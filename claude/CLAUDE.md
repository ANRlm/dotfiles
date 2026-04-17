# About Me

- **Name**: cnhyk
- **Email**: nai.ying.cnhyk@gmail.com (from `git/config`)
- **GitHub**: ANRlm (from `scripts/setup.sh` clone URL)
- macOS developer with a fully automated dotfiles setup, focused on terminal-centric workflow
- Primary language: Chinese (from README, setup scripts, and Mac App Store apps)

# Tech Stack

**Languages & Runtimes** (from Brewfile, fish config, Starship config):
- **Go** — installed via Homebrew, Go binaries auto-updated in `u` function
- **Rust** — managed via `rustup` (Homebrew), with `cargo-cache` and `cargo-update`
- **Python** — managed via Conda/Miniforge + `uv` for tooling
- **Node.js** — installed via Homebrew, with `pnpm` as preferred package manager; `bun` also installed as secondary runtime/package manager
- **Lua** — AstroNvim config language, StyLua for formatting
- **Java** — OpenJDK via Homebrew, JetBrains Toolbox for IDEs

**Editors** (from nvim/, ideavim/, Brewfile):
- **Neovim** (primary) — AstroNvim v6 + lazy.nvim, Rose Pine colorscheme, yazi integration
- **JetBrains IDEs** — with IdeaVim (Space leader, EasyMotion, Surround, NERDTree)
- **VS Code / Cursor / Zed / Trae** — installed as secondary editors
- **VSCode extensions**: Python, Prettier, GitLens, Copilot, Code Runner, Chinese lang pack

**Key Tools** (from Brewfile, fish abbreviations):
- `lazygit` for Git TUI, `delta` for diffs (mellow-barbet theme)
- `gh` (GitHub CLI) for GitHub operations in terminal
- `fzf` + `ripgrep` + `fd` for search; `bat` + `eza` for file viewing
- `yazi` for terminal file management
- `tmux` for terminal multiplexing
- `zoxide` for smart directory navigation
- `OrbStack` for containers (not Docker Desktop)
- `Raycast` as app launcher (replacing Spotlight)
- `opencode` — AI coding tool (terminal-based)

**Version Management**:
- No asdf/mise/nvm/fnm detected — Node, Go, Java managed directly via Homebrew
- Python environments via Conda (conda-forge priority, auto_activate: false)
- Rust via rustup

# Code Style

**Lua** (from `.stylua.toml`):
- Indent: 2 spaces
- Line width: 120
- Quote style: auto-prefer double
- Line endings: Unix
- Call parentheses: None
- Collapse simple statements: Always

**General preferences** (inferred from configs):
- Spaces over tabs (Lua 2-space, Yazi preview tab_size 2)
- Dark theme preference (`vim.opt.background = "dark"`, all tools use dark themes)
- Vi/Vim keybindings everywhere (tmux vi mode, btop vim keys, IdeaVim)
- Leader key: Space (both Neovim and IdeaVim)
- Nerd Font icons enabled throughout

**VSCode** (from Brewfile extensions):
- Formatter: Prettier (`esbenp.prettier-vscode`)
- Theme: One Dark Pro (`zhuangtongfa.material-theme`)

# Workflow

**Git** (from `git/config`, lazygit config):
- Diff viewer: `delta` with side-by-side, line numbers, mellow-barbet theme, Catppuccin Mocha syntax
- Merge conflict style: zdiff3
- Git LFS enabled
- Primary Git TUI: `lazygit` (abbreviation `lg`)
- No custom git aliases detected — relies on lazygit for complex operations

**Update routine** (from `fish/functions/u.fish`):
- Single `u` command updates everything: Homebrew, Neovim plugins, Go binaries, Conda, Rust, npm, pnpm, Bun, uv tools, Fisher, TPM, Yazi plugins, Mac App Store, Mole cleanup
- Auto-dumps Brewfile after Homebrew update (`brew bundle dump --force`)
- Blocks Chrome AI model downloads via `GenAILocalFoundationalModelSettings` enterprise policy (set once, persists across Chrome updates)

**Dotfiles management** (from `scripts/`):
- Symlink-based: all configs live in `~/dotfiles/`, symlinked to `~/.config/`
- `setup.sh` for fresh machine bootstrap (SSH + Homebrew + clone + restore)
- `restore.sh` for config restoration (symlinks + brew bundle + TPM + shell switch)
- Privacy scripts for macOS hardening

# Environment

- **OS**: macOS (Apple Silicon — `/opt/homebrew`)
- **Shell**: Fish (default shell, set via `chsh`)
- **Prompt**: Starship (text-only symbols, no Nerd Font icons in prompt)
- **Terminal**: Ghostty (MesloLGS Nerd Font Mono 14pt + Sarasa Mono SC, Mellow theme, custom cursor shaders); Warp also installed as secondary terminal
- **Multiplexer**: tmux (prefix `Ctrl-a`, Catppuccin Mocha, status bar top, vi copy mode)
- **Window Manager**: AeroSpace (tiling, `Cmd+hjkl` focus, `Ctrl+Alt+Shift+N` workspaces)
- **Keyboard**: Karabiner-Elements + Goku (EDN config)
- **Fonts**: MesloLGS Nerd Font Mono, Sarasa Mono SC, Fira Code NF, JetBrains Mono NF, LXGW WenKai, Geist, Geist Mono

# Preferences

**Theme philosophy** (from all configs):
- Unified dark theme: Rose Pine (Neovim, Fish, Lazygit) + Catppuccin Mocha (tmux, bat, delta syntax, Yazi) + Mellow (Ghostty, delta feature)
- Consistent Nerd Font icons across all tools

**Navigation patterns** (from abbreviations, keybindings):
- `v` = nvim, `lg` = lazygit, `y` = yazi (with cwd sync)
- `Ctrl+T` = fzf directory, `Ctrl+R` = fzf history, `Ctrl+G` = ripgrep search
- `el` = detailed file list (eza), `et` = tree view
- `cd` replaced by zoxide (`cd` command overridden via `zoxide init --cmd cd`)

**Operational habits** (from `u` function, abbreviations):
- Single-command mass update philosophy (`u` updates everything)
- Homebrew: no auto-update, no analytics, parallel builds = CPU count
- Conda: lazy-loaded (only initialized on first `conda` call)
- Aggressive cleanup: `brew cleanup --prune=all`, `conda clean --all`, `pnpm store prune`, `cargo cache --autoclean`

**macOS-specific** (from Brewfile, aerospace config):
- Tiling window management (AeroSpace) with floating exceptions for chat apps (QQ, WeChat), utilities (Finder, Keka, Easydict)
- `.hushlogin` — no login banner
- Privacy-conscious: multiple privacy/security hardening scripts

# Instructions for Claude

**Language**:
- Respond in Chinese when I write in Chinese; respond in English when I write in English
- Code comments, variable names, commit messages, and technical terms should remain in English

**Code style**:
- Use spaces for indentation (2 spaces for Lua/JS/TS/YAML/TOML, 4 spaces for Python/Go/Rust)
- Prefer double quotes unless the language convention differs
- Unix line endings (LF)
- Do not add trailing comments or docstrings unless asked
- Do not change existing code style in files you edit — match the surrounding code

**Behavior**:
- Be concise and direct — no filler, no preamble, no summarizing what was just done
- When suggesting shell commands, use Fish syntax (not bash/zsh)
- When suggesting editor operations, assume Neovim (not VS Code)
- Prefer terminal-native tools (ripgrep over GUI search, lazygit over GitHub UI)
- When creating config files, follow XDG conventions (`~/.config/`)

**Do NOT**:
- Add unnecessary error handling or validation for internal code
- Add type annotations or docstrings unless explicitly asked
- Suggest GUI solutions when a CLI alternative exists
- Use `sudo` without explaining why it's needed
- Create README or documentation files unless asked
- Add emojis to code or responses

**Uncertainty**:
- If unsure about a technical detail, say so directly rather than guessing
- When multiple approaches exist, briefly list trade-offs and let me choose
- If a task requires destructive operations (rm -rf, force push, etc.), always confirm first
