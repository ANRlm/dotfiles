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

function __u_plugin_list --argument-names tool
    set -l json ($tool plugin list --json); or return
    switch $tool
        case claude
            printf '%s\n' $json | jq -sr 'if length != 1 or (.[0] | type) != "array" then error("Expected one plugin array") else .[0] end | [.[] | select(.id | endswith("@skills-dir") | not) | .id] | unique[]'
    end
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

function __u_sync_skills
    set -l shared "$HOME/.agents/skills"
    test -d "$shared"; or return 1
    set -l profile "$HOME/.claude"
    if set -q CLAUDE_CONFIG_DIR; and test -n "$CLAUDE_CONFIG_DIR"
        set profile "$CLAUDE_CONFIG_DIR"
    end
    set -l target "$profile/skills"
    mkdir -p "$target"; or return
    # Follow local skill links and discover scoped packages such as @tencent-adm.
    set -l manifests (find -L "$shared" -type f -name SKILL.md -print); or return
    set -l failed 0
    for manifest in $manifests
        set -l source (path dirname "$manifest")
        set -l link "$target/"(path basename "$source")
        if test -e "$link"; or test -L "$link"
            set -l resolved (path resolve "$link")
            set -l expected (path resolve "$source")
            if not test -L "$link"; or test "$resolved" != "$expected"
                echo "  Skill link conflict: $link (expected $source)" >&2
                set failed 1
            end
        else
            ln -s "$source" "$link"; or set failed 1
        end
    end
    return $failed
end

# Names that `skills update` reported as deleted upstream.
function __u_deleted_skills
    awk 'BEGIN { esc = sprintf("%c", 27) }
        { gsub(esc "\\[[0-9;]*[A-Za-z]", "") }
        /deleted upstream:/ { warned = 1; next }
        warned && NF == 0 { next }
        warned && /^[[:space:]]*•/ { sub(/^[[:space:]]*•[[:space:]]*/, ""); print; next }
        warned { exit }'
end

# Update global skills, then drop the copies whose upstream stopped shipping them.
# `skills update -y` only warns about those, so the pruning happens here.
function __u_update_skills
    set -l log (mktemp -t u-skills)
    npx -y skills update -g -y 2>&1 | tee $log
    set -l code $pipestatus[1]
    set -l names (__u_deleted_skills <$log)
    rm -f $log
    test $code -eq 0; or return $code
    test (count $names) -eq 0; and return 0
    echo "  Removing skills deleted upstream: $names"
    npx -y skills remove $names -g -y
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
    # Run from $HOME so a project's mise.toml is never upgraded in place.
    __u_run "mise tools upgraded" mise -C "$HOME" upgrade

    # ── Agent skills & plugins ────────────────────────────────────────

    # Shared skills live in ~/.agents/skills: Codex and Pi read it directly,
    # Claude Code reads per-skill symlinks in CLAUDE_CONFIG_DIR.
    __u_section "Agent skills & plugins"
    __u_run "Shared skills updated" __u_update_skills
    # update only refreshes installed skills; re-adding picks up new upstream ones
    __u_run "mattpocock skills synced" npx -y skills add mattpocock/skills --skill '*' -g -a claude-code -a codex -a pi -y
    __u_run "TokenHub skills updated" thcli +connect --target $HOME/.agents/skills </dev/null
    __u_run "Claude skill links synced" __u_sync_skills
    if __u_run "Claude marketplaces updated" claude plugin marketplace update
        set -l plugins (__u_plugin_list claude)
        if test $status -eq 0
            for plugin in $plugins
                __u_run "Claude plugin $plugin updated" claude plugin update $plugin
            end
        else
            __u_run "Claude plugin list read" false
        end
    end
    __u_run "Codex marketplaces upgraded" codex plugin marketplace upgrade
    __u_run "Pi packages updated" pi update --extensions
    __u_run "Grok plugins updated" grok plugin update

    # ── Python (uv) ───────────────────────────────────────────────────

    __u_section "Python / uv"
    __u_run "uv cache pruned" uv cache prune

    # ── Mac App Store ─────────────────────────────────────────────────

    __u_section "Mac App Store"
    # The Brewfile lists more than this machine installs.
    if type -q mas
        __u_run "MAS updated" mas update
    else
        echo "  mas not installed, skipped"
    end

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
    # Bulk update keeps each install's ref and config and skips linked plugins.
    __u_run "Herdr plugins updated" herdr plugin update -y
    # Hook scripts live outside the repo, so a Herdr upgrade leaves them stale.
    # Install only the stale ones: reinstalling rewrites the agent's own config.
    # Grok keeps its hooks under GROK_HOME, which only the grok wrapper sets.
    set -l integrations (env GROK_HOME=$HOME/.grok-profiles/default herdr integration status)
    set -l outdated
    for agent in claude codex pi grok
        string match -q -- "$agent: outdated*" $integrations; and set -a outdated $agent
    end
    if test -z "$outdated"
        __u_ok "Herdr integrations current"
    else
        for agent in $outdated
            __u_run "$agent integration updated" env GROK_HOME=$HOME/.grok-profiles/default herdr integration install $agent
        end
    end

    # ── Yazi ──────────────────────────────────────────────────────────

    __u_section Yazi
    __u_run "Yazi plugins updated" __u_retry 3 ya pkg upgrade

    # ── Mole ──────────────────────────────────────────────────────────

    __u_section Mole
    # Piped so Mole skips its clear-screen and keeps earlier results visible.
    __u_run "Mole cleaned" bash -o pipefail -c 'mo clean </dev/null | cat'

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
