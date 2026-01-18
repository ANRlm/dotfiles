#!/bin/bash

echo "Installing packages for Arch Linux..."

sudo pacman -Syyu

sudo pacman -S --needed \
    bat \
    btop \
    lazygit \
    eza \
    yazi \
    helix \
    neovim \
    fish \
    tmux \
    zsh \
    starship \
    git \
    fzf \
    ripgrep \
    fd

if ! command -v paru &> /dev/null; then
    echo "Installing paru..."
    sudo pacman -S --needed base-devel git
    cd /tmp
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si
    cd ~
fi

echo "Package installation completed!"

echo "Setting fish as default shell..."
if command -v fish &> /dev/null; then
    if ! grep -q "$(which fish)" /etc/shells; then
        echo "Adding fish to /etc/shells..."
        which fish | sudo tee -a /etc/shells
    fi
    
    chsh -s $(which fish)
    echo "Default shell changed to fish. Please log out and log back in for changes to take effect."
else
    echo "Fish installation failed, skipping shell change."
fi

echo "Setup completed!"
