function u --description "Update everything"
    # ── helpers ──────────────────────────────────────────────────────────────
    function _section
        set_color --bold cyan
        echo ""
        echo "══ $argv ══"
        set_color normal
    end

    function _ok
        set_color green; echo "  ✓ $argv"; set_color normal
    end

    function _skip
        set_color yellow; echo "  - $argv (not found, skipped)"; set_color normal
    end

    # ── Homebrew ──────────────────────────────────────────────────────────────
    _section "Homebrew"
    brew update
    brew upgrade
    brew upgrade --cask
    brew autoremove
    brew cleanup --prune=all
    brew bundle dump --force --file ~/dotfiles/Brewfile
    _ok "Homebrew done"

    # ── Google Chrome — block auto-update & AI model download ─────────────
    _section "Chrome (lock updater & AI models)"
    if test -d "/Applications/Google Chrome.app"
        for _dir in \
            "$HOME/Library/Application Support/Google/GoogleUpdater" \
            "$HOME/Library/Application Support/Google/Chrome/OptGuideOnDeviceModel" \
            "$HOME/Library/Application Support/Google/Chrome/optimization_guide_model_store"
            sudo rm -rf $_dir
            mkdir -p $_dir
            sudo chown root $_dir
            sudo chmod 000 $_dir
        end
        _ok "Chrome locked"
    else
        _skip "Google Chrome"
    end

    # ── Neovim (AstroNvim) ────────────────────────────────────────────────────
    _section "Neovim"
    if command -q nvim
        # sync plugin manager first, then update everything else
        nvim --headless "+Lazy! sync"       +qa
        nvim --headless "+AstroUpdate"      +qa
        nvim --headless "+MasonToolsUpdate" +qa
        nvim --headless "+TSUpdateSync"     +qa
        _ok "Neovim plugins updated"
    else
        _skip "nvim"
    end

    # ── Go toolchain ──────────────────────────────────────────────────────────
    _section "Go"
    if command -q go
        # update all non-stdlib binaries installed via `go install`
        set _gobin (go env GOPATH)/bin
        if test -d $_gobin
            for _bin in $_gobin/*
                set _pkg (go version -m $_bin 2>/dev/null | awk '$1=="path"{print $2; exit}')
                if test -n "$_pkg"
                    go install "$_pkg@latest" 2>/dev/null
                end
            end
            _ok "Go binaries updated"
        end
    else
        _skip "go"
    end

    # ── Conda / Miniforge ────────────────────────────────────────────────────
    _section "Conda"
    if command -q conda
        conda update conda -y
        conda update --all -y
        conda clean --all -y
        _ok "Conda updated"
    else
        _skip "conda"
    end

    # ── Rust ──────────────────────────────────────────────────────────────────
    _section "Rust"
    if command -q rustup
        rustup update
        if command -q cargo
            # cargo-update: `cargo install cargo-update` to enable
            if test -x ~/.cargo/bin/cargo-install-update
                cargo install-update -a
            else
                _skip "cargo-update (run: cargo install cargo-update)"
            end
            if test -x ~/.cargo/bin/cargo-cache
                cargo cache --autoclean
            else
                _skip "cargo-cache (run: cargo install cargo-cache)"
            end
        end
        _ok "Rust updated"
    else
        _skip "rustup"
    end

    # ── Node ──────────────────────────────────────────────────────────────────
    _section "Node"
    if command -q npm
        npm update -g
        npm cache clean --force
        _ok "npm updated"
    else
        _skip "npm"
    end
    if command -q pnpm
        pnpm update -g
        pnpm store prune
        _ok "pnpm updated"
    else
        _skip "pnpm"
    end

    # ── Python (uv) ───────────────────────────────────────────────────────────
    _section "Python / uv"
    if command -q uv
        uv tool upgrade --all
        _ok "uv tools upgraded"
    else
        _skip "uv"
    end

    # ── Shell ─────────────────────────────────────────────────────────────────
    _section "Fish / Fisher"
    if functions -q fisher
        fisher update
        _ok "Fisher plugins updated"
    else
        _skip "fisher"
    end

    _section "Tmux / TPM"
    set _tpm "$HOME/.config/tmux/plugins/tpm/bin/update_plugins"
    if test -x $_tpm
        $_tpm all
        _ok "TPM plugins updated"
    else
        _skip "TPM (~/.config/tmux/plugins/tpm not found)"
    end

    # ── Tools ─────────────────────────────────────────────────────────────────
    _section "Yazi plugins"
    if command -q ya
        ya pkg upgrade
        _ok "Yazi plugins updated"
    else
        _skip "ya"
    end

    # ── macOS App Store ───────────────────────────────────────────────────────
    _section "Mac App Store"
    if command -q mas
        mas update
        _ok "MAS updated"
    else
        _skip "mas"
    end

    # ── Mole ──────────────────────────────────────────────────────────────────
    _section "Mole"
    if command -q mo
        printf '\n' | mo clean
        mo purge
        _ok "Mole cleaned"
    else
        _skip "mo (mole)"
    end

    # ── App caches ────────────────────────────────────────────────────────────
    _section "App Caches"
    rm -rf ~/Library/Application\ Support/CleanShot/media
    _ok "CleanShot media cleared"

    # ── Done ──────────────────────────────────────────────────────────────────
    echo ""
    set_color --bold green
    echo "✓ All updated"
    set_color normal

    functions --erase _section _ok _skip
end
