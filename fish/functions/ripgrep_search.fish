function ripgrep_search --description "Live ripgrep search with fzf"
    set -l editor $EDITOR
    test -n "$editor"; or set editor hx

    for cmd in rg fzf bat $editor
        if not command -q $cmd
            echo "ripgrep_search: missing dependency: $cmd" >&2
            commandline -f repaint
            return 1
        end
    end

    set -l RG_PREFIX "rg --line-number --no-heading --color=always --smart-case --"
    set -l query (commandline -t)
    set -l result (
        fzf \
            --min-height=20+ \
            --bind=ctrl-z:ignore \
            --ansi \
            --disabled \
            --query "$query" \
            --delimiter : \
            --bind "start:reload:$RG_PREFIX {q} || true" \
            --bind "change:reload:$RG_PREFIX {q} || true" \
            --bind "ctrl-o:become($editor {1} +{2})" \
            --preview 'bat --style=numbers --color=always {1} --highlight-line {2}' \
            --preview-window 'right:50%:+{2}-/2'
    )
    if test -n "$result"
        set -l parts (string split -m 2 : -- $result)
        if test (count $parts) -ge 2
            commandline -t -- "$parts[1]:$parts[2]"
        end
    end
    commandline -f repaint
end
