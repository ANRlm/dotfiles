import { homedir } from "node:os";
import { stripVTControlCharacters } from "node:util";
import type { ContextUsage, ExtensionAPI, ExtensionContext, Theme } from "@earendil-works/pi-coding-agent";
import { parseColor, truncateToWidth, visibleWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";

const WHITE = parseColor("#FFFFFF");

/** Local footer: location above, remaining context left, model/effort right. */
export interface FooterSnapshot {
  cwd: string;
  home: string;
  branch?: string;
  model: string;
  effort: string;
  window?: number;
  usedPercent?: number | null;
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

export function renderFooter(state: FooterSnapshot, theme: Theme, width: number): string[] {
  width = Math.max(0, Math.floor(width));
  if (width === 0) return [];

  const white = (text: string) => theme.style(text, { fg: WHITE });
  const cwd = state.cwd === state.home
    ? "~"
    : state.cwd.startsWith(`${state.home}/`)
      ? `~${state.cwd.slice(state.home.length)}`
      : state.cwd;
  const location = white(label(cwd)) + (state.branch ? white(` (${label(state.branch)})`) : "");
  const model = white(label(state.model)) + (state.effort ? white(` (${label(state.effort)})`) : "");

  const left = typeof state.usedPercent === "number" && Number.isFinite(state.usedPercent)
    ? Math.max(0, Math.min(100, 100 - state.usedPercent))
    : undefined;
  const budgetColor = (text: string) => left !== undefined && left < 10
    ? theme.fg("error", text)
    : left !== undefined && left < 25
      ? theme.fg("warning", text)
      : white(text);
  const barWidth = 10;
  // A half-cell endpoint leaves a small gap before the used track.
  const halves = left === undefined ? 0 : Math.floor(left * barWidth * 2 / 100);
  const full = Math.floor(halves / 2);
  const half = halves % 2;
  const track = barWidth - full - half;
  const filled = half
    ? "━".repeat(full) + "╸"
    : full > 0 && track > 0
      ? "━".repeat(full - 1) + "╸"
      : "━".repeat(full);
  const bar = budgetColor(filled) + white("─".repeat(track));
  const percentage = left === undefined
    ? white("—")
    : budgetColor(`${Math.round(left)}%`);
  const context = white("ctx ") + white(formatWindow(state.window)) + ` ${bar} ${percentage}`;

  const lines = [truncateToWidth(location, width)];
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
  let refresh: (() => void) | undefined;

  function install(ctx: ExtensionContext) {
    if (ctx.mode !== "tui") return;
    ctx.ui.setFooter(enabled ? (tui, theme, footerData) => {
      let cachedKey: string | undefined;
      let usage: ContextUsage | undefined;
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
          const model = ctx.model;
          const manager = ctx.sessionManager;
          const key = JSON.stringify([
            manager.getSessionId(), manager.getLeafId(),
            model?.provider, model?.id, model?.contextWindow,
          ]);
          // Avoid rebuilding the long conversation projection on every editor keystroke.
          if (key !== cachedKey) {
            usage = ctx.getContextUsage();
            cachedKey = key;
          }
          const lines = renderFooter({
            cwd: manager.getCwd(),
            home: homedir(),
            branch: footerData.getGitBranch() ?? undefined,
            model: model?.id ?? "no model",
            effort: ctx.thinkingLevel ?? pi.getThinkingLevel(),
            window: usage?.contextWindow ?? model?.contextWindow,
            usedPercent: usage?.percent,
          }, theme, width);

          // Normally absent; retain warnings/statuses published by other extensions.
          if (width > 0) {
            for (const status of footerData.getExtensionStatuses().values()) {
              const text = theme.style(stripVTControlCharacters(status), { fg: WHITE });
              lines.push(...wrapTextWithAnsi(text, width).map((line) => truncateToWidth(line, width)));
            }
          }
          return lines;
        },
      };
    } : undefined);
  }

  pi.on("session_start", (_event, ctx) => install(ctx));
  pi.on("model_select", () => refresh?.());
  pi.on("thinking_level_select", () => refresh?.());
  pi.on("message_end", () => refresh?.());
  pi.on("tool_execution_end", () => refresh?.());
  pi.on("session_compact", () => refresh?.());
  pi.on("session_tree", () => refresh?.());
  pi.on("agent_end", () => refresh?.());
  pi.on("session_shutdown", (_event, ctx) => {
    if (ctx.mode === "tui" && enabled) ctx.ui.setFooter(undefined);
    refresh = undefined;
  });

  pi.registerCommand("statusline", {
    description: "Switch footer: /statusline custom or /statusline default (no argument toggles)",
    handler: async (args, ctx) => {
      if (ctx.mode !== "tui") return;
      const choice = args.trim();
      if (choice && choice !== "custom" && choice !== "default") {
        ctx.ui.notify("Usage: /statusline custom | default", "info");
        return;
      }
      enabled = choice ? choice === "custom" : !enabled;
      install(ctx);
    },
  });
}
