# Context

- OS: macOS (Apple Silicon) + AeroSpace (window manager)
- Shell: Fish + Starship; Terminal: Ghostty; Multiplexer: tmux
- Primary editor: Neovim (AstroNvim); Secondary: JetBrains IDEs
- Core CLI tools: eza (ls), bat (cat), fd (find), btop
- Package managers: pnpm (primary), bun (secondary), Homebrew (system)
- Python env: Conda (Miniforge)
- Containers: OrbStack; Git TUI: lazygit; File manager: yazi

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
