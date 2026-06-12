# Claude Code Global Instructions

User-wide defaults for Claude Code. Project-level `CLAUDE.md` files override these instructions when they are more specific.

## Scope

- This file is managed in `~/dotfiles/claude/CLAUDE.md` and symlinked to `~/.claude/CLAUDE.md`.
- Use these defaults across all projects unless a local `CLAUDE.md` or `.claude.md` overrides them.
- Keep generated code, comments, variable names, and commit messages in English.
- Respond in Chinese when the user writes in Chinese; respond in English when the user writes in English.

## Environment

- OS: macOS on Apple Silicon.
- Shell: Fish with Starship prompt.
- Terminal: Ghostty + tmux.
- Editor: Neovim with AstroNvim.
- Package managers: Homebrew (system), pnpm (primary JS), bun (secondary JS).
- Python: Conda/Miniforge and uv.
- CLI toolkit: `rg`, `fd`, `bat`, `eza`, `btop`, `lazygit`, `yazi`.

## Code Style

| Language | Indent | Quotes | Notes |
|----------|--------|--------|-------|
| Lua | 2 spaces | double | StyLua, 120 columns, omit call parentheses where idiomatic |
| JavaScript/TypeScript | 2 spaces | double | Prettier |
| YAML/TOML | 2 spaces | project style | Keep keys ordered with surrounding config |
| Python | 4 spaces | double | Do not add type annotations unless requested |
| Go | tabs | double | gofmt, no unnecessary comments |
| Rust | 4 spaces | double | rustfmt |

- Use LF line endings.
- Match surrounding style when editing existing files.
- Add comments only when they explain non-obvious behavior.

## Workflow

- Prefer terminal-native tools over GUI workflows.
- Prefer `rg`, `fd`, `bat`, and `eza` over slower or less readable alternatives.
- Write shell examples in Fish syntax unless a script is explicitly Bash.
- Assume Neovim for editor-oriented instructions.
- Follow XDG conventions for config paths.
- Use existing project patterns before introducing new abstractions.

## Git

- Commit subjects: concise, imperative, English.
- Do not force push without explicit confirmation.
- Do not revert unrelated user changes.
- Prefer `lazygit` for interactive Git workflows and `gh` for GitHub operations.

## Safety

- Confirm before destructive operations (`rm -rf`, force push, history rewriting).
- Do not use `sudo` without explaining why it is needed.
- Do not create README or documentation files unless asked.
- Do not add broad validation or defensive error handling to internal code unless requested.

## CLAUDE.md Management

- Press `#` during a Claude Code session to auto-incorporate learnings into the appropriate CLAUDE.md.
- Edit `~/dotfiles/claude/CLAUDE.md` (not `~/.claude/CLAUDE.md`) — the latter is a symlink.
- Keep content concise and human-readable; one line per concept when possible.

---

## Dotfiles

The sections below apply when working in the `~/dotfiles` repository.

### Commands

| Command | Description |
|---------|-------------|
| `bash scripts/setup.sh` | Bootstrap a new macOS machine (calls `restore.sh` internally) |
| `bash scripts/restore.sh` | Symlink configs, install Homebrew bundle, set up tmux/tpm, set Fish as default shell |
| `brew bundle --file=Brewfile` | Install all packages, casks, and MAS apps listed in the Brewfile |
| `brew bundle dump --force --file=Brewfile --no-vscode` | Snapshot current Homebrew state back into the Brewfile |
| `u` | Fish function: update all tooling (Homebrew, Conda, Node, Python, Fish/Fisher, tmux/TPM, Neovim/Lazy+Mason, Yazi, MAS, Mole) and auto-dump Brewfile |
| `goku` | Generate `karabiner/config` (JSON) from `karabiner/edn` (EDN source) |

### Architecture

```text
dotfiles/
  bat/        # bat config
  btop/       # btop config
  claude/     # Claude Code global instructions (symlinked to ~/.claude/)
  conda/      # Conda config
  fish/       # Fish shell config, functions, completions
  ghostty/    # Ghostty terminal config and shaders
  git/        # Git config
  karabiner/  # Karabiner-Elements config (edn/ source + config/ generated JSON)
  lazygit/    # lazygit config
  nvim/       # AstroNvim config
  scripts/    # setup, restore, and privacy scripts
  starship/   # Starship prompt config
  tmux/       # tmux config and plugins
  yazi/       # yazi config and plugins
  Brewfile    # Homebrew bundle (auto-updated by `u`)
```

### Key Files

- `scripts/setup.sh` — full bootstrap for a new macOS machine.
- `scripts/restore.sh` — idempotent dotfiles restore entry point for existing machines.
- `Brewfile` — Homebrew packages, casks, and MAS apps (auto-updated by `u`).
- `fish/config.fish` — shell environment, abbreviations, and interactive setup.
- `fish/functions/u.fish` — the `u` update-orchestrator function.
- `tmux/tmux.conf` — tmux terminal, mouse, clipboard, and keybinding behavior.
- `ghostty/config` — Ghostty terminal UI and shell integration.
- `karabiner/edn/` — Goku EDN source for Karabiner key mappings.
- `claude/CLAUDE.md` — source file for the global Claude Code instruction symlink.

### Gotchas

- `~/.claude/CLAUDE.md` is a symlink to `~/dotfiles/claude/CLAUDE.md`; always edit the dotfiles source.
- `scripts/setup.sh` calls `scripts/restore.sh` internally — restore changes usually don't need duplicated setup changes.
- `scripts/restore.sh` symlinks config directories into `~/.config/` and links the global Claude instructions separately.
- Running `u` auto-dumps the current Homebrew state to `Brewfile` via `brew bundle dump --force`. If you manually install or remove a brew package, either run `u` or dump the Brewfile separately to keep them in sync.
- Some files in this repository are intentionally machine-specific; avoid broad cleanup unless requested.
