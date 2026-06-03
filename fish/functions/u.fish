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

    # ── Conda
    _section Conda
    _run "Conda updated" fish -c "conda update conda -y; and conda update --all -y; and conda clean --all -y"

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
    _run "Plugins synced" bash -lc "nvim --headless '+Lazy! sync' +qa"
    _run "Mason packages updated" bash -lc "nvim --headless -c MasonUpdate -c qa"

    # ── Yazi
    _section Yazi
    _run "Yazi plugins updated" ya pkg upgrade

    # ── Mac App Store
    _section "Mac App Store"
    _run "MAS updated" mas upgrade

    # ── Mole
    _section Mole
    _run "Mole cleaned" bash -lc "printf '\\n' | mo clean"

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
