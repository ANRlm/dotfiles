function u --description "Update everything"
    set -g __u_failures 0

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

    function _fail
        set_color red
        echo "  ✗ $argv"
        set_color normal
    end

    function _run --argument-names label
        set -e argv[1]
        $argv
        set -l status_code $status
        if test $status_code -eq 0
            _ok "$label"
        else
            _fail "$label (exit $status_code)"
            set -g __u_failures (math $__u_failures + 1)
        end
        return $status_code
    end

    # ── Homebrew
    _section Homebrew
    _run "Homebrew done" bash -lc "brew update && brew upgrade && brew autoremove && brew cleanup --prune=all && brew bundle dump --force --file ~/dotfiles/Brewfile"

    # ── Google Chrome — block AI model download via enterprise policy
    _section Chrome
    if test -d "/Applications/Google Chrome.app"
        set _pref ~/Library/Preferences/com.google.Chrome
        set _cur (defaults read $_pref GenAILocalFoundationalModelSettings 2>/dev/null)
        if test "$_cur" != 1
            _run "Chrome AI model policy set" defaults write $_pref GenAILocalFoundationalModelSettings -int 1
        else
            _ok "Chrome AI model policy already set"
        end
    else
        _ok "Chrome not installed"
    end

    # ── Rust
    _section Rust
    _run "Rust updated" bash -lc "rustup update && cargo install-update -a && cargo cache --autoclean"

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
        if test $status -eq 0
            _ok "Go binaries updated"
        else
            _fail "Go binaries updated"
            set -g __u_failures (math $__u_failures + 1)
        end
    else
        _ok "Go binaries (none installed)"
    end

    # ── Conda
    _section Conda
    _run "Conda updated" bash -lc "conda update conda -y && conda update --all -y && conda clean --all -y"

    # ── Node
    _section Node
    _run "npm updated" npm update -g
    _run "pnpm updated" bash -lc "pnpm update -g && pnpm store prune"

    # ── Python (uv)
    _section "Python / uv"
    _run "uv tools upgraded" uv tool upgrade --all

    # ── Fish / Fisher
    _section "Fish / Fisher"
    _run "Fisher plugins updated" fisher update

    # ── Tmux / TPM
    _section "Tmux / TPM"
    _run "TPM plugins updated" ~/.config/tmux/plugins/tpm/bin/update_plugins all

    # ── Neovim / AstroNvim
    _section "Neovim / AstroNvim"
    _run "Plugins synced" bash -lc "nvim --headless '+Lazy! sync' +qa 2>/dev/null"
    _run "Mason packages updated" bash -lc "nvim --headless -c MasonUpdate -c qa 2>/dev/null"

    # ── Yazi
    _section Yazi
    _run "Yazi plugins updated" ya pkg upgrade

    # ── Mac App Store
    _section "Mac App Store"
    _run "MAS updated" mas upgrade

    # ── Mole
    _section Mole
    _run "Mole cleaned" bash -lc "printf '\\n' | mo clean"

    # ── App caches
    _section "App Caches"
    _run "CleanShot media cleared" rm -rf ~/Library/Application\ Support/CleanShot/media

    # ── Done
    echo ""
    if test $__u_failures -eq 0
        set_color --bold green
        echo "✓ All updated"
    else
        set_color --bold red
        echo "✗ Update finished with $__u_failures failure(s)"
    end
    set_color normal

    functions --erase _section _ok _fail _run
    set -e __u_failures
end
