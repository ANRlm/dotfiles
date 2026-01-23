#!/bin/bash

OS="$(uname -s)"
DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"

echo "Detected OS: $OS"
echo "Starting dotfiles restoration from $DOTFILES_DIR"

mkdir -p "$CONFIG_DIR"

if [[ "$OS" == "Darwin" ]]; then
    echo "Configuring for macOS..."
    MACOS_APP_SUPPORT="$HOME/Library/Application Support"
    mkdir -p "$MACOS_APP_SUPPORT/lazygit"
    mkdir -p "$MACOS_APP_SUPPORT/eza"

    for dir in aerospace bat btop fish ghostty nvim yazi tmux karabiner neovide mole git; do
        ln -sfn "$DOTFILES_DIR/$dir" "$CONFIG_DIR/$dir"
    done

    ln -sfn "$DOTFILES_DIR/eza" "$MACOS_APP_SUPPORT/eza"
    ln -sf "$DOTFILES_DIR/lazygit/config.yml" "$MACOS_APP_SUPPORT/lazygit/config.yml"

    echo "Restoring Homebrew packages..."
    brew bundle

elif [[ "$OS" == "Linux" ]]; then
    echo "Configuring for Linux..."

    for dir in bat btop lazygit eza yazi helix nvim fish tmux git; do
        ln -sfn "$DOTFILES_DIR/$dir" "$CONFIG_DIR/$dir"
    done

else
    echo "Unsupported operating system: $OS"
    exit 1
fi

ln -sf "$DOTFILES_DIR/zsh/.hushlogin" "$HOME/.hushlogin"
ln -sf "$DOTFILES_DIR/zsh/zprofile"   "$HOME/.zprofile"
ln -sf "$DOTFILES_DIR/zsh/zshrc"      "$HOME/.zshrc"
ln -sf "$DOTFILES_DIR/starship/starship.toml" "$CONFIG_DIR/starship.toml"
ln -sf "$DOTFILES_DIR/conda/.condarc"         "$HOME/.condarc"
ln -sf "$DOTFILES_DIR/idea/.ideavimrc"        "$HOME/.ideavimrc"
ln -sf "$DOTFILES_DIR/git/.gitconfig"       "$HOME/.gitconfig"

echo "Dotfiles restored successfully!"
