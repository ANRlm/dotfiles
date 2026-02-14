#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'

# ──────────────────────────────────────────────────
# Colors & logging
# ──────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
section() { echo -e "\n${YELLOW}── $* ──${NC}"; }
# ──────────────────────────────────────────────────
# Paths
# ──────────────────────────────────────────────────
section "Preparation"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$HOME/.config"
OS="$(uname -s)"

info "Dotfiles: $DOTFILES_DIR"
info "Config:   $CONFIG_DIR"
info "OS:       $OS"

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

for dir in aerospace alacritty bat btop conda fish ghostty git go-musicfox ideavim lazygit mole neovide nvim starship tmux yazi; do
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
if [[ "$OS" == "Darwin" ]]; then
	section "Brew bundle"

	brew bundle --file="$DOTFILES_DIR/Brewfile"
fi
# ──────────────────────────────────────────────────
echo -e "\n${GREEN}Dotfiles restored successfully!${NC}"
