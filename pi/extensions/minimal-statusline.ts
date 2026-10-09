import { mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { stripVTControlCharacters } from "node:util";
import type { ContextUsage, ExtensionAPI, ExtensionContext, SessionEntry, Theme } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";

/** Spinner frames for the live activity indicator, advanced every 100ms. */
const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

/** Rough characters-per-token ratio used for the live throughput estimate. */
const CHARS_PER_TOKEN = 4;

const SEPARATOR = " · ";

/** In narrow panes the lowest-value fields disappear first, never a whole line. */
const STATS_DROP_ORDER = ["cache", "tokens", "cacheHit", "cost"] as const;
const RIGHT_DROP_ORDER = ["rate", "effort", "activity"] as const;

/** Footer state while the agent is working; absent when idle. */
export interface ActivitySnapshot {
  phase: "waiting" | "streaming" | "tool";
  toolName?: string;
  /** Milliseconds elapsed: the running tool's own time in phase "tool", the turn's time otherwise. */
  elapsedMs: number;
  frame: string;
}

export interface RateSnapshot {
  tokensPerSecond: number;
  /** True while tokens are still arriving and the count is derived from text length. */
  estimated: boolean;
}

/** Which groups the footer shows; `/statusline <preset>` switches it. */
export type FooterPreset = "full" | "minimal" | "cost";

interface PresetFlags {
  tokens: boolean;
  cache: boolean;
  cost: boolean;
  cacheHit: boolean;
  rate: boolean;
  activity: boolean;
  effort: boolean;
}

/**
 * `DEFAULT_COMPACTION_SETTINGS.reserveTokens` from pi's compaction module, used when
 * settings.json has no `compaction` key (the defaults apply at runtime, but
 * `getSettings().compaction` stays undefined then).
 */
const DEFAULT_RESERVE_TOKENS = 16384;

const PRESETS: Record<FooterPreset, PresetFlags> = {
  full: { tokens: true, cache: true, cost: true, cacheHit: true, rate: true, activity: true, effort: true },
  // Working state only: no session totals, no throughput.
  minimal: { tokens: false, cache: false, cost: false, cacheHit: false, rate: false, activity: true, effort: true },
  // Money only.
  cost: { tokens: false, cache: false, cost: true, cacheHit: false, rate: false, activity: false, effort: false },
};

const PRESET_FILE = join(homedir(), ".pi", "agent", "statusline.json");

function loadPreset(): FooterPreset {
  try {
    const value = JSON.parse(readFileSync(PRESET_FILE, "utf8")).preset;
    if (value === "full" || value === "minimal" || value === "cost") return value;
  } catch {
    // Missing or unreadable: fall back to the default preset.
  }
  return "full";
}

function savePreset(preset: FooterPreset): void {
  try {
    mkdirSync(dirname(PRESET_FILE), { recursive: true });
    writeFileSync(PRESET_FILE, `${JSON.stringify({ preset }, null, 2)}\n`);
  } catch {
    // A failed write only means the choice is not remembered.
  }
}

/** Local footer: location + session stats above, remaining context left, model/activity right. */
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
  /** Tokens auto-compaction keeps as headroom (`compaction.reserveTokens`). */
  autoCompactReserve?: number;
  activity?: ActivitySnapshot;
  rate?: RateSnapshot;
  preset?: FooterPreset;
}

function label(text: string): string {
  return stripVTControlCharacters(text).replace(/[\x00-\x1f\x7f-\x9f]/g, " ");
}

function formatWindow(tokens: number | undefined): string {
  if (tokens === undefined || !Number.isFinite(tokens) || tokens <= 0) return "—";
  if (tokens >= 1_000_000) return `${Number((tokens / 1_000_000).toFixed(2))}M`;
  if (tokens >= 1_000) return `${Number((tokens / 1_000).toFixed(1))}k`;
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
      const promptTokens = usage.input + usage.cacheRead + usage.cacheWrite;
      if (promptTokens > 0) totals.cacheHitPercent = (usage.cacheRead / promptTokens) * 100;
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
  const flags = PRESETS[state.preset ?? "full"];

  const cwd = state.cwd === state.home
    ? "~"
    : state.cwd.startsWith(`${state.home}/`)
      ? `~${state.cwd.slice(state.home.length)}`
      : state.cwd;
  const chip = state.branch
    ? ` ${theme.style(` ${label(state.branch)} `, { fg: "accent", bg: "selectedBg" })}`
    : "";
  const location = plain(label(cwd)) + chip;

  const remaining = typeof state.usedPercent === "number" && Number.isFinite(state.usedPercent)
    ? Math.max(0, Math.min(100, 100 - state.usedPercent))
    : undefined;
  // Same thresholds as the built-in footer: warning past 70% used, error past 90%.
  const budgetColor = (text: string) => remaining !== undefined && remaining < 10
    ? theme.fg("error", text)
    : remaining !== undefined && remaining < 30
      ? theme.fg("warning", text)
      : plain(text);
  const barWidth = width >= 100 ? 14 : width >= 70 ? 10 : 6;
  // A half-cell endpoint leaves a small gap before the used track.
  const halves = remaining === undefined ? 0 : Math.floor(remaining * barWidth * 2 / 100);
  const full = Math.floor(halves / 2);
  const half = halves % 2;
  const track = barWidth - full - half;
  const filled = half
    ? "━".repeat(full) + "╸"
    : full > 0 && track > 0
      ? "━".repeat(full - 1) + "╸"
      : "━".repeat(full);

  const reserve = state.autoCompactReserve;
  const windowSize = state.window;
  const bar = budgetColor(filled) + dim("─".repeat(track));
  const percentage = remaining === undefined ? plain("—") : budgetColor(`${Math.round(remaining)}%`);
  // Absolute headroom left before auto-compaction triggers is easier to act on than
  // the percentage: `≈88k →auto`.
  let headroom = "";
  if (reserve && windowSize && remaining !== undefined) {
    const headroomTokens = Math.round((windowSize * remaining) / 100 - reserve);
    headroom = " " + (headroomTokens > 0 ? muted(`≈${formatWindow(headroomTokens)}`) + " " : "") + dim("→auto");
  }
  const context = dim("ctx") + " " + muted(formatWindow(windowSize)) + " " + bar + " " + percentage + headroom;

  // The model block rides the right side of the context line: live activity first
  // (spinner, running tool, elapsed), then throughput, model, and effort.
  interface RightPart { key: "activity" | "rate" | "model" | "effort"; text: string }
  const right: RightPart[] = [];
  const activity = state.activity;
  if (flags.activity && activity) {
    const group = [theme.fg("accent", activity.frame)];
    if (activity.phase === "tool" && activity.toolName) group.push(theme.fg("toolTitle", label(activity.toolName)));
    group.push(muted(formatDuration(activity.elapsedMs)));
    right.push({ key: "activity", text: group.join(" ") });
  }
  if (flags.rate && state.rate) {
    const rate = `${formatRate(state.rate.tokensPerSecond)} tok/s`;
    right.push({ key: "rate", text: state.rate.estimated ? dim(`~${rate}`) : muted(rate) });
  }
  right.push({ key: "model", text: plain(label(state.model)) });
  if (flags.effort && state.effort) {
    right.push({ key: "effort", text: colorizeEffort(theme, state.effort, label(state.effort)) });
  }

  const renderRight = (parts: RightPart[]) => parts.map((part) => part.text).join(separator);
  let visibleRight = right;
  while (visibleRight.length > 1 && width - visibleWidth(context) - visibleWidth(renderRight(visibleRight)) < 2) {
    const lowest = RIGHT_DROP_ORDER.find((key) => visibleRight.some((part) => part.key === key));
    if (lowest === undefined) break;
    visibleRight = visibleRight.filter((part) => part.key !== lowest);
  }
  const model = renderRight(visibleRight);

  // Token totals, cost, and cache stats ride the free right side of the location
  // line, so the context line keeps carrying only the current state. Each part is
  // omitted until there is something to show, matching the built-in footer.
  interface StatsPart { key: "tokens" | "cost" | "cacheHit" | "cache"; text: string }
  const stats: StatsPart[] = [];
  if (flags.tokens) {
    const counts = [
      state.input ? muted(`↑${formatWindow(state.input)}`) : "",
      state.output ? muted(`↓${formatWindow(state.output)}`) : "",
    ].filter(Boolean).join(" ");
    if (counts) stats.push({ key: "tokens", text: counts });
  }
  if (flags.cost && state.cost !== undefined && state.cost > 0) {
    stats.push({ key: "cost", text: plain(`$${state.cost.toFixed(3)}`) });
  }
  if (flags.cacheHit && state.cacheHitPercent !== undefined) {
    // A low hit rate is what actually costs money, so it is worth a color.
    const hit = `ch ${state.cacheHitPercent.toFixed(1)}%`;
    stats.push({
      key: "cacheHit",
      text: state.cacheHitPercent >= 60
        ? theme.fg("success", hit)
        : state.cacheHitPercent < 30
          ? theme.fg("warning", hit)
          : muted(hit),
    });
  }
  if (flags.cache && (state.cacheRead || state.cacheWrite)) {
    // Reads are the cheap path, writes are the expensive one (Anthropic bills 1h
    // writes at 2x input). Providers without prompt caching report zero.
    const counts = [
      state.cacheRead ? muted(`r ${formatWindow(state.cacheRead)}`) : "",
      state.cacheWrite ? muted(`w ${formatWindow(state.cacheWrite)}`) : "",
    ].filter(Boolean).join(" ");
    stats.push({ key: "cache", text: counts });
  }

  const renderStats = (parts: StatsPart[]) => parts.map((part) => part.text).join(separator);
  let visibleStats = stats;
  while (visibleStats.length > 0 && width - visibleWidth(location) - visibleWidth(renderStats(visibleStats)) < 2) {
    const lowest = STATS_DROP_ORDER.find((key) => visibleStats.some((part) => part.key === key));
    if (lowest === undefined) break;
    visibleStats = visibleStats.filter((part) => part.key !== lowest);
  }
  const statsText = renderStats(visibleStats);

  const lines: string[] = [];
  if (!statsText) {
    lines.push(truncateToWidth(location, width));
  } else if (width - visibleWidth(location) - visibleWidth(statsText) >= 2) {
    lines.push(location + " ".repeat(width - visibleWidth(location) - visibleWidth(statsText)) + statsText);
  } else {
    // In narrow panes keep both fields: location first, stats right-aligned below.
    lines.push(truncateToWidth(location, width));
    const fitted = truncateToWidth(statsText, width);
    lines.push(" ".repeat(Math.max(0, width - visibleWidth(fitted))) + fitted);
  }
  const gap = width - visibleWidth(context) - visibleWidth(model);
  if (gap >= 2) {
    lines.push(context + " ".repeat(gap) + model);
  } else {
    // In narrow panes, keep all fields and put the model on the bottom right.
    lines.push(...wrapTextWithAnsi(context, width).map((line) => truncateToWidth(line, width)));
    for (const line of wrapTextWithAnsi(model, width)) {
      const fitted = truncateToWidth(line, width);
      lines.push(" ".repeat(Math.max(0, width - visibleWidth(fitted))) + fitted);
    }
  }
  return lines;
}

export default function minimalStatusline(pi: ExtensionAPI) {
  let enabled = true;
  let preset = loadPreset();
  let refresh: (() => void) | undefined;
  let ticker: ReturnType<typeof setInterval> | undefined;
  // Only the session whose footer is installed may drive the live state; forked
  // sessions in the same process share this module scope.
  let installedSessionId: string | undefined;

  // Live turn state, written by the event handlers and read on every render.
  let turnStartedAt: number | undefined;
  let phase: ActivitySnapshot["phase"] = "waiting";
  let toolName: string | undefined;
  let toolStartedAt: number | undefined;
  let stream: { firstDeltaAt?: number; chars: number; exactTokens?: number } | undefined;
  let rate: RateSnapshot | undefined;

  const ensureTicker = () => {
    if (ticker) return;
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
      phase,
      toolName,
      elapsedMs: phase === "tool" && toolStartedAt !== undefined ? now - toolStartedAt : now - turnStartedAt,
      frame: SPINNER_FRAMES[Math.floor(now / 100) % SPINNER_FRAMES.length],
    };
  }

  /**
   * While tokens are arriving the provider has not reported a usage count yet, so the
   * rate is estimated from streamed text (prefixed with `~`); once the message ends,
   * the exact `usage.output` over the same window replaces it and stays on screen.
   */
  function currentRate(now: number): RateSnapshot | undefined {
    if (stream?.firstDeltaAt !== undefined && stream.exactTokens === undefined) {
      const seconds = (now - stream.firstDeltaAt) / 1000;
      if (seconds >= 0.35) {
        return { tokensPerSecond: stream.chars / CHARS_PER_TOKEN / seconds, estimated: true };
      }
    }
    return rate;
  }

  /** Events from other sessions in this process must not touch the visible footer. */
  function owns(ctx: ExtensionContext): boolean {
    return ctx.mode === "tui" && ctx.sessionManager.getSessionId() === installedSessionId;
  }

  function install(ctx: ExtensionContext) {
    if (ctx.mode !== "tui") return;
    installedSessionId = ctx.sessionManager.getSessionId();
    ctx.ui.setFooter(enabled ? (tui, theme, footerData) => {
      let cachedKey: string | undefined;
      let usage: ContextUsage | undefined;
      let sessionUsage: SessionUsage | undefined;
      // Read once per install: it only changes when the user edits settings.
      const compaction = pi.getSettings().compaction;
      const autoCompactReserve = compaction?.enabled === false
        ? undefined
        : (compaction?.reserveTokens ?? DEFAULT_RESERVE_TOKENS);
      const requestUpdate = () => {
        cachedKey = undefined;
        tui.requestRender();
      };
      refresh = requestUpdate;
      const unsubscribe = footerData.onBranchChange(requestUpdate);

      return {
        dispose() {
          unsubscribe();
          if (refresh === requestUpdate) refresh = undefined;
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
          // Avoid rebuilding the long conversation projection on every editor keystroke.
          // Every append moves the leaf, so the key also covers usage entries that
          // arrive outside a message (cache_warm, tool results, compaction).
          if (key !== cachedKey) {
            usage = ctx.getContextUsage();
            sessionUsage = readSessionUsage(manager.getEntries());
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
            rate: currentRate(now),
            preset,
          }, theme, width);

          // Normally absent; retain warnings/statuses published by other extensions.
          if (width > 0) {
            for (const status of footerData.getExtensionStatuses().values()) {
              const text = theme.fg("dim", "│ ") + theme.fg("muted", stripVTControlCharacters(status));
              lines.push(...wrapTextWithAnsi(text, width).map((line) => truncateToWidth(line, width)));
            }
          }
          return lines;
        },
      };
    } : undefined);
  }

  pi.on("session_start", (_event, ctx) => install(ctx));
  pi.on("agent_start", (_event, ctx) => {
    if (!owns(ctx)) return;
    turnStartedAt = Date.now();
    phase = "waiting";
    toolName = undefined;
    toolStartedAt = undefined;
    stream = undefined;
    rate = undefined;
    ensureTicker();
  });
  pi.on("agent_end", (_event, ctx) => {
    if (!owns(ctx)) return;
    turnStartedAt = undefined;
    toolName = undefined;
    toolStartedAt = undefined;
    stream = undefined;
    stopTicker();
    refresh?.();
  });
  pi.on("message_start", (event, ctx) => {
    if (!owns(ctx)) return;
    if (event.message.role === "assistant") stream = { chars: 0 };
  });
  pi.on("message_update", (event, ctx) => {
    if (!owns(ctx)) return;
    if (event.message.role !== "assistant") return;
    const delta = event.assistantMessageEvent;
    if (delta.type !== "text_delta" && delta.type !== "thinking_delta") return;
    if (!stream) stream = { chars: 0 };
    if (stream.firstDeltaAt === undefined) stream.firstDeltaAt = Date.now();
    stream.chars += delta.delta.length;
    phase = "streaming";
    ensureTicker();
  });
  pi.on("tool_execution_start", (event, ctx) => {
    if (!owns(ctx)) return;
    phase = "tool";
    toolName = event.toolName;
    toolStartedAt = Date.now();
    ensureTicker();
  });
  pi.on("tool_execution_end", (_event, ctx) => {
    if (!owns(ctx)) return;
    phase = "waiting";
    toolName = undefined;
    toolStartedAt = undefined;
    refresh?.();
  });
  pi.on("message_end", (event, ctx) => {
    if (!owns(ctx)) return;
    if (event.message.role === "assistant") {
      const output = event.message.usage.output;
      const first = stream?.firstDeltaAt;
      if (first !== undefined && output > 0) {
        const seconds = (Date.now() - first) / 1000;
        if (seconds > 0.05) rate = { tokensPerSecond: output / seconds, estimated: false };
      }
      // Freeze the estimate: no more characters will arrive for this message.
      stream = { chars: stream?.chars ?? 0, exactTokens: output };
    }
    refresh?.();
  });
  pi.on("model_select", () => refresh?.());
  pi.on("thinking_level_select", () => refresh?.());
  pi.on("session_compact", () => refresh?.());
  pi.on("session_tree", () => refresh?.());
  pi.on("session_shutdown", (_event, ctx) => {
    stopTicker();
    if (ctx.mode === "tui" && enabled) ctx.ui.setFooter(undefined);
    refresh = undefined;
  });

  pi.registerCommand("statusline", {
    description: "Switch footer: /statusline custom | default (no argument toggles), preset: full | minimal | cost",
    handler: async (args, ctx) => {
      if (ctx.mode !== "tui") return;
      const choice = args.trim();
      if (choice === "full" || choice === "minimal" || choice === "cost") {
        preset = choice;
        savePreset(preset);
        enabled = true;
        install(ctx);
        ctx.ui.notify(`Statusline preset: ${preset}`, "info");
        return;
      }
      if (choice && choice !== "custom" && choice !== "default") {
        ctx.ui.notify("Usage: /statusline custom | default | full | minimal | cost", "info");
        return;
      }
      enabled = choice ? choice === "custom" : !enabled;
      install(ctx);
    },
  });
}
