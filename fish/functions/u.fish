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

function __u_fail
    set_color red
    echo "  ✗ $argv"
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
        __u_fail "$label (exit $status_code)"
        set __u_failures (math $__u_failures + 1)
    end
    return $status_code
end

function __u_update_plugins
    set -f __u_failures 0

    # ── Fish / Fisher
    __u_section "Fish / Fisher"
    __u_run "Fisher plugins updated" fisher update

    # ── Tmux / TPM
    __u_section "Tmux / TPM"
    __u_run "TPM plugins updated" ~/.config/tmux/plugins/tpm/bin/update_plugins all

    # ── Yazi
    __u_section Yazi
    __u_run "Yazi plugins updated" __u_retry 3 ya pkg upgrade

    echo ""
    set -l final_status 0
    if test $__u_failures -eq 0
        set_color --bold green
        echo "✓ Plugins updated"
    else
        set_color --bold red
        echo "✗ Plugin update finished with $__u_failures failure(s)"
        set final_status 1
    end
    set_color normal

    return $final_status
end

function u --description "Update global tools and applications"
    if test (count $argv) -gt 0
        if test (count $argv) -eq 1; and test "$argv[1]" = plugins
            __u_update_plugins
            return $status
        end

        echo "Usage: u [plugins]" >&2
        return 2
    end

    set -f __u_failures 0

    # ── Homebrew
    __u_section Homebrew
    __u_run "Homebrew done" bash -c "brew update && brew upgrade --no-ask && brew autoremove && brew cleanup --prune=all && brew bundle dump --force --file ~/dotfiles/Brewfile --no-vscode"

    # ── Node
    __u_section Node
    __u_run "npm updated" env PATH="/opt/homebrew/bin:$PATH" PUPPETEER_SKIP_DOWNLOAD=true npm update -g
    __u_run "pnpm updated" env PATH="/opt/homebrew/bin:$PNPM_HOME:$PATH" fish -c "cd; and pnpm update -g; and pnpm store prune"

    # ── Python (uv)
    __u_section "Python / uv"
    __u_run "uv tools upgraded" uv tool upgrade --all
    __u_run "uv cache pruned" uv cache prune

    # ── Mac App Store
    __u_section "Mac App Store"
    __u_run "MAS updated" mas update

    # ── Mole
    __u_section Mole
    __u_run "Mole cleaned" mo clean </dev/null

    # ── Done
    echo ""
    set -l final_status 0
    if test $__u_failures -eq 0
        set_color --bold green
        echo "✓ All updated"
    else
        set_color --bold red
        echo "✗ Update finished with $__u_failures failure(s)"
        set final_status 1
    end
    set_color normal

    return $final_status
end
