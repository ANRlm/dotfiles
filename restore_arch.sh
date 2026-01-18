#!/bin/bash

echo "Installing packages for Arch Linux..."

sudo pacman -Syyu --noconfirm

sudo pacman -S --needed --noconfirm \
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
    sudo pacman -S --needed --noconfirm base-devel git
    
    cd /tmp
    git clone https://aur.archlinux.org/paru.git
    cd paru
    
    echo -e "1\ny" | makepkg -si
    
    cd ~
    rm -rf /tmp/paru
fi

echo "Package installation completed!"

echo ""
echo "=================================="
echo "Please set/update your password before changing default shell:"
echo "=================================="
passwd

echo ""
echo "Setting fish as default shell..."
if command -v fish &> /dev/null; then
    # Add fish to /etc/shells if not already present
    if ! grep -q "$(which fish)" /etc/shells; then
        echo "Adding fish to /etc/shells..."
        which fish | sudo tee -a /etc/shells
    fi
    
    chsh -s $(which fish)
    echo "Default shell changed to fish. Please log out and log back in for changes to take effect."
else
    echo "Fish installation failed, skipping shell change."
fi

echo ""
echo "Setup completed!"
