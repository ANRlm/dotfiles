# dotfiles

Personal macOS dotfiles for terminal, editor, shell, and development tooling.

## What's included

- Shell: `fish`, `starship`
- Editor: `nvim`, `ideavim`
- Terminal + multiplexer: `ghostty`, `tmux`
- Git tools: `git`, `lazygit`, `delta`
- File tools: `yazi`, `bat`, `btop`
- Automation scripts: `scripts/setup.sh`, `scripts/restore.sh`
- Package bootstrap: `Brewfile` (Homebrew, Casks, MAS, VS Code extensions, Cargo)

## Repository layout

Most top-level folders map to `~/.config/<name>` through symlinks created by the restore script.

```text
.
|- aerospace/
|- bat/
|- btop/
|- fish/
|- ghostty/
|- git/
|- karabiner/
|- nvim/
|- starship/
|- tmux/
|- yazi/
`- scripts/
```

## Quick start

### 1) First-time machine bootstrap

Use this if GitHub SSH or Homebrew are not fully set up yet:

```bash
bash scripts/setup.sh
```

This script will:

1. Check/configure GitHub SSH
2. Install Homebrew (if missing)
3. Ensure Git is installed
4. Clone this repository to `~/dotfiles` (if needed)
5. Run restore

### 2) Restore on an existing clone

If you already cloned this repo:

```bash
bash scripts/restore.sh
```

This script will:

1. Symlink config directories into `~/.config`
2. Apply Karabiner links
3. Run `brew bundle --file=./Brewfile`
4. Install TPM and tmux plugins
5. Set default shell to fish (when available)

## Notes

- `restore.sh` replaces existing target config paths before linking. Back up local config files you want to keep.
- `Brewfile` includes a large desktop app/tooling set; edit it before restore if you want a lighter install.
- Fish config sets aliases/abbreviations and startup integrations (zoxide, starship, OrbStack).

## Maintenance

- Update brew bundle entries by editing `Brewfile`.
- Re-run restore after changing configs:

```bash
bash scripts/restore.sh
```
