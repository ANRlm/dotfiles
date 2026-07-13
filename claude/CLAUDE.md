# Claude Code Global Instructions

User-scoped defaults for Claude Code. Claude loads user, project, and local
instructions additively, with project and local files read later. Avoid
conflicting rules and follow explicit project conventions.

## Scope

- The source file is `~/dotfiles/claude/CLAUDE.md` and is symlinked to `~/.claude/CLAUDE.md`.
- Apply these defaults across all projects.
- Project instructions may live in `./CLAUDE.md` or `./.claude/CLAUDE.md`.
- Personal project instructions may live in `./CLAUDE.local.md`.

## Communication

- Respond in Chinese when the user writes in Chinese and in English when the
  user writes in English.
- Keep generated code, comments, identifiers, and commit subjects in English
  unless a project requires otherwise.

## Environment

- OS: macOS on Apple Silicon.
- Shell: Fish with Starship.
- Terminal: Ghostty with tmux.
- Editor: Neovim with AstroNvim v6.
- Package managers: Homebrew for system tools, pnpm as the primary JavaScript
  package manager, and bun as a secondary runtime.
- Python: Conda/Miniforge and uv.
- CLI toolkit: `rg`, `fd`, `bat`, `eza`, `btop`, `lazygit`, and `yazi`.

## Code Style

Follow project-local instructions, formatters, and surrounding code first.
Use these preferences only as fallbacks.

| Language | Indentation | Quotes | Formatter or notes |
| --- | --- | --- | --- |
| Lua | 2 spaces | Double | StyLua, 120 columns, idiomatic call syntax |
| JavaScript/TypeScript | 2 spaces | Double | Prettier |
| YAML/TOML | 2 spaces | Project style | Follow surrounding key order |
| Python | 4 spaces | Double | Do not add type annotations unless requested |
| Go | Tabs | Double | `gofmt`; avoid unnecessary comments |
| Rust | 4 spaces | Double | `rustfmt` |

- Use LF line endings.
- Add comments only when they explain non-obvious behavior.

## Workflow

- Inspect repository instructions and the current working tree before editing.
- Prefer terminal-native tools and existing project commands.
- Prefer `rg`, `fd`, `bat`, and `eza` over slower or less readable alternatives.
- Write shell examples in Fish syntax unless the target is explicitly a Bash script.
- Assume Neovim for editor-oriented instructions.
- Follow XDG conventions for configuration paths.
- Use existing project patterns before introducing new abstractions.
- Run relevant formatters, linters, and tests after changes; report any checks
  that cannot be run.

## Git and Safety

- Write concise, imperative, English commit subjects.
- Preserve unrelated user changes.
- Confirm before destructive operations such as `rm -rf`, force pushes, or
  history rewrites.
- Do not use `sudo` without explaining why it is required.
- Prefer `lazygit` for interactive Git workflows and `gh` for GitHub operations.
- Do not create README or other documentation files unless requested.
- Do not add broad validation or defensive error handling to internal code
  unless requested.
- Never expose credentials, tokens, private keys, or other secrets.

## Instruction Management

- Edit `~/dotfiles/claude/CLAUDE.md` rather than the `~/.claude/CLAUDE.md` symlink.
- Use `/memory` to inspect loaded instructions and auto memory, or ask Claude
  directly to update an instruction file.
- Keep this file concise, specific, internally consistent, and below 200 lines.
- Put project-specific facts in a project `CLAUDE.md` or `.claude/rules/`
  instead of this global file.
