#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'

OS="$(uname -s)"
echo "Detected OS: $OS"

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"

mkdir -p "$CONFIG_DIR"

# Tmux restore
mkdir -p "$CONFIG_DIR/tmux"
mkdir -p "$CONFIG_DIR/tmux/plugins/catppuccin"
if [ ! -d "$DOTFILES_DIR/oh-my-tmux" ]; then
  git clone https://github.com/gpakosz/.tmux.git "$DOTFILES_DIR/oh-my-tmux"
fi
if [ ! -d "$CONFIG_DIR/tmux/plugins/catppuccin/tmux" ]; then
  git clone -b v2.1.3 https://github.com/catppuccin/tmux.git "$CONFIG_DIR/tmux/plugins/catppuccin/tmux"
fi
ln -sf "$DOTFILES_DIR/oh-my-tmux/.tmux.conf" "$CONFIG_DIR/tmux/tmux.conf"
ln -sf "$DOTFILES_DIR/tmux/tmux.conf.local" "$CONFIG_DIR/tmux/tmux.conf.local"

# Macos restore
if [[ "$OS" == "Darwin" ]]; then
    for dir in aerospace alacritty bat btop fastfetch fish ghostty git go-musicfox karabiner lazygit mole neovide nvim yazi; do
        rm -rf "$CONFIG_DIR/$dir"
        ln -s "$DOTFILES_DIR/$dir" "$CONFIG_DIR/$dir"
    done

    # Eza restore
    ln -sfn "$DOTFILES_DIR/eza" "$HOME/Library/Application Support/eza"

    # Disable Gatekeeper
    sudo spctl --master-disable || true

    # Homebrew restore
    brew bundle

# Linux restore
elif [[ "$OS" == "Linux" ]]; then
    for dir in bat btop lazygit eza yazi helix nvim fish git alacritty; do
        rm -rf "$CONFIG_DIR/$dir"
        ln -s "$DOTFILES_DIR/$dir" "$CONFIG_DIR/$dir"
    done
fi

# Zsh restore
ln -sf "$DOTFILES_DIR/zsh/.hushlogin" "$HOME/.hushlogin"
ln -sf "$DOTFILES_DIR/zsh/zprofile"   "$HOME/.zprofile"
ln -sf "$DOTFILES_DIR/zsh/zshrc"      "$HOME/.zshrc"
# Starship restore
ln -sf "$DOTFILES_DIR/starship/starship.toml" "$CONFIG_DIR/starship.toml"
# Conda restore
ln -sf "$DOTFILES_DIR/conda/.condarc" "$HOME/.condarc"
# Idea vim restore
ln -sf "$DOTFILES_DIR/idea/.ideavimrc" "$HOME/.ideavimrc"
# Git restore
ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

echo "Dotfiles restored successfully!"
