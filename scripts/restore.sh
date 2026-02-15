#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'

# ──────────────────────────────────────────────────
# Colors & logging
# ──────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
section() { echo -e "\n${YELLOW}── $* ──${NC}"; }
die() {
	echo -e "${RED}[✗]${NC} $*" >&2
	exit 1
}

trap 'die "Error on line $LINENO"' ERR
# ──────────────────────────────────────────────────
# Preparation
# ──────────────────────────────────────────────────
section "Preparation"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$HOME/.config"

info "Dotfiles: $DOTFILES_DIR"
info "Config:   $CONFIG_DIR"

mkdir -p "$CONFIG_DIR"
touch "$HOME/.hushlogin"
# ──────────────────────────────────────────────────
# Functions
# ──────────────────────────────────────────────────
link_dir() {
	local src="$1" dst="$2"
	rm -rf "$dst"
	ln -s "$src" "$dst"
	info "Linked dir  $dst → $src"
}

link_file() {
	local src="$1" dst="$2"
	mkdir -p "$(dirname "$dst")"
	ln -sf "$src" "$dst"
	info "Linked file $dst → $src"
}
# ──────────────────────────────────────────────────
# Config dirs
# ──────────────────────────────────────────────────
section "Config dirs"

for dir in aerospace alacritty bat btop conda fish ghostty git go-musicfox ideavim lazygit mole neovide npm nvim starship tmux yazi; do
	link_dir "$DOTFILES_DIR/$dir" "$CONFIG_DIR/$dir"
done
# ──────────────────────────────────────────────────
# Karabiner
# ──────────────────────────────────────────────────
section "Karabiner"

link_dir "$DOTFILES_DIR/karabiner/config" "$CONFIG_DIR/karabiner"
link_file "$DOTFILES_DIR/karabiner/edn/karabiner.edn" "$CONFIG_DIR/karabiner.edn"
# ──────────────────────────────────────────────────
# Brew bundle
# ──────────────────────────────────────────────────
section "Brew bundle"

brew bundle --file="$DOTFILES_DIR/Brewfile"
# ──────────────────────────────────────────────────
# TPM
# ──────────────────────────────────────────────────
section "TPM"

TPM_DIR="$HOME/.config/tmux/plugins/tpm"

if [[ -d "$TPM_DIR" ]]; then
	info "TPM already installed, skipping"
else
	git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
	info "TPM installed"
fi

info "Installing tmux plugins..."
bash "$TPM_DIR/bin/install_plugins"
info "Tmux plugins installed"
# ──────────────────────────────────────────────────
# Default shell → fish
# ──────────────────────────────────────────────────
section "Default shell"

FISH_PATH="$(command -v fish 2>/dev/null || echo "")"
if [[ -z "$FISH_PATH" ]]; then
	warn "fish not found in PATH, skipping default shell setup"
else
	if ! grep -qxF "$FISH_PATH" /etc/shells; then
		echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
		info "Added $FISH_PATH to /etc/shells"
	fi
	if [[ "$SHELL" == "$FISH_PATH" ]]; then
		info "fish is already the default shell"
	else
		chsh -s "$FISH_PATH"
		info "Default shell set to $FISH_PATH"
	fi
fi
# ──────────────────────────────────────────────────
# Cargo packages
# ──────────────────────────────────────────────────
section "Cargo packages"

if ! command -v cargo &>/dev/null; then
	warn "cargo not found in PATH, skipping cargo installs"
else
	for pkg in cargo-cache cargo-update; do
		if cargo install --list | grep -q "^${pkg} "; then
			info "$pkg is already installed, skipping"
		else
			cargo install "$pkg"
			info "Installed $pkg"
		fi
	done
fi

echo -e "\n${GREEN}Dotfiles restored successfully!${NC}"
