# dotfiles

macOS dotfiles managed via symlinks.

## Stack

| Category | Tools |
|----------|-------|
| Shell | Fish + Starship |
| Terminal | Ghostty + tmux |
| Editor | Neovim (AstroNvim) |
| Git | lazygit + delta |
| Files | yazi + eza + fd |
| Search | fzf + ripgrep |
| Window manager | AeroSpace |
| Packages | Homebrew + pnpm + bun + uv |

## Setup

Fresh machine:

```sh
bash scripts/setup.sh
```

Existing machine (restore symlinks + packages):

```sh
bash scripts/restore.sh
```

## Update

```fish
u
```

Runs a single command that updates Homebrew, Neovim plugins, language toolchains, shell plugins, and more.
