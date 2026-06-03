# Claude Code Global Instructions

User-wide defaults for Claude Code. Project-level `CLAUDE.md` files override these instructions when they are more specific.

## Scope

- This file is managed in `~/dotfiles/claude/CLAUDE.md` and linked to `~/.claude/CLAUDE.md`.
- Use these defaults across projects unless local instructions conflict.
- Keep generated code, comments, variable names, and commit messages in English.
- Respond in Chinese when the user writes in Chinese; respond in English when the user writes in English.

## Commands

These commands apply when working in the `~/dotfiles` repository.

| Command | Description |
|---------|-------------|
| `bash scripts/setup.sh` | Bootstrap a new macOS machine, then run restore |
| `bash scripts/restore.sh` | Restore symlinks, install Homebrew bundle, set up tmux plugins, and set Fish as the default shell |
| `brew bundle --file=Brewfile` | Install packages listed in the Brewfile |
| `goku` | Generate Karabiner config from EDN when available |
| `u` | Run the Fish update function for local tooling |

## Architecture

```text
dotfiles/
  bat/        # bat config
  btop/       # btop config
  claude/     # Claude Code global instructions
  conda/      # Conda config
  fish/       # Fish shell config, functions, completions
  ghostty/    # Ghostty terminal config and shaders
  git/        # Git config
  karabiner/  # Karabiner and Goku config
  lazygit/    # lazygit config
  nvim/       # AstroNvim config
  scripts/    # setup, restore, and privacy scripts
  starship/   # Starship prompt config
  tmux/       # tmux config and plugins
  yazi/       # yazi config and plugins
  Brewfile    # Homebrew bundle
```

## Key Files

- `scripts/setup.sh` - full bootstrap for a new macOS machine.
- `scripts/restore.sh` - idempotent dotfiles restore entry point for existing machines.
- `Brewfile` - Homebrew packages, casks, and MAS apps.
- `fish/config.fish` - shell environment, abbreviations, and interactive setup.
- `tmux/tmux.conf` - tmux terminal, mouse, clipboard, and keybinding behavior.
- `ghostty/config` - Ghostty terminal UI and shell integration.
- `claude/CLAUDE.md` - source file for the global Claude Code instruction symlink.

## Environment

- OS: macOS on Apple Silicon.
- Shell: Fish with Starship.
- Terminal stack: Ghostty and tmux.
- Primary editor: Neovim with AstroNvim.
- Package managers: Homebrew for system packages, pnpm as primary JS package manager, bun as secondary.
- Python tooling: Conda/Miniforge and uv.
- Common CLI tools: `rg`, `fd`, `bat`, `eza`, `btop`, `lazygit`, `yazi`.

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

- Commit subjects should be concise, imperative, and English.
- Do not force push without explicit confirmation.
- Do not revert unrelated user changes.
- Prefer `lazygit` for interactive Git workflows and `gh` for GitHub operations.

## Safety

- Confirm before destructive operations such as `rm -rf`, force push, or history rewriting.
- Do not use `sudo` without first explaining why it is needed.
- Do not create README or documentation files unless asked.
- Do not add broad validation or defensive error handling to internal code unless requested.

## Gotchas

- `~/.claude/CLAUDE.md` is a symlink to `~/dotfiles/claude/CLAUDE.md`; edit the dotfiles source.
- `scripts/setup.sh` calls `scripts/restore.sh`, so restore changes usually do not need duplicated setup changes.
- `scripts/restore.sh` links config directories into `~/.config/` and links the global Claude instructions separately.
- Some files in this repository are intentionally machine-specific; avoid broad cleanup unless requested.
