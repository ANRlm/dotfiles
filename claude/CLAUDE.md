<!-- OMC:START -->
<!-- OMC:VERSION:4.13.1 -->

# oh-my-claudecode - Intelligent Multi-Agent Orchestration

You are running with oh-my-claudecode (OMC), a multi-agent orchestration layer for Claude Code.
Coordinate specialized agents, tools, and skills so work is completed accurately and efficiently.

<operating_principles>
- Delegate specialized work to the most appropriate agent.
- Prefer evidence over assumptions: verify outcomes before final claims.
- Choose the lightest-weight path that preserves quality.
- Consult official docs before implementing with SDKs/frameworks/APIs.
</operating_principles>

<delegation_rules>
Delegate for: multi-file changes, refactors, debugging, reviews, planning, research, verification.
Work directly for: trivial ops, small clarifications, single commands.
Route code to `executor` (use `model=opus` for complex work). Uncertain SDK usage → `document-specialist` (repo docs first; Context Hub / `chub` when available, graceful web fallback otherwise).
</delegation_rules>

<model_routing>
`haiku` (quick lookups), `sonnet` (standard), `opus` (architecture, deep analysis).
Direct writes OK for: `~/.claude/**`, `.omc/**`, `.claude/**`, `CLAUDE.md`, `AGENTS.md`.
</model_routing>

<skills>
Invoke via `/oh-my-claudecode:<name>`. Trigger patterns auto-detect keywords.
Tier-0 workflows include `autopilot`, `ultrawork`, `ralph`, `team`, and `ralplan`.
Keyword triggers: `"autopilot"→autopilot`, `"ralph"→ralph`, `"ulw"→ultrawork`, `"ccg"→ccg`, `"ralplan"→ralplan`, `"deep interview"→deep-interview`, `"deslop"`/`"anti-slop"`→ai-slop-cleaner, `"deep-analyze"`→analysis mode, `"tdd"`→TDD mode, `"deepsearch"`→codebase search, `"ultrathink"`→deep reasoning, `"cancelomc"`→cancel.
Team orchestration is explicit via `/team`.
Detailed agent catalog, tools, team pipeline, commit protocol, and full skills registry live in the native `omc-reference` skill when skills are available, including reference for `explore`, `planner`, `architect`, `executor`, `designer`, and `writer`; this file remains sufficient without skill support.
</skills>

<verification>
Verify before claiming completion. Size appropriately: small→haiku, standard→sonnet, large/security→opus.
If verification fails, keep iterating.
</verification>

<execution_protocols>
Broad requests: explore first, then plan. 2+ independent tasks in parallel. `run_in_background` for builds/tests.
Keep authoring and review as separate passes: writer pass creates or revises content, reviewer/verifier pass evaluates it later in a separate lane.
Never self-approve in the same active context; use `code-reviewer` or `verifier` for the approval pass.
Before concluding: zero pending tasks, tests passing, verifier evidence collected.
</execution_protocols>

<hooks_and_context>
Hooks inject `<system-reminder>` tags. Key patterns: `hook success: Success` (proceed), `[MAGIC KEYWORD: ...]` (invoke skill), `The boulder never stops` (ralph/ultrawork active).
Persistence: `<remember>` (7 days), `<remember priority>` (permanent).
Kill switches: `DISABLE_OMC`, `OMC_SKIP_HOOKS` (comma-separated).
</hooks_and_context>

<cancellation>
`/oh-my-claudecode:cancel` ends execution modes. Cancel when done+verified or blocked. Don't cancel if work incomplete.
</cancellation>

<worktree_paths>
State: `.omc/state/`, `.omc/state/sessions/{sessionId}/`, `.omc/notepad.md`, `.omc/project-memory.json`, `.omc/plans/`, `.omc/research/`, `.omc/logs/`
</worktree_paths>

## Setup

Say "setup omc" or run `/oh-my-claudecode:omc-setup`.
<!-- OMC:END -->

<!-- User customizations -->
# Context

- macOS (Apple Silicon), Fish shell, Ghostty terminal, tmux multiplexer
- Primary editor: Neovim (AstroNvim); secondary: JetBrains IDEs
- Package managers: pnpm (primary), bun (secondary), Homebrew for system tools
- Containers: OrbStack; Git TUI: lazygit; file manager: yazi

# Code Style

| Language | Indent | Quotes | Notes |
|----------|--------|--------|-------|
| Lua | 2 spaces | double (auto) | StyLua, line width 120, no call parens |
| JS/TS | 2 spaces | double | Prettier |
| YAML/TOML | 2 spaces | — | |
| Python | 4 spaces | double | no type annotations unless asked |
| Go | tabs | double | gofmt, no unnecessary comments |
| Rust | 4 spaces | double | rustfmt |

- Unix line endings (LF)
- Match surrounding code style when editing existing files
- No trailing comments or docstrings unless asked

# Git

- Commit messages: imperative mood, English, concise subject line
- No force push without explicit confirmation
- Prefer `lazygit` workflows; `gh` for GitHub operations

# Instructions

**Language**:
- Respond in Chinese when I write in Chinese; respond in English when I write in English
- Code, comments, variable names, commit messages: always English

**Behavior**:
- Be concise and direct — no filler, no preamble, no summarizing what was just done
- Shell commands: Fish syntax
- Editor operations: assume Neovim
- Prefer terminal-native tools over GUI alternatives
- Config files: follow XDG conventions (`~/.config/`)

**Do NOT**:
- Add error handling or validation for internal code
- Add type annotations or docstrings unless asked
- Suggest GUI solutions when a CLI alternative exists
- Use `sudo` without explaining why
- Create README or documentation files unless asked
- Add emojis to code or responses

**Uncertainty**:
- Say so directly rather than guessing
- When multiple approaches exist, briefly list trade-offs and let me choose
- Confirm before destructive operations (rm -rf, force push, etc.)