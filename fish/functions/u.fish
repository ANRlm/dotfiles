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

# Skip a step whose tool is missing: the Brewfile and agent tools differ per machine.
function __u_has
    for cmd in $argv
        type -q $cmd; and continue
        echo "  $cmd not installed, skipped"
        return 1
    end
end

# One "id<TAB>scope<TAB>projectPath" line per updatable Claude plugin.
function __u_claude_plugins
    set -l json (claude plugin list --json); or return
    printf '%s\n' $json | jq -sr 'if length != 1 or (.[0] | type) != "array" then error("Expected one plugin array") else .[0] end | [.[] | select((.id | endswith("@skills-dir") | not) and .scope != "managed") | [.id, (.scope // "user"), (.projectPath // "")] | @tsv] | unique[]'
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
    set -l target "$HOME/.claude/skills"
    mkdir -p "$target"; or return
    # Follow local skill links and discover scoped packages such as @tencent-adm.
    set -l manifests (find -L "$shared" -type f -name SKILL.md -print); or return
    # Skills that a user-scope Claude plugin ships would load twice through a link.
    set -l plugin_skills
    set -l installed "$HOME/.claude/plugins/installed_plugins.json"
    if test -f "$installed"
        set -l dirs (jq -r '.plugins[][] | select(.scope == "user") | .installPath' "$installed"); or return
        for dir in $dirs
            test -d "$dir"; or continue
            for plugin_manifest in (find -L "$dir" -type f -name SKILL.md -print)
                set -a plugin_skills (path basename (path dirname "$plugin_manifest"))
            end
        end
    end
    set -l failed 0
    for manifest in $manifests
        set -l source (path dirname "$manifest")
        set -l link "$target/"(path basename "$source")
        if contains -- (path basename "$source") $plugin_skills
            # Drop only a link this function made; anything else stays.
            if test -L "$link"; and test (path resolve "$link") = (path resolve "$source")
                rm "$link"; or set failed 1
            end
            continue
        end
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

# Skill names printed by `skills add <source> --list`.
function __u_listed_skills
    awk 'BEGIN { esc = sprintf("%c", 27) }
        { gsub(esc "\\[[0-9;]*[A-Za-z]", "") }
        /^│    [a-z0-9][a-z0-9._-]*[[:space:]]*$/ { print $2 }'
end

# `skills update` only refreshes names already installed, so sources taken whole
# are added again to pick up skills that upstream added since.
function __u_add_skill_families
    set -l opts -g -a claude-code -a codex -a pi -y
    npx -y skills add https://open.feishu.cn/lark-cli/skills/regular --skill '*' $opts </dev/null; or return
    # Old names that only hand off to lark-meeting.
    npx -y skills remove lark-minutes lark-note lark-vc lark-vc-agent -g -y </dev/null; or return
    # AgentLoop skills drive the aliyun CLI; machines without it skip them.
    type -q aliyun; or return 0
    set -l repo aliyun/alibabacloud-aiops-skills
    set -l agentloop (npx -y skills add $repo --full-depth --list </dev/null | __u_listed_skills | string match -- 'alibabacloud-agentloop-*')
    if test (count $agentloop) -eq 0
        echo "  No AgentLoop skills listed in $repo" >&2
        return 1
    end
    npx -y skills add $repo --skill alibabacloud-cli-guidance $agentloop --full-depth $opts </dev/null
end

# Project and local scopes keep their own copy, updated from inside that project.
function __u_claude_plugin_update --argument-names plugin scope dir
    set -l here $PWD
    test -z "$dir"; or cd $dir; or return
    claude plugin update $plugin --scope $scope
    set -l code $status
    cd $here
    return $code
end

function u --description "Update global tools, applications and plugins"
    if set -q argv[1]
        echo "Usage: u" >&2
        return 2
    end

    set -f __u_failures 0
    set -l shared $HOME/.agents/skills

    # ── Homebrew ──────────────────────────────────────────────────────

    __u_section Homebrew
    if __u_run "Homebrew metadata updated" brew update
        # --greedy also upgrades casks that update themselves.
        __u_run "Homebrew packages upgraded" brew upgrade --greedy --no-ask
    end
    __u_run "Homebrew dependencies cleaned" brew autoremove
    __u_run "Homebrew cache cleaned" brew cleanup --prune=all
    __u_run "Brewfile updated" __u_brewfile_merge "$HOME/dotfiles/Brewfile"

    # ── Node ──────────────────────────────────────────────────────────

    __u_section Node
    __u_has npm; and __u_run "npm updated" npm update -g
    __u_has pnpm; and __u_run "pnpm store pruned" pnpm --dir "$HOME" store prune
    # Run from $HOME so a project's mise.toml is never upgraded in place.
    __u_has mise; and __u_run "mise tools upgraded" mise -C "$HOME" upgrade

    # ── Agent skills & plugins ────────────────────────────────────────

    # Shared skills live in ~/.agents/skills: Codex, Pi and Grok read it directly,
    # Claude Code reads per-skill symlinks in ~/.claude/skills.
    __u_section "Agent skills & plugins"
    if test -d $shared
        if __u_has npx
            __u_run "Shared skills updated" __u_update_skills
            __u_run "Lark (and AgentLoop) skill sets completed" __u_add_skill_families
            # tcapi is published only on ClawHub and drives tccli; --force replaces locally edited files.
            __u_has tccli; and __u_run "ClawHub skills updated" npx -y clawhub --workdir $HOME/.agents --dir skills --no-input update --all --force
        end
        __u_has thcli; and __u_run "TokenHub skills updated" thcli +connect --target $shared </dev/null
        # init, not update: update leaves locally edited files as they are
        __u_has bl; and __u_run "Bailian skills updated" bl skill init --quiet
        # The skill text follows the rex CLI; setup only refreshes the stub and session hooks.
        __u_has rex; and __u_run "Rex agent setup refreshed" rex skill setup </dev/null
    else
        echo "  $shared not found, shared skills skipped"
    end
    # AgentLoop and other product commands ship as aliyun CLI plugins.
    __u_has aliyun; and __u_run "Aliyun CLI plugins updated" aliyun plugin update </dev/null
    if __u_has claude
        test -d $shared; and __u_run "Claude skill links synced" __u_sync_skills
        if __u_run "Claude marketplaces updated" claude plugin marketplace update
            set -l plugins (__u_claude_plugins)
            if test $status -eq 0
                for entry in $plugins
                    set -l plugin (string split \t -- $entry)
                    if test -z "$plugin[3]"
                        __u_run "Claude plugin $plugin[1] updated" __u_claude_plugin_update $plugin
                    else if test -d "$plugin[3]"
                        __u_run "Claude plugin $plugin[1] updated in $plugin[3]" __u_claude_plugin_update $plugin
                    else
                        echo "  Claude plugin $plugin[1] skipped: $plugin[3] is gone"
                    end
                end
            else
                __u_run "Claude plugin list read" false
            end
        end
    end
    __u_has codex; and __u_run "Codex marketplaces upgraded" codex plugin marketplace upgrade
    __u_has pi; and __u_run "Pi packages updated" pi update --extensions
    __u_has grok; and __u_run "Grok plugins updated" grok plugin update

    # ── Python (uv) ───────────────────────────────────────────────────

    __u_section "Python / uv"
    __u_has uv; and __u_run "uv cache pruned" uv cache prune

    # ── Mac App Store ─────────────────────────────────────────────────

    __u_section "Mac App Store"
    __u_has mas; and __u_run "MAS updated" mas update

    # ── Yazi ──────────────────────────────────────────────────────────

    __u_section Yazi
    __u_has ya; and __u_run "Yazi plugins updated" __u_retry 3 ya pkg upgrade

    # ── Mole ──────────────────────────────────────────────────────────

    __u_section Mole
    # Piped so Mole skips its clear-screen and keeps earlier results visible.
    __u_has mo; and __u_run "Mole cleaned" bash -o pipefail -c 'mo clean </dev/null | cat'

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
