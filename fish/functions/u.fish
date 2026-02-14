function u --description "Update everything"
    brew update; and brew upgrade; and brew upgrade --cask --greedy
    brew autoremove; and brew cleanup --prune=all
    brew bundle dump --force --file ~/dotfiles/Brewfile
    nvim --headless "+Lazy! sync" +qa
    nvim --headless "+MasonToolsUpdate" +qa
    nvim --headless "+TSUpdateSync" +qa
    conda update conda -y; and conda update --all -y; and conda clean --all -y
    ya pkg upgrade
    fisher update
    uv tool upgrade --all
    npm update -g; and npm cache clean --force
    pnpm update -g; and pnpm store prune
    ~/.config/tmux/plugins/tpm/bin/update_plugins all
    mas update
    rustup update
    mo clean; and mo purge
end
