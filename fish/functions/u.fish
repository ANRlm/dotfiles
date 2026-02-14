function u --description "Update everything"
    # ── Sudo
    sudo -v
    fish -c 'while true; sudo -n -v 2>/dev/null; sleep 50; end' &
    set sudo_pid $last_pid
    # ── Homebrew
    brew update
    and brew upgrade
    and brew upgrade --cask --greedy
    brew autoremove
    and brew cleanup --prune=all
    brew bundle dump --force --file ~/dotfiles/Brewfile
    # ── Neovim
    nvim --headless "+AstroUpdate"      +qa
    nvim --headless "+Lazy! sync"       +qa
    nvim --headless "+MasonToolsUpdate" +qa
    nvim --headless "+TSUpdateSync"     +qa
    # ── Conda
    conda update conda -y
    and conda update --all -y
    and conda clean --all -y
    # ── Rust
    rustup update
    and cargo install-update -a
    cargo cache --autoclean
    and cargo cache --remove-dir all
    # ── Node
    npm update -g
    and npm cache clean --force
    pnpm update -g
    and pnpm store prune
    # ── Python
    uv tool upgrade --all
    # ── Shell
    fisher update
    ~/.config/tmux/plugins/tpm/bin/update_plugins all
    # ── Tools
    ya pkg upgrade
    # ── macOS
    mas update
    printf '\n' | mo clean
    and mo purge
    # ── Rime
    printf '\n' | bash ~/dotfiles/scripts/rime-wanxiang-update-macos.sh \
        --schema base --fuzhu base --dict --gram
    # ── Kill sudo 
    kill $sudo_pid 2>/dev/null
end
