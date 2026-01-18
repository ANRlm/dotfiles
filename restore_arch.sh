#!/bin/bash

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
    sudo pacman -S --needed --noconfirm base-devel git
    cd /tmp
    git clone https://aur.archlinux.org/paru.git
    cd paru
    echo -e "1\ny" | makepkg -si
    cd ~
    rm -rf /tmp/paru
fi

sudo passwd $USER

if command -v fish &> /dev/null; then
    if ! grep -q "$(which fish)" /etc/shells; then
        which fish | sudo tee -a /etc/shells
    fi
    
    sudo chsh -s $(which fish) $USER
    echo "Default shell changed to fish. Please log out and log back in for changes to take effect."
else
    echo "Fish installation failed, skipping shell change."
fi

echo ""
echo "Setup completed!"
