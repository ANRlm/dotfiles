#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'

# --------------------------------------------------
# colors
# --------------------------------------------------
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
section() { echo -e "\n${YELLOW}── $* ──${NC}"; }

# --------------------------------------------------
# dirs
# --------------------------------------------------
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"
OS="$(uname -s)"

info "Dotfiles: $DOTFILES_DIR"
info "Config:   $CONFIG_DIR"
info "OS:       $OS"

mkdir -p "$CONFIG_DIR"

# --------------------------------------------------
# tools function
# --------------------------------------------------

# 链接目录：先删旧链接再建新链接
link_dir() {
	local src="$1" dst="$2"
	rm -rf "$dst"
	ln -s "$src" "$dst"
	info "Linked dir  $dst → $src"
}

# 链接文件：-sf 直接覆盖
link_file() {
	local src="$1" dst="$2"
	mkdir -p "$(dirname "$dst")"
	ln -sf "$src" "$dst"
	info "Linked file $dst → $src"
}

# clone 仓库（已存在则跳过）
clone_if_missing() {
	local repo="$1" dst="$2" flags="${3:-}"
	if [ ! -d "$dst" ]; then
		# shellcheck disable=SC2086
		git clone $flags "$repo" "$dst"
		info "Cloned $repo"
	else
		warn "Already exists, skipping clone: $dst"
	fi
}

# --------------------------------------------------
# tmux
# --------------------------------------------------
section "tmux"

clone_if_missing \
	"https://github.com/gpakosz/.tmux.git" \
	"$DOTFILES_DIR/oh-my-tmux"

clone_if_missing \
	"https://github.com/catppuccin/tmux.git" \
	"$CONFIG_DIR/tmux/plugins/catppuccin/tmux" \
	"-b v2.1.3"

mkdir -p "$CONFIG_DIR/tmux/plugins/catppuccin"
link_file "$DOTFILES_DIR/oh-my-tmux/.tmux.conf" "$CONFIG_DIR/tmux/tmux.conf"
link_file "$DOTFILES_DIR/tmux/tmux.conf.local" "$CONFIG_DIR/tmux/tmux.conf.local"

# --------------------------------------------------
# Config dirs
# --------------------------------------------------
section "Config dirs"

for dir in aerospace alacritty bat btop eza fish ghostty git go-musicfox karabiner lazygit mole neovide nvim yazi; do
	link_dir "$DOTFILES_DIR/$dir" "$CONFIG_DIR/$dir"
done

# --------------------------------------------------
# Config files
# --------------------------------------------------
section "Config files"

touch "$HOME/.hushlogin"
info "Touched ~/.hushlogin"

link_file "$DOTFILES_DIR/starship/starship.toml" "$CONFIG_DIR/starship.toml"
link_file "$DOTFILES_DIR/conda/.condarc" "$HOME/.condarc"
link_file "$DOTFILES_DIR/idea/.ideavimrc" "$HOME/.ideavimrc"
link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/goku/karabiner.edn" "$CONFIG_DIR/karabiner.edn"

# --------------------------------------------------
# macOS
# --------------------------------------------------
if [[ "$OS" == "Darwin" ]]; then
	section "macOS"

	link_dir "$DOTFILES_DIR/eza" "$HOME/Library/Application Support/eza"

	brew bundle --file="$DOTFILES_DIR/Brewfile"
	info "Homebrew packages installed"
fi

# --------------------------------------------------
echo -e "\n${GREEN}Dotfiles restored successfully!${NC}"
