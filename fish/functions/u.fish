function __u_section
    set_color --bold cyan
    echo ""
    echo "══ $argv ══"
    set_color normal
end

function __u_ok
    set_color green
    echo "  ✓ $argv"
    set_color normal
end

function __u_retry --argument-names max_attempts
    set -e argv[1]
    set -l attempt 1

    while true
        $argv
        set -l status_code $status
        if test $status_code -eq 0; or test $attempt -ge $max_attempts
            return $status_code
        end

        set_color yellow
        echo "  ↻ Retrying update ($attempt/$max_attempts)"
        set_color normal
        sleep 2
        set attempt (math $attempt + 1)
    end
end

function __u_run --no-scope-shadowing --argument-names label
    set -e argv[1]
    $argv
    set -l status_code $status
    if test $status_code -eq 0
        __u_ok "$label"
    else
        set_color red
        echo "  ✗ $label (exit $status_code)"
        set_color normal
        set __u_failures (math $__u_failures + 1)
    end
    return $status_code
end

function u --description "Update global tools, applications and plugins"
    if set -q argv[1]
        echo "Usage: u" >&2
        return 2
    end

    set -f __u_failures 0
    set -lx PATH /opt/homebrew/bin $PNPM_HOME/bin $PATH

    # ── Homebrew ──────────────────────────────────────────────────────

    __u_section Homebrew
    if __u_run "Homebrew metadata updated" brew update
        __u_run "Homebrew packages upgraded" brew upgrade --no-ask
    end
    __u_run "Homebrew dependencies cleaned" brew autoremove
    __u_run "Homebrew cache cleaned" brew cleanup --prune=all
    __u_run "Brewfile updated" brew bundle dump --force --file "$HOME/dotfiles/Brewfile" --no-vscode --no-describe

    # ── Node ──────────────────────────────────────────────────────────

    __u_section Node
    __u_run "npm updated" env PUPPETEER_SKIP_DOWNLOAD=true npm update -g
    __u_run "pnpm updated" pnpm --dir "$HOME" update -g
    __u_run "pnpm store pruned" pnpm --dir "$HOME" store prune

    # Skip bun when its global package manifest does not exist.
    set -l bun_home $BUN_INSTALL
    test -n "$bun_home"; or set bun_home $HOME/.bun
    if test -f $bun_home/install/global/package.json
        __u_run "bun updated" bun update -g
    else
        __u_ok "bun (no global packages)"
    end

    # ── Python (uv) ───────────────────────────────────────────────────

    __u_section "Python / uv"
    __u_run "uv tools upgraded" uv tool upgrade --all
    __u_run "uv cache pruned" uv cache prune

    # ── Mac App Store ─────────────────────────────────────────────────

    __u_section "Mac App Store"
    __u_run "MAS updated" mas update

    # ── Tmux / TPM ────────────────────────────────────────────────────

    __u_section "Tmux / TPM"
    # TPM's parallel updater can return success when a plugin fails.
    for plugin in (path filter -d ~/.config/tmux/plugins/*)
        test -e "$plugin/.git"; or continue
        set -l name (path basename "$plugin")
        set -lx GIT_TERMINAL_PROMPT 0
        __u_run "$name updated" git -C "$plugin" pull --ff-only
        and __u_run "$name submodules updated" git -C "$plugin" submodule update --init --recursive
    end

    # ── Yazi ──────────────────────────────────────────────────────────

    __u_section Yazi
    __u_run "Yazi plugins updated" __u_retry 3 ya pkg upgrade

    # ── Mole ──────────────────────────────────────────────────────────

    __u_section Mole
    __u_run "Mole cleaned" mo clean </dev/null

    # ── Done ──────────────────────────────────────────────────────────

    echo ""
    if test $__u_failures -eq 0
        set_color --bold green
        echo "✓ All updated"
    else
        set_color --bold red
        echo "✗ Update finished with $__u_failures failure(s)"
    end
    set_color normal

    test $__u_failures -eq 0
end
