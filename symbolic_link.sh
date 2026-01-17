#!/bin/bash

mkdir -p ~/.config

remove_if_exists() {
    if [ -e "$1" ] || [ -L "$1" ]; then
        rm -rf "$1"
    fi
}

ln -sf ~/dotfiles/zsh/.hushlogin ~/.hushlogin
ln -sf ~/dotfiles/zsh/zprofile ~/.zprofile
ln -sf ~/dotfiles/zsh/zshrc ~/.zshrc

for dir in aerospace bat btop fish ghostty nvim yazi; do
    remove_if_exists ~/.config/$dir
    ln -sf ~/dotfiles/$dir ~/.config/$dir
done

ln -sf ~/dotfiles/starship/starship.toml ~/.config/starship.toml
ln -sf ~/dotfiles/conda/.condarc ~/.condarc
ln -sf ~/dotfiles/idea/.ideavimrc ~/.ideavimrc

mkdir -p ~/.config/git
ln -sf ~/dotfiles/git/themes.gitconfig ~/.config/git/themes.gitconfig
ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig

echo "Dotfiles restored successfully"
