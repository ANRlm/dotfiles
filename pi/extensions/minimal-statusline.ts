import { homedir } from "node:os";
import { stripVTControlCharacters } from "node:util";
import type { ContextUsage, ExtensionAPI, ExtensionContext, SessionEntry, Theme } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";

/** Spinner frames for the live activity marker; each render advances it. */
const SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

const SEPARATOR = " · ";

/** Footer state while the agent is working; absent when idle. */
export interface ActivitySnapshot {
  phase: "waiting" | "thinking" | "streaming" | "tool" | "compacting" | "finishing";
  toolName?: string;
  toolCount?: number;
  frame: string;
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
  cacheHitPercent?: number;
  cacheRead?: number;
  cacheWrite?: number;
  activity?: ActivitySnapshot;
}

function label(text: string): string {
  return stripVTControlCharacters(text).replace(/[\x00-\x1f\x7f-\x9f]/g, " ");
}

/** Remaining-window gauge; color follows the same remaining share it draws. */
export function renderContext(state: FooterSnapshot, theme: Theme, budget: number): string {
  const dim = (text: string) => theme.fg("dim", text);
  const plain = (text: string) => theme.fg("text", text);
  const windowSize = state.window !== undefined && Number.isFinite(state.window) && state.window > 0
    ? state.window : undefined;
  const used = typeof state.usedPercent === "number" && Number.isFinite(state.usedPercent)
    ? Math.max(0, Math.min(100, state.usedPercent)) : undefined;
  if (used === undefined || windowSize === undefined) {
    return `${dim("ctx")} ${plain(`—/${formatWindow(windowSize)}`)} · ${dim("usage pending")}`;
  }
  const remaining = 100 - used;
  const remainingTokens = windowSize * remaining / 100;
  // Yellow below 30%, red below 10% remaining.
  const color = remaining < 10 ? "error" : remaining < 30 ? "warning" : "text";
  const accent = (text: string) => theme.fg(color, text);
  const prefix = `${dim("ctx")} ${plain(`${remainingTokens === 0 ? "0" : formatWindow(remainingTokens)}/${formatWindow(windowSize)}`)}`;
  // Color alone is not a reliable signal on every theme, so add an ASCII marker.
  const percent = remaining < 10 ? accent(`! ${Math.round(remaining)}% left`) : plain(`${Math.round(remaining)}% left`);
  // Shrink the decoration before removing the redundant absolute remaining ratio.
  for (const size of [14, 10, 6]) {
    const halves = Math.floor(remaining * size * 2 / 100);
    const filled = Math.floor(halves / 2);
    const half = halves % 2;
    const bar = accent("━".repeat(filled) + (half ? "╸" : "")) + dim("─".repeat(size - filled - half));
    const text = `${prefix} ${bar} ${percent}`;
    if (visibleWidth(text) <= budget) return text;
  }
  const withoutBar = `${prefix} ${percent}`;
  if (visibleWidth(withoutBar) <= budget) return withoutBar;
  const compact = `${dim("ctx")} ${percent}`;
  // If even the compact form cannot fit, let the caller wrap the complete values.
  return visibleWidth(compact) <= budget ? compact : withoutBar;
}

function joinSides(left: string, right: string, width: number): string {
  if (!right) return truncateToWidth(left, width);
  if (!left) return truncateToWidth(right, width);
  const gap = width - visibleWidth(left) - visibleWidth(right);
  return truncateToWidth(left + " ".repeat(Math.max(2, gap)) + right, width);
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
  cacheHitPercent?: number;
}

function addUsage(
  totals: SessionUsage,
  usage: { input: number; output: number; cacheRead?: number; cacheWrite?: number },
): void {
  totals.input += usage.input;
  totals.output += usage.output;
  totals.cacheRead += usage.cacheRead ?? 0;
  totals.cacheWrite += usage.cacheWrite ?? 0;
}

/** Prompt samples behind the hit rate; a long session must not drown out a cold streak. */
const CACHE_WINDOW = 20;

/**
 * Sum every usage-bearing session entry, exactly like Pi's built-in footer: plain
 * `usage` entries, assistant messages, tool results, and compaction/branch summaries.
 * Summing only the current branch would disagree with `/session` after branching or
 * compaction. The cache-hit rate is prompt-weighted over the last `CACHE_WINDOW`
 * samples only, so a cold streak stays visible in a long session.
 */
export function readSessionUsage(entries: readonly SessionEntry[]): SessionUsage {
  const totals: SessionUsage = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 };
  // Prompt samples in order; only the tail feeds the hit rate.
  const prompts: Array<[cached: number, prompt: number]> = [];
  type UsageNumbers = Parameters<typeof addUsage>[1];
  const note = (usage: UsageNumbers) => {
    addUsage(totals, usage);
    const cached = usage.cacheRead ?? 0;
    prompts.push([cached, usage.input + cached + (usage.cacheWrite ?? 0)]);
  };
  for (const entry of entries) {
    if (entry.type === "message" && entry.message.role === "assistant") {
      note(entry.message.usage);
    } else if (entry.type === "message" && entry.message.role === "toolResult") {
      if (entry.message.usage) note(entry.message.usage);
    } else if (entry.type === "usage") {
      note(entry.usage);
    } else if (entry.type === "compaction" || entry.type === "branch_summary") {
      if (entry.usage) note(entry.usage);
    }
  }
  const recent = prompts.slice(-CACHE_WINDOW);
  const cached = recent.reduce((sum, [read]) => sum + read, 0);
  const promptTokens = recent.reduce((sum, [, prompt]) => sum + prompt, 0);
  totals.cacheHitPercent = promptTokens > 0 ? (cached / promptTokens) * 100 : undefined;
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
  // Both ends of the row are cut with `…`; nothing moves to another line.
  const location = (budget: number) => {
    const fullPath = label(cwd);
    const branch = state.branch && budget >= 12
      ? muted(` ${truncateToWidth(`[${label(state.branch)}]`, Math.min(18, Math.floor(budget / 3)) + 2)}`)
      : "";
    const pathBudget = Math.max(0, budget - visibleWidth(branch));
    const tail = `…/${fullPath.split("/").pop()}`;
    const path = visibleWidth(fullPath) <= pathBudget || visibleWidth(tail) > pathBudget ? fullPath : tail;
    return truncateToWidth(plain(truncateToWidth(path, pathBudget)) + branch, Math.max(0, budget));
  };

  const contextFor = (budget: number) => renderContext(state, theme, budget);

  // Identity stays on row two; live activity can overflow below on narrow panes.
  // Concurrent tools keep the newest name and count them, e.g. `tool Task ×2`.
  const activity = state.activity;
  const phaseLabel = !activity ? "" : activity.phase === "tool"
    ? `tool ${label(activity.toolName ?? "tool")}${activity.toolCount && activity.toolCount > 1 ? ` ×${activity.toolCount}` : ""}`
    : { waiting: "waiting", thinking: "thinking", streaming: "streaming", compacting: "compacting", finishing: "finishing" }[activity.phase];
  const live = activity ? `${theme.fg("accent", activity.frame)} ${theme.fg("toolTitle", phaseLabel)}` : "";
  const identity = [
    plain(label(state.model)),
    state.effort ? colorizeEffort(theme, state.effort, label(state.effort)) : "",
  ].filter(Boolean).join(separator);
  const allRight = [live, identity].filter(Boolean).join(separator);

  // Only the cache hit rate rides the free right side of the location line. That
  // keeps the footer quiet; the r/w numbers live in the built-in footer if needed.
  // `cacheRead`/`cacheWrite` gate this like the built-in footer: a provider that does
  // not report caching at all would otherwise show a fabricated 0% hit rate.
  const statsText = state.cacheHitPercent !== undefined && (state.cacheRead || state.cacheWrite)
    // A cold first request is normal; a single low hit rate is not a warning.
    ? muted(`cache ${state.cacheHitPercent.toFixed(1)}%`)
    : "";
  const overflow: string[] = [];
  const appendOverflow = (text: string) => overflow.push(...wrapTextWithAnsi(text, width));
  const locationMinimum = Math.min(18, Math.floor(width / 4));
  const statsFit = visibleWidth(statsText) + locationMinimum + 2 <= width;
  if (!statsFit) appendOverflow(statsText);
  const topStats = statsFit ? statsText : "";
  const top = joinSides(location(Math.max(0, width - visibleWidth(topStats) - 2)), topStats, width);

  // Keep model and effort on row two, even when idle. Overflow is visible, never
  // hidden behind a preset/details view. Size ctx against the actual right block.
  const fitsRow = (rightText: string) =>
    visibleWidth(contextFor(width - visibleWidth(rightText) - 2)) + visibleWidth(rightText) + 2 <= width;
  let bottom: string;
  if (fitsRow(allRight)) {
    bottom = joinSides(contextFor(width - visibleWidth(allRight) - 2), allRight, width);
  } else if (fitsRow(identity)) {
    bottom = joinSides(contextFor(width - visibleWidth(identity) - 2), identity, width);
    if (live) appendOverflow(live);
  } else {
    // Last resort: wrap the identity above the gauge rather than hiding anything.
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
  let refresh: (() => void) | undefined;
  let ticker: ReturnType<typeof setInterval> | undefined;
  // Only the session whose footer is installed may drive the live state; forked
  // sessions in the same process share this module scope.
  let installedSessionId: string | undefined;

  // Live turn state, written by the event handlers and read on every render.
  let live = false;
  let phase: ActivitySnapshot["phase"] = "waiting";
  const activeTools = new Map<string, { name: string }>();
  let compactionStandalone = false;

  const stopTicker = () => {
    if (ticker) clearInterval(ticker);
    ticker = undefined;
  };
  /** Repaint now, and keep the spinner moving for as long as the turn is live. */
  function paint() {
    if (live && enabled && refresh && !ticker) {
      ticker = setInterval(() => refresh?.(), 200);
      ticker.unref?.();
    }
    refresh?.();
  }

  /** The frame follows the render clock, so it advances on every repaint. */
  function currentActivity(now: number): ActivitySnapshot | undefined {
    if (!live) return undefined;
    return {
      phase: phase === "compacting" ? phase : activeTools.size ? "tool" : phase,
      toolName: [...activeTools.values()].at(-1)?.name,
      toolCount: activeTools.size,
      frame: SPINNER_FRAMES[Math.floor(now / 100) % SPINNER_FRAMES.length],
    };
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
      // Render-only: the cache key below already covers every append that can change
      // the numbers, so clearing it here would just force the projection rebuild that
      // an editor keystroke or a live activity update would otherwise trigger.
      const requestUpdate = () => tui.requestRender();
      refresh = requestUpdate;
      const unsubscribe = footerData.onBranchChange(requestUpdate);

      return {
        dispose() {
          unsubscribe();
          stopTicker();
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
          // Avoid rebuilding the long conversation projection on every editor keystroke
          // or activity tick. Every append moves the leaf, so the key also covers usage
          // entries that arrive outside a message (cache_warm, tool results, compaction),
          // and the model part also covers context-window changes.
          if (key !== cachedKey) {
            usage = ctx.getContextUsage();
            sessionUsage = readSessionUsage(manager.getEntries());
            cachedKey = key;
          }
          const contextWindow = usage?.contextWindow ?? model?.contextWindow;
          return renderFooter({
            cwd: manager.getCwd(),
            home: homedir(),
            branch: footerData.getGitBranch() ?? undefined,
            // Two providers can serve the same model id; the badge tells them apart.
            model: model ? `${model.id} (${model.provider})` : "no model",
            effort: ctx.thinkingLevel ?? pi.getThinkingLevel(),
            window: contextWindow,
            usedPercent: usage?.percent,
            cacheHitPercent: sessionUsage?.cacheHitPercent,
            cacheRead: sessionUsage?.cacheRead,
            cacheWrite: sessionUsage?.cacheWrite,
            activity: currentActivity(now),
          }, theme, width);
        },
      };
    } : undefined);
  }

  const resetLive = () => {
    live = false;
    stopTicker();
    activeTools.clear();
    phase = "waiting";
    compactionStandalone = false;
  };
  pi.on("session_start", (_event, ctx) => {
    if (ctx.mode !== "tui") return;
    resetLive();
    install(ctx);
  });
  pi.on("agent_start", (_event, ctx) => {
    if (!owns(ctx)) return;
    live = true;
    phase = "waiting";
    paint();
  });
  pi.on("agent_end", (_event, ctx) => {
    if (!owns(ctx)) return;
    phase = "finishing";
    paint();
  });
  pi.on("agent_settled", (_event, ctx) => {
    if (!owns(ctx)) return;
    resetLive();
    paint();
  });
  pi.on("before_provider_request", (_event, ctx) => {
    if (!owns(ctx)) return;
    phase = "waiting";
    paint();
  });
  pi.on("session_before_compact", (_event, ctx) => {
    if (!owns(ctx)) return;
    compactionStandalone = !live;
    live = true;
    phase = "compacting";
    paint();
  });
  const finishCompaction = (_event: unknown, ctx: ExtensionContext) => {
    if (!owns(ctx)) return;
    if (compactionStandalone) resetLive();
    else phase = "waiting";
    paint();
  };
  pi.on("session_compact", finishCompaction);
  pi.on("session_compact_failed", finishCompaction);
  pi.on("message_start", (event, ctx) => {
    if (!owns(ctx)) return;
    if (event.message.role === "assistant") {
      phase = "waiting";
      paint();
    }
  });
  pi.on("message_update", (event, ctx) => {
    if (!owns(ctx)) return;
    if (event.message.role !== "assistant") return;
    const type = event.assistantMessageEvent.type;
    if (type !== "text_delta" && type !== "thinking_delta" && type !== "toolcall_delta") return;
    // No requestRender here: streamed output repaints the footer with each chunk.
    phase = type === "thinking_delta" ? "thinking" : "streaming";
  });
  pi.on("tool_execution_start", (event, ctx) => {
    if (!owns(ctx)) return;
    activeTools.set(event.toolCallId, { name: event.toolName });
    paint();
  });
  pi.on("tool_execution_end", (event, ctx) => {
    if (!owns(ctx)) return;
    activeTools.delete(event.toolCallId);
    if (!activeTools.size) phase = "waiting";
    paint();
  });
  pi.on("message_end", (event, ctx) => {
    if (!owns(ctx)) return;
    if (event.message.role === "assistant") phase = "waiting";
    paint();
  });
  pi.on("model_select", (_event, ctx) => {
    if (!owns(ctx)) return;
    paint();
  });
  pi.on("thinking_level_select", (_event, ctx) => {
    if (!owns(ctx)) return;
    paint();
  });
  pi.on("session_tree", (_event, ctx) => {
    if (!owns(ctx)) return;
    paint();
  });
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
