import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { stripVTControlCharacters } from "node:util";
import type { CompactionSettings, ContextUsage, ExtensionAPI, ExtensionContext, SessionEntry, Theme } from "@earendil-works/pi-coding-agent";
import { sliceByColumn, truncateToWidth, visibleWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";

/** Spinner frames for the live activity indicator, advanced every 100ms. */
const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

/**
 * Characters-per-token varies too much between scripts for one constant: measured
 * over 13k assistant messages, CJK text averages ~1.05 tokens per character while
 * Latin/code text averages ~1 token per 2.73 characters. Weighting streamed text by
 * script removes most of the error a flat 4-chars/token estimate has on mixed output.
 */
const TOKENS_PER_CJK_CHAR = 1.05;
const TOKENS_PER_OTHER_CHAR = 1 / 2.73;

/** CJK ideographs (incl. extensions), kana, Hangul, CJK punctuation and fullwidth forms. */
const CJK_CHAR = /[\u2e80-\u9fff\u3000-\u30ff\uac00-\ud7af\uff00-\uffef\u{20000}-\u{2ffff}\u{30000}-\u{3134f}]/gu;

export function countCjkCharacters(text: string): number {
  return text.match(CJK_CHAR)?.length ?? 0;
}

/** Script-aware estimate of how many output tokens the streamed characters produced. */
export function scriptTokenEstimate(cjkCharacters: number, otherCharacters: number): number {
  return cjkCharacters * TOKENS_PER_CJK_CHAR + otherCharacters * TOKENS_PER_OTHER_CHAR;
}

/**
 * Per-model residual calibration of the script estimate. The script weights absorb the
 * dominant difference between providers (content mix); two leftovers remain per model —
 * one for streamed text (prose and thinking) and one for tool-call argument JSON, which
 * may tokenize differently from prose. Completed messages distribute output tokens
 * proportionally to estimated mass. Both factors therefore learn the same aggregate
 * ratio, with different weights; mixed samples cannot identify independent errors.
 * Keep this lightweight heuristic and its persisted format for compatibility. The nudge grows with the part's token mass, so a long message teaches
 * more than a short one, while the cap and bounds keep one unusual message from sticking.
 */
const RATE_CALIBRATION_FILE = join(homedir(), ".pi", "agent", "statusline-rate.json");
const RATE_CALIBRATION_ALPHA = 0.05;
const RATE_CALIBRATION_SCALE = 300;
const RATE_CALIBRATION_MAX_WEIGHT = 0.5;
const RATE_CALIBRATION_MIN_TOKENS = 30;
const RATE_CALIBRATION_MIN = 0.5;
const RATE_CALIBRATION_MAX = 2;

/** Residual factors for one model: streamed text and tool-call argument JSON. */
export interface RateCalibration {
  text: number;
  tool: number;
}

const clampCalibration = (value: number): number => Math.min(RATE_CALIBRATION_MAX, Math.max(RATE_CALIBRATION_MIN, value));

export function updateRateCalibration(
  previous: number | undefined,
  actualTokens: number,
  estimatedTokens: number,
): number | undefined {
  if (!Number.isFinite(actualTokens) || actualTokens <= 0 || estimatedTokens < RATE_CALIBRATION_MIN_TOKENS) return undefined;
  const ratio = clampCalibration(actualTokens / estimatedTokens);
  if (previous === undefined || !Number.isFinite(previous)) return ratio;
  const weight = Math.min(RATE_CALIBRATION_MAX_WEIGHT, RATE_CALIBRATION_ALPHA * estimatedTokens / RATE_CALIBRATION_SCALE);
  return previous + weight * (ratio - previous);
}

export function loadRateCalibration(file: string = RATE_CALIBRATION_FILE): Map<string, RateCalibration> {
  try {
    const raw: unknown = JSON.parse(readFileSync(file, "utf8"));
    const entries = new Map<string, RateCalibration>();
    if (raw && typeof raw === "object") {
      for (const [model, value] of Object.entries(raw)) {
        if (typeof value === "number" && Number.isFinite(value)) {
          // Legacy single coefficient: it was learned from text messages only.
          entries.set(model, { text: clampCalibration(value), tool: 1 });
        } else if (value && typeof value === "object") {
          const record = value as { text?: unknown; tool?: unknown };
          if (typeof record.text === "number" && Number.isFinite(record.text)
            && typeof record.tool === "number" && Number.isFinite(record.tool)) {
            entries.set(model, { text: clampCalibration(record.text), tool: clampCalibration(record.tool) });
          }
        }
      }
    }
    return entries;
  } catch {
    return new Map();
  }
}

export function saveRateCalibration(entries: Map<string, RateCalibration>, file: string = RATE_CALIBRATION_FILE): void {
  try {
    mkdirSync(dirname(file), { recursive: true });
    writeFileSync(file, `${JSON.stringify(Object.fromEntries(entries), null, 2)}\n`);
  } catch {
    // A failed write only means the calibration is relearned in the next session.
  }
}

const SEPARATOR = " · ";

/** Footer state while the agent is working; absent when idle. */
export interface ActivitySnapshot {
  phase: "waiting" | "thinking" | "streaming" | "tool" | "compacting" | "finishing";
  toolName?: string;
  toolCount?: number;
  /** Milliseconds elapsed for the whole run, including tools and recovery. */
  elapsedMs: number;
  frame: string;
}

export interface RateSnapshot {
  tokensPerSecond: number;
  /** True while tokens are still arriving and the count is derived from text length. */
  estimated: boolean;
}

/** Code-point counts of the characters streamed for one message part. */
interface StreamCounts {
  cjk: number;
  other: number;
}

/** Accumulated streamed characters of the in-flight assistant message. */
interface StreamState {
  firstDeltaAt?: number;
  /** Streamed prose and thinking. */
  text: StreamCounts;
  /** Streamed tool-call argument JSON. */
  tool: StreamCounts;
  exactTokens?: number;
}

/**
 * `DEFAULT_COMPACTION_SETTINGS.reserveTokens` from pi's compaction module, used when
 * settings.json has no `compaction` key (the defaults apply at runtime, but
 * `getSettings().compaction` stays undefined then).
 */
const DEFAULT_RESERVE_TOKENS = 16384;

/**
 * The reserve Pi actually applies for a model: a per-model
 * `compaction.modelOverrides["provider/id"]` entry wins over the ordinary
 * `compaction.reserveTokens`, which wins over the built-in default. Mirrors
 * `SettingsManager.getCompactionReserveTokens`.
 */
export function resolveAutoCompactReserve(
  compaction: CompactionSettings | undefined,
  model: { provider?: string; id?: string } | undefined,
): number | undefined {
  if (compaction?.enabled === false) return undefined;
  const key = model ? `${model.provider}/${model.id}` : undefined;
  const override = key ? compaction?.modelOverrides?.[key] : undefined;
  return override?.reserveTokens ?? compaction?.reserveTokens ?? DEFAULT_RESERVE_TOKENS;
}

/** One footer: location/stats above, context and activity/model/effort below. */
export interface FooterSnapshot {
  cwd: string;
  home: string;
  branch?: string;
  model: string;
  effort: string;
  window?: number;
  usedPercent?: number | null;
  input?: number;
  output?: number;
  cost?: number;
  cacheHitPercent?: number;
  cacheRead?: number;
  cacheWrite?: number;
  /** Tokens auto-compaction keeps as headroom, after model overrides are applied. */
  autoCompactReserve?: number;
  activity?: ActivitySnapshot;
  rate?: RateSnapshot;
}

function label(text: string): string {
  return stripVTControlCharacters(text).replace(/[\x00-\x1f\x7f-\x9f]/g, " ");
}

/** Preserve both ends of model/branch names, measuring terminal columns. */
export function shortLabel(text: string, width: number): string {
  width = Math.max(0, Math.floor(width));
  if (visibleWidth(text) <= width) return text;
  if (width < 5) return truncateToWidth(text, width, "…");
  const left = Math.ceil((width - 1) * 0.6);
  return sliceByColumn(text, 0, left, true) + "…" + sliceByColumn(text, visibleWidth(text) - (width - 1 - left), width - 1 - left, true);
}

/** Used-window gauge; color reflects room before the effective limit, not raw usage. */
export function renderContext(state: FooterSnapshot, theme: Theme, budget: number): string {
  const dim = (text: string) => theme.fg("dim", text);
  const plain = (text: string) => theme.fg("text", text);
  const windowSize = state.window !== undefined && Number.isFinite(state.window) && state.window > 0
    ? state.window : undefined;
  const used = typeof state.usedPercent === "number" && Number.isFinite(state.usedPercent)
    ? Math.max(0, Math.min(100, state.usedPercent)) : undefined;
  // Undefined means auto-compaction is disabled. Zero is a valid enabled reserve.
  const auto = state.autoCompactReserve !== undefined;
  const reserve = typeof state.autoCompactReserve === "number" && Number.isFinite(state.autoCompactReserve)
    ? Math.max(0, state.autoCompactReserve) : 0;
  if (used === undefined || windowSize === undefined) {
    return `${dim("ctx")} ${plain(`—/${formatWindow(windowSize)}`)} · ${dim("usage pending")}${auto ? "" : ` · ${dim("auto off")}`}`;
  }
  const usedTokens = windowSize * used / 100;
  const limit = Math.max(0, windowSize - (auto ? reserve : 0));
  const headroom = limit - usedTokens;
  // Yellow below 30%, red below 10% of the effective capacity still available.
  const fraction = limit > 0 ? headroom / limit : 0;
  const color = fraction < 0.1 ? "error" : fraction < 0.3 ? "warning" : "text";
  const accent = (text: string) => theme.fg(color, text);
  const headroomText = `≈${formatWindow(Math.max(1, Math.round(headroom)))}`;
  const status = !auto ? dim("auto off") : headroom <= 0
    ? accent("auto due") : `${dim("auto in")} ${accent(headroomText)}`;
  const compactStatus = auto && headroom > 0 ? `${dim("auto")} ${accent(headroomText)}` : status;
  const prefix = `${dim("ctx")} ${plain(`${usedTokens === 0 ? "0" : formatWindow(usedTokens)}/${formatWindow(windowSize)}`)}`;
  const percent = (auto ? plain : accent)(`${Math.round(used)}%`);
  // Shrink the decoration before removing the redundant absolute usage ratio.
  for (const size of [14, 10, 6]) {
    const halves = Math.floor(used * size * 2 / 100);
    const filled = Math.floor(halves / 2);
    const half = halves % 2;
    const bar = accent("━".repeat(filled) + (half ? "╸" : "")) + dim("─".repeat(size - filled - half));
    const text = `${prefix} ${bar} ${percent} · ${status}`;
    if (visibleWidth(text) <= budget) return text;
  }
  const withoutBar = `${prefix} ${percent} · ${status}`;
  if (visibleWidth(withoutBar) <= budget) return withoutBar;
  const compact = `${dim("ctx")} ${percent} · ${compactStatus}`;
  // If even the compact form cannot fit, let the caller wrap the complete values.
  return visibleWidth(compact) <= budget ? compact : withoutBar;
}

function joinSides(left: string, right: string, width: number): string {
  if (!right) return truncateToWidth(left, width);
  if (!left) return truncateToWidth(right, width);
  const gap = width - visibleWidth(left) - visibleWidth(right);
  return truncateToWidth(left + " ".repeat(Math.max(2, gap)) + right, width);
}

/** setStatus has no severity metadata: recognize explicit warning/error markers. */
export function isImportantStatus(text: string): boolean {
  return /(?:⚠|❌|\b(?:warning|error|failed|failure)\b|警告|错误|失败)/iu.test(label(text));
}

export function renderExtensionStatuses(statuses: ReadonlyMap<string, string>, theme: Theme, width: number): string[] {
  if (width <= 0 || statuses.size === 0) return [];
  const ordinary: string[] = [];
  const important: string[] = [];
  for (const [key, value] of statuses) {
    const text = `${label(key)}: ${label(value)}`;
    (isImportantStatus(value) ? important : ordinary).push(text);
  }
  return [
    ...important.flatMap((text) => wrapTextWithAnsi(theme.fg("warning", `│ ${text}`), width)),
    ...ordinary.flatMap((text) => wrapTextWithAnsi(theme.fg("muted", `│ ${text}`), width)),
  ].map((line) => truncateToWidth(line, width));
}

function formatWindow(tokens: number | undefined): string {
  if (tokens === undefined || !Number.isFinite(tokens) || tokens <= 0) return "—";
  if (tokens >= 1_000_000) return `${Number((tokens / 1_000_000).toFixed(2))}M`;
  if (tokens >= 1_000) {
    const thousands = Number((tokens / 1_000).toFixed(1));
    // Rounding can push 999.95k to "1000k"; promote it to the M step instead.
    return thousands < 1_000 ? `${thousands}k` : `${Number((tokens / 1_000_000).toFixed(2))}M`;
  }
  return String(tokens);
}

function formatDuration(ms: number): string {
  const seconds = Math.max(0, ms) / 1000;
  if (seconds < 10) return `${seconds.toFixed(1)}s`;
  if (seconds < 60) return `${Math.round(seconds)}s`;
  return `${Math.floor(seconds / 60)}m${String(Math.floor(seconds % 60)).padStart(2, "0")}s`;
}

function formatRate(rate: number): string {
  return rate >= 10 ? String(Math.round(rate)) : rate.toFixed(1);
}

/** Effort is colored with the theme's own thinking-level tokens. */
function colorizeEffort(theme: Theme, effort: string, text: string): string {
  switch (effort.trim().toLowerCase()) {
    case "off": return theme.fg("thinkingOff", text);
    case "minimal": return theme.fg("thinkingMinimal", text);
    case "low": return theme.fg("thinkingLow", text);
    case "medium": return theme.fg("thinkingMedium", text);
    case "high": return theme.fg("thinkingHigh", text);
    case "xhigh": return theme.fg("thinkingXhigh", text);
    case "max": return theme.fg("thinkingMax", text);
    default: return theme.fg("thinkingText", text);
  }
}

export interface SessionUsage {
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  cost: number;
  cacheHitPercent?: number;
}

function addUsage(
  totals: SessionUsage,
  usage: { input: number; output: number; cacheRead?: number; cacheWrite?: number; cost: { total: number } },
): void {
  totals.input += usage.input;
  totals.output += usage.output;
  totals.cacheRead += usage.cacheRead ?? 0;
  totals.cacheWrite += usage.cacheWrite ?? 0;
  totals.cost += usage.cost.total;
}

/**
 * Sum every usage-bearing session entry, exactly like Pi's built-in footer: plain
 * `usage` entries, assistant messages, tool results, and compaction/branch summaries.
 * Summing only the current branch would disagree with `/session` after branching or
 * compaction. The cache-hit rate comes from the latest assistant message, not an
 * average across the session.
 */
export function readSessionUsage(entries: readonly SessionEntry[]): SessionUsage {
  const totals: SessionUsage = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0 };
  for (const entry of entries) {
    if (entry.type === "message" && entry.message.role === "assistant") {
      const { usage } = entry.message;
      addUsage(totals, usage);
      // Mirrors the built-in footer: the rate comes from the latest assistant message,
      // and a message with no prompt tokens clears it rather than keeping a stale one.
      const promptTokens = usage.input + usage.cacheRead + usage.cacheWrite;
      totals.cacheHitPercent = promptTokens > 0 ? (usage.cacheRead / promptTokens) * 100 : undefined;
    } else if (entry.type === "message" && entry.message.role === "toolResult") {
      if (entry.message.usage) addUsage(totals, entry.message.usage);
    } else if (entry.type === "usage") {
      addUsage(totals, entry.usage);
    } else if (entry.type === "compaction" || entry.type === "branch_summary") {
      if (entry.usage) addUsage(totals, entry.usage);
    }
  }
  return totals;
}

export function renderFooter(state: FooterSnapshot, theme: Theme, width: number): string[] {
  width = Math.max(0, Math.floor(width));
  if (width === 0) return [];

  // Every color comes from a theme token, so the footer follows the active theme
  // (including light ones) instead of assuming a dark background.
  const plain = (text: string) => theme.fg("text", text);
  const muted = (text: string) => theme.fg("muted", text);
  const dim = (text: string) => theme.fg("dim", text);
  const separator = dim(SEPARATOR);

  const cwd = state.cwd === state.home
    ? "~"
    : state.cwd.startsWith(`${state.home}/`)
      ? `~${state.cwd.slice(state.home.length)}`
      : state.cwd;
  const location = (budget: number) => {
    const branch = state.branch && budget >= 12 ? muted(` [${shortLabel(label(state.branch), Math.min(18, Math.floor(budget / 3)))}]`) : "";
    const pathBudget = Math.max(0, budget - visibleWidth(branch));
    const basename = label(cwd).split("/").pop() ?? "";
    const shortened = pathBudget >= visibleWidth(basename) + 2 ? `…/${basename}` : basename;
    const path = visibleWidth(label(cwd)) <= pathBudget
      ? label(cwd)
      : shortLabel(shortened, pathBudget);
    return truncateToWidth(plain(path) + branch, Math.max(0, budget));
  };

  const contextFor = (budget: number) => renderContext(state, theme, budget);

  // Identity stays on row two; live activity can overflow below on narrow panes.
  interface RightPart { key: "activity" | "rate" | "model" | "effort"; text: string }
  const right: RightPart[] = [];
  const activity = state.activity;
  if (activity) {
    const group = [theme.fg("accent", activity.frame)];
    const phaseLabel = activity.phase === "tool"
      ? (activity.toolCount && activity.toolCount > 1 ? `tools×${activity.toolCount}` : `tool ${label(activity.toolName ?? "tool")}`)
      : { waiting: "waiting", thinking: "thinking", streaming: "streaming", compacting: "compacting", finishing: "finishing" }[activity.phase];
    group.push(theme.fg("toolTitle", phaseLabel));
    group.push(muted(formatDuration(activity.elapsedMs).padStart(6)));
    right.push({ key: "activity", text: group.join(" ") });
  }
  if (state.rate && (activity?.phase === "thinking" || activity?.phase === "streaming")) {
    const rate = `${formatRate(state.rate.tokensPerSecond)} tok/s`;
    right.push({ key: "rate", text: state.rate.estimated ? dim(`~${rate}`) : muted(rate) });
  }
  right.push({ key: "model", text: plain(label(state.model)) });
  if (state.effort) {
    right.push({ key: "effort", text: colorizeEffort(theme, state.effort, label(state.effort)) });
  }

  const renderRight = (parts: RightPart[]) => parts.map((part) => part.text).join(separator);

  // Token totals, cost, and cache stats ride the free right side of the location
  // line, so the context line keeps carrying only the current state. Each part is
  // omitted until there is something to show, matching the built-in footer.
  interface StatsPart { key: "tokens" | "cost" | "cacheHit" | "cache"; text: string }
  const stats: StatsPart[] = [];
  {
    const counts = [
      state.input ? muted(`↑${formatWindow(state.input)}`) : "",
      state.output ? muted(`↓${formatWindow(state.output)}`) : "",
    ].filter(Boolean).join(" ");
    if (counts) stats.push({ key: "tokens", text: counts });
  }
  if (state.cost !== undefined && state.cost > 0) {
    stats.push({ key: "cost", text: plain(`≈$${state.cost.toFixed(3)}`) });
  }
  // `cacheRead`/`cacheWrite` gate this like the built-in footer: a provider that does
  // not report caching at all would otherwise show a fabricated 0% hit rate.
  if (state.cacheHitPercent !== undefined && (state.cacheRead || state.cacheWrite)) {
    // A cold first request is normal; a single low hit rate is not a warning.
    stats.push({ key: "cacheHit", text: muted(`cache ${state.cacheHitPercent.toFixed(1)}%`) });
  }
  if (state.cacheRead || state.cacheWrite) {
    // Reads are the cheap path, writes are the expensive one (Anthropic bills 1h
    // writes at 2x input). Providers without prompt caching report zero.
    const counts = [
      state.cacheRead ? muted(`r ${formatWindow(state.cacheRead)}`) : "",
      state.cacheWrite ? muted(`w ${formatWindow(state.cacheWrite)}`) : "",
    ].filter(Boolean).join(" ");
    stats.push({ key: "cache", text: counts });
  }

  const statsText = stats.map((part) => part.text).join(separator);
  const identity = renderRight(right.filter((part) => part.key === "model" || part.key === "effort"));
  const live = renderRight(right.filter((part) => part.key === "activity" || part.key === "rate"));
  const allRight = renderRight(right);
  const overflow: string[] = [];
  const appendOverflow = (text: string) => overflow.push(...wrapTextWithAnsi(text, width));
  const locationMinimum = Math.min(18, Math.floor(width / 4));
  const statsFit = visibleWidth(statsText) + locationMinimum + 2 <= width;
  if (!statsFit) appendOverflow(statsText);
  const topStats = statsFit ? statsText : "";
  const top = joinSides(location(Math.max(0, width - visibleWidth(topStats) - 2)), topStats, width);

  // Keep model and effort on row two, even when idle. Overflow is visible, never
  // hidden behind a preset/details view. Size ctx against the actual right block.
  const liveContext = contextFor(width - visibleWidth(allRight) - 2);
  const idleContext = contextFor(width - visibleWidth(identity) - 2);
  let bottom: string;
  if (visibleWidth(liveContext) + visibleWidth(allRight) + 2 <= width) {
    bottom = joinSides(liveContext, allRight, width);
  } else if (visibleWidth(idleContext) + visibleWidth(identity) + 2 <= width) {
    bottom = joinSides(idleContext, identity, width);
    if (live) appendOverflow(live);
  } else {
    const identityLines = wrapTextWithAnsi(identity, width);
    const first = identityLines.shift() ?? "";
    bottom = " ".repeat(Math.max(0, width - visibleWidth(first))) + first;
    overflow.push(...identityLines);
    appendOverflow(contextFor(width));
    if (live) appendOverflow(live);
  }
  return [top, bottom, ...overflow].map((line) => truncateToWidth(line, width));
}

export default function minimalStatusline(pi: ExtensionAPI) {
  let enabled = true;
  const rateCalibration = loadRateCalibration();
  let refresh: (() => void) | undefined;
  let ticker: ReturnType<typeof setInterval> | undefined;
  // Only the session whose footer is installed may drive the live state; forked
  // sessions in the same process share this module scope.
  let installedSessionId: string | undefined;

  // Live turn state, written by the event handlers and read on every render.
  let turnStartedAt: number | undefined;
  let phase: ActivitySnapshot["phase"] = "waiting";
  const activeTools = new Map<string, { name: string }>();
  let compactionStandalone = false;
  let stream: StreamState | undefined;

  const ensureTicker = () => {
    if (ticker || !enabled || !refresh) return;
    ticker = setInterval(() => refresh?.(), 100);
    ticker.unref?.();
  };
  const stopTicker = () => {
    if (ticker) clearInterval(ticker);
    ticker = undefined;
  };

  function currentActivity(now: number): ActivitySnapshot | undefined {
    if (turnStartedAt === undefined) return undefined;
    return {
      phase: phase === "compacting" ? phase : activeTools.size ? "tool" : phase,
      toolName: activeTools.values().next().value?.name,
      toolCount: activeTools.size,
      elapsedMs: now - turnStartedAt,
      frame: SPINNER_FRAMES[Math.floor(now / 100) % SPINNER_FRAMES.length],
    };
  }

  /**
   * Script estimate with the model's learned residual factors applied separately to
   * streamed text and tool-call argument JSON.
   */
  function calibratedEstimate(model: { provider?: string; id?: string } | undefined, counts: StreamState): number {
    const calibration = rateCalibration.get(`${model?.provider}/${model?.id}`);
    return scriptTokenEstimate(counts.text.cjk, counts.text.other) * (calibration?.text ?? 1)
      + scriptTokenEstimate(counts.tool.cjk, counts.tool.other) * (calibration?.tool ?? 1);
  }

  /**
   * While tokens are arriving the provider has not reported a usage count yet, so the
   * rate is estimated from streamed characters (prefixed with `~`), weighting CJK and
   * non-CJK separately and applying the model's learned residual factors. Once the
   * message ends, hide the rate rather than displaying stale throughput.
   */
  function currentRate(now: number, model: { provider?: string; id?: string } | undefined): RateSnapshot | undefined {
    if (activeTools.size || (phase !== "streaming" && phase !== "thinking")) return undefined;
    if (stream?.firstDeltaAt !== undefined && stream.exactTokens === undefined) {
      const seconds = (now - stream.firstDeltaAt) / 1000;
      if (seconds >= 0.35) {
        const tokensPerSecond = calibratedEstimate(model, stream) / seconds;
        return { tokensPerSecond, estimated: true };
      }
    }
    return undefined;
  }

  /** Events from other sessions in this process must not touch the visible footer. */
  function owns(ctx: ExtensionContext): boolean {
    return ctx.mode === "tui" && ctx.sessionManager.getSessionId() === installedSessionId;
  }

  function install(ctx: ExtensionContext) {
    if (ctx.mode !== "tui") return;
    installedSessionId = ctx.sessionManager.getSessionId();
    stopTicker();
    ctx.ui.setFooter(enabled ? (tui, theme, footerData) => {
      let cachedKey: string | undefined;
      let usage: ContextUsage | undefined;
      let sessionUsage: SessionUsage | undefined;
      let autoCompactReserve: number | undefined;
      // Render-only: the cache key below already covers every append that can change
      // the numbers, so clearing it here would just force the projection rebuild the
      // activity ticker would otherwise trigger ten times a second.
      const requestUpdate = () => tui.requestRender();
      refresh = requestUpdate;
      if (turnStartedAt !== undefined) ensureTicker();
      const unsubscribe = footerData.onBranchChange(requestUpdate);

      return {
        dispose() {
          unsubscribe();
          if (refresh === requestUpdate) {
            refresh = undefined;
            stopTicker();
          }
        },
        invalidate() {}, // Colors and width are resolved afresh on every render.
        render(width: number): string[] {
          const now = Date.now();
          const model = ctx.model;
          const manager = ctx.sessionManager;
          const key = JSON.stringify([
            manager.getSessionId(), manager.getLeafId(),
            model?.provider, model?.id, model?.contextWindow,
          ]);
          // Avoid rebuilding the long conversation projection on every editor keystroke
          // or activity tick. Every append moves the leaf, so the key also covers usage
          // entries that arrive outside a message (cache_warm, tool results, compaction),
          // and the model part re-resolves compaction.modelOverrides on model switches.
          if (key !== cachedKey) {
            usage = ctx.getContextUsage();
            sessionUsage = readSessionUsage(manager.getEntries());
            autoCompactReserve = resolveAutoCompactReserve(pi.getSettings().compaction, model ?? undefined);
            cachedKey = key;
          }
          const contextWindow = usage?.contextWindow ?? model?.contextWindow;
          const lines = renderFooter({
            cwd: manager.getCwd(),
            home: homedir(),
            branch: footerData.getGitBranch() ?? undefined,
            model: model?.id ?? "no model",
            effort: ctx.thinkingLevel ?? pi.getThinkingLevel(),
            window: contextWindow,
            usedPercent: usage?.percent,
            input: sessionUsage?.input,
            output: sessionUsage?.output,
            cost: sessionUsage?.cost,
            cacheHitPercent: sessionUsage?.cacheHitPercent,
            cacheRead: sessionUsage?.cacheRead,
            cacheWrite: sessionUsage?.cacheWrite,
            autoCompactReserve,
            activity: currentActivity(now),
            rate: currentRate(now, model),
          }, theme, width);

          lines.push(...renderExtensionStatuses(footerData.getExtensionStatuses(), theme, width));
          return lines;
        },
      };
    } : undefined);
  }

  const resetLive = () => {
    turnStartedAt = undefined;
    activeTools.clear();
    phase = "waiting";
    stream = undefined;
    compactionStandalone = false;
    stopTicker();
  };
  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    resetLive();
    install(ctx);
  });
  pi.on("agent_start", (_event, ctx) => {
    if (!owns(ctx)) return;
    turnStartedAt ??= Date.now();
    phase = "waiting";
    stream = undefined;
    ensureTicker();
    refresh?.();
  });
  pi.on("agent_end", (_event, ctx) => {
    if (!owns(ctx)) return;
    phase = "finishing";
    stream = undefined;
    refresh?.();
  });
  pi.on("agent_settled", (_event, ctx) => {
    if (!owns(ctx)) return;
    resetLive();
    refresh?.();
  });
  pi.on("before_provider_request", (_event, ctx) => {
    if (!owns(ctx)) return;
    phase = "waiting";
    refresh?.();
  });
  pi.on("session_before_compact", (_event, ctx) => {
    if (!owns(ctx)) return;
    compactionStandalone = turnStartedAt === undefined;
    turnStartedAt ??= Date.now();
    phase = "compacting";
    ensureTicker();
    refresh?.();
  });
  const finishCompaction = (_event: unknown, ctx: ExtensionContext) => {
    if (!owns(ctx)) return;
    if (compactionStandalone) resetLive();
    else phase = "waiting";
    refresh?.();
  };
  pi.on("session_compact", finishCompaction);
  pi.on("session_compact_failed", finishCompaction);
  pi.on("message_start", (event, ctx) => {
    if (!owns(ctx)) return;
    if (event.message.role === "assistant") {
      stream = { text: { cjk: 0, other: 0 }, tool: { cjk: 0, other: 0 } };
      phase = "waiting";
      refresh?.();
    }
  });
  pi.on("message_update", (event, ctx) => {
    if (!owns(ctx)) return;
    if (event.message.role !== "assistant") return;
    const delta = event.assistantMessageEvent;
    if (delta.type !== "text_delta" && delta.type !== "thinking_delta" && delta.type !== "toolcall_delta") return;
    if (!stream) stream = { text: { cjk: 0, other: 0 }, tool: { cjk: 0, other: 0 } };
    if (stream.firstDeltaAt === undefined) stream.firstDeltaAt = Date.now();
    // Count code points, not UTF-16 units, so astral characters match the script weights.
    const counts = delta.type === "toolcall_delta" ? stream.tool : stream.text;
    const cjk = countCjkCharacters(delta.delta);
    counts.cjk += cjk;
    counts.other += Array.from(delta.delta).length - cjk;
    phase = delta.type === "thinking_delta" ? "thinking" : "streaming";
    ensureTicker();
  });
  pi.on("tool_execution_start", (event, ctx) => {
    if (!owns(ctx)) return;
    activeTools.set(event.toolCallId, { name: event.toolName });
    ensureTicker();
    refresh?.();
  });
  pi.on("tool_execution_end", (event, ctx) => {
    if (!owns(ctx)) return;
    activeTools.delete(event.toolCallId);
    if (!activeTools.size) phase = "waiting";
    refresh?.();
  });
  pi.on("message_end", (event, ctx) => {
    if (!owns(ctx)) return;
    if (event.message.role === "assistant") {
      phase = "waiting";
      const output = event.message.usage.output;
      const first = stream?.firstDeltaAt;
      if (first !== undefined && output > 0) {
        // Proportional allocation is a heuristic, not independently measured text/tool
        // usage. Preserve the existing calibration format; do not claim exact throughput.
        const model = ctx.model;
        if (stream && model) {
          const textEstimate = scriptTokenEstimate(stream.text.cjk, stream.text.other);
          const toolEstimate = scriptTokenEstimate(stream.tool.cjk, stream.tool.other);
          const totalEstimate = textEstimate + toolEstimate;
          if (totalEstimate >= RATE_CALIBRATION_MIN_TOKENS) {
            const key = `${model.provider}/${model.id}`;
            const ratio = output / totalEstimate;
            const previous = rateCalibration.get(key);
            const text = updateRateCalibration(previous?.text, ratio * textEstimate, textEstimate);
            const tool = updateRateCalibration(previous?.tool, ratio * toolEstimate, toolEstimate);
            if (text !== undefined || tool !== undefined) {
              rateCalibration.set(key, { text: text ?? previous?.text ?? 1, tool: tool ?? previous?.tool ?? 1 });
              saveRateCalibration(rateCalibration);
            }
          }
        }
      }
      // Freeze the estimate: no more characters will arrive for this message.
      stream = {
        text: stream?.text ?? { cjk: 0, other: 0 },
        tool: stream?.tool ?? { cjk: 0, other: 0 },
        exactTokens: output,
      };
    }
    refresh?.();
  });
  pi.on("model_select", (_event, ctx) => {
    if (!owns(ctx)) return;
    stream = undefined;
    refresh?.();
  });
  pi.on("thinking_level_select", () => refresh?.());
  pi.on("session_tree", () => refresh?.());
  pi.on("session_shutdown", (_event, ctx) => {
    if (!owns(ctx)) return;
    resetLive();
    if (enabled) ctx.ui.setFooter(undefined);
    refresh = undefined;
    installedSessionId = undefined;
  });

  pi.registerCommand("statusline", {
    description: "Toggle the statusline (custom | default)",
    handler: async (args, ctx) => {
      if (ctx.mode !== "tui") return;
      const choice = args.trim();
      if (choice && choice !== "custom" && choice !== "default") {
        ctx.ui.notify("Usage: /statusline [custom | default]", "info");
        return;
      }
      enabled = choice ? choice === "custom" : !enabled;
      install(ctx);
    },
  });
}
