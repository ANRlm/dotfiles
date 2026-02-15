function u --description "Update everything"
    # ── Sudo keepalive
    sudo -v
    fish -c 'while true; sudo -n true 2>/dev/null; sleep 55; end' &
    set sudo_pid $last_pid

    # ── Homebrew
    brew update
    brew upgrade
    brew upgrade --cask --greedy
    brew autoremove
    brew cleanup --prune=all
    brew bundle dump --force --file ~/dotfiles/Brewfile

    # ── Neovim
    if command -q nvim
        nvim --headless "+AstroUpdate"      +qa
        nvim --headless "+Lazy! sync"       +qa
        nvim --headless "+MasonToolsUpdate" +qa
        nvim --headless "+TSUpdateSync"     +qa
    end

    # ── Conda
    if command -q conda
        conda update conda -y
        conda update --all -y
        conda clean --all -y
    end

    # ── Rust
    if command -q rustup
        rustup update
        cargo install-update -a
        cargo cache --autoclean
        cargo cache --remove-dir all
    end

    # ── Node
    if command -q npm
        npm update -g
        npm cache clean --force
    end
    if command -q pnpm
        pnpm update -g
        pnpm store prune
    end

    # ── Python
    if command -q uv
        uv tool upgrade --all
    end

    # ── Shell
    if command -q fisher
        fisher update
    end
    ~/.config/tmux/plugins/tpm/bin/update_plugins all

    # ── Tools
    if command -q ya
        ya pkg upgrade
    end

    # ── macOS
    if command -q mas
        mas update
    end
    printf '\n' | mo clean
    mo purge

    # ── Rime
    if test -f ~/dotfiles/scripts/rime-wanxiang-update-macos.sh
        printf '\n' | bash ~/dotfiles/scripts/rime-wanxiang-update-macos.sh \
            --schema base --fuzhu base --dict --gram
    end

    # ── Kill sudo keepalive
    kill $sudo_pid 2>/dev/null; or true

    echo "✓ All updated"
end
