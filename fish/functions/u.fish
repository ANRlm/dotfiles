function u --description "Update everything"
    # ── helpers
    function _section
        set_color --bold cyan
        echo ""
        echo "══ $argv ══"
        set_color normal
    end

    function _ok
        set_color green
        echo "  ✓ $argv"
        set_color normal
    end

    # ── Homebrew
    _section Homebrew
    brew update
    brew upgrade
    brew autoremove
    brew cleanup --prune=all
    brew bundle dump --force --file ~/dotfiles/Brewfile
    _ok "Homebrew done"

    # ── Google Chrome — block AI model download via enterprise policy
    _section Chrome
    if test -d "/Applications/Google Chrome.app"
        set _pref ~/Library/Preferences/com.google.Chrome
        set _cur (defaults read $_pref GenAILocalFoundationalModelSettings 2>/dev/null)
        if test "$_cur" != 1
            defaults write $_pref GenAILocalFoundationalModelSettings -int 1
            _ok "Chrome AI model policy set"
        else
            _ok "Chrome AI model policy already set"
        end
    end

    # ── Rust
    _section Rust
    rustup self update
    rustup update
    cargo install-update -a
    cargo cache --autoclean
    _ok "Rust updated"

    # ── Go
    _section Go
    set _gobin (go env GOPATH)/bin
    if test -n "$(ls -A $_gobin 2>/dev/null)"
        for _bin in $_gobin/*
            set _pkg (go version -m $_bin 2>/dev/null | awk '$1=="path"{print $2; exit}')
            if test -n "$_pkg"
                go install "$_pkg@latest" 2>/dev/null
            end
        end
        _ok "Go binaries updated"
    else
        _ok "Go binaries (none installed)"
    end

    # ── Conda
    _section Conda
    conda update conda -y
    conda update --all -y
    conda clean --all -y
    _ok "Conda updated"

    # ── Node
    _section Node
    npm update -g
    _ok "npm updated"
    pnpm update -g
    pnpm store prune
    _ok "pnpm updated"

    # ── Bun
    _section Bun
    bun upgrade
    bun update -g opencode-ai
    cd ~/.config/opencode && bun update oh-my-openagent && cd -
    _ok "Bun updated"

    # ── Python (uv)
    _section "Python / uv"
    uv tool upgrade --all
    _ok "uv tools upgraded"

    # ── Fish / Fisher
    _section "Fish / Fisher"
    fisher update
    _ok "Fisher plugins updated"

    # ── Tmux / TPM
    _section "Tmux / TPM"
    ~/.config/tmux/plugins/tpm/bin/update_plugins all
    _ok "TPM plugins updated"

    # ── Neovim / AstroNvim
    _section "Neovim / AstroNvim"
    nvim --headless "+Lazy! sync" +qa 2>/dev/null
    _ok "Plugins synced"
    nvim --headless -c MasonUpdate -c qa 2>/dev/null
    _ok "Mason packages updated"

    # ── Yazi
    _section Yazi
    ya pkg upgrade
    _ok "Yazi plugins updated"

    # ── Mac App Store
    _section "Mac App Store"
    mas upgrade
    _ok "MAS updated"

    # ── Mole
    _section Mole
    printf '\n' | mo clean
    mo purge
    _ok "Mole cleaned"

    # ── App caches
    _section "App Caches"
    rm -rf ~/Library/Application\ Support/CleanShot/media
    _ok "CleanShot media cleared"

    # ── Done
    echo ""
    set_color --bold green
    echo "✓ All updated"
    set_color normal

    functions --erase _section _ok
end
