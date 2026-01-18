#!/bin/bash

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo "Starting dotfiles restoration from $DOTFILES_DIR"

mkdir -p "$CONFIG_DIR"
mkdir -p "$CONFIG_DIR/git"

for dir in bat btop lazygit eza yazi helix nvim; do
    ln -sfn "$DOTFILES_DIR/$dir" "$CONFIG_DIR/$dir"
done

ln -sf "$DOTFILES_DIR/zsh/.hushlogin" "$HOME/.hushlogin"
ln -sf "$DOTFILES_DIR/zsh/zprofile"   "$HOME/.zprofile"
ln -sf "$DOTFILES_DIR/zsh/zshrc"      "$HOME/.zshrc"

ln -sf "$DOTFILES_DIR/starship/starship.toml" "$CONFIG_DIR/starship.toml"
ln -sf "$DOTFILES_DIR/conda/.condarc"         "$HOME/.condarc"
ln -sf "$DOTFILES_DIR/idea/.ideavimrc"        "$HOME/.ideavimrc"

ln -sf "$DOTFILES_DIR/git/themes.gitconfig" "$CONFIG_DIR/git/themes.gitconfig"
ln -sf "$DOTFILES_DIR/git/.gitconfig"       "$HOME/.gitconfig"

echo "Dotfiles restored successfully!"
