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

function __u_brewfile_merge --argument-names brewfile
    # Add newly installed entries only; this machine stays leaner than the list.
    # npm globals stay out of the list.
    set -l dump (brew bundle dump --file=- --no-vscode --no-npm --no-describe); or return
    set -l lines (cat $brewfile); or return
    for entry in $dump
        contains -- $entry $lines; and continue
        # Append after the last entry of the same kind (tap, brew, cask, ...).
        set -l kind (string split -m1 ' ' -- $entry)[1]
        set -l at 0
        set -l i 0
        for line in $lines
            set i (math $i + 1)
            string match -q -- "$kind *" $line; and set at $i
        end
        test $at -eq 0; and set at (count $lines)
        set -l merged
        test $at -eq 0; and set merged $entry
        set i 0
        for line in $lines
            set i (math $i + 1)
            set -a merged $line
            test $i -eq $at; and set -a merged $entry
        end
        set lines $merged
        echo "  + $entry"
    end
    printf '%s\n' $lines >$brewfile
end

function u --description "Update global tools, applications and plugins"
    if set -q argv[1]
        echo "Usage: u" >&2
        return 2
    end

    set -f __u_failures 0
    set -lx PATH /opt/homebrew/bin $PATH

    # ── Homebrew ──────────────────────────────────────────────────────

    __u_section Homebrew
    if __u_run "Homebrew metadata updated" brew update
        __u_run "Homebrew packages upgraded" brew upgrade --no-ask
    end
    __u_run "Homebrew dependencies cleaned" brew autoremove
    __u_run "Homebrew cache cleaned" brew cleanup --prune=all
    __u_run "Brewfile updated" __u_brewfile_merge "$HOME/dotfiles/Brewfile"

    # ── Node ──────────────────────────────────────────────────────────

    __u_section Node
    __u_run "npm updated" env PUPPETEER_SKIP_DOWNLOAD=true npm update -g
    __u_run "pnpm store pruned" pnpm --dir "$HOME" store prune

    # ── Agent skills & plugins ────────────────────────────────────────

    # Shared skills live in ~/.agents/skills: Codex and Pi read it directly,
    # Claude Code reads the symlinks `npx skills` keeps in its profile.
    __u_section "Agent skills & plugins"
    __u_run "Shared skills updated" npx -y skills update -g -y
    # shortcut: thcli links no new skill into Claude's profile; link it by hand if TokenHub adds one.
    __u_run "TokenHub skills updated" thcli +connect --target $HOME/.agents/skills </dev/null
    if __u_run "Claude marketplaces updated" claude plugin marketplace update
        for plugin in (claude plugin list --json | jq -r '.[] | select(.id | endswith("@skills-dir") | not) | .id')
            __u_run "Claude plugin $plugin updated" claude plugin update $plugin
        end
    end
    __u_run "Codex marketplaces upgraded" codex plugin marketplace upgrade
    __u_run "Pi packages updated" pi update --extensions
    __u_run "Cua Driver updated" cua-driver update --apply
    __u_run "treehouse updated" treehouse update

    # ── Python (uv) ───────────────────────────────────────────────────

    __u_section "Python / uv"
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

    # ── Herdr ─────────────────────────────────────────────────────────

    __u_section Herdr
    # Reinstalling a GitHub plugin moves it to the latest commit and keeps its config.
    for repo in (herdr plugin list --json | jq -r '.result.plugins[].source | select(.kind == "github") | "\(.owner)/\(.repo)"')
        __u_run "$repo updated" herdr plugin install $repo -y
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
