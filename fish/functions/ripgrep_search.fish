function ripgrep_search --description "Live ripgrep search with fzf"
    for cmd in rg fzf bat nvim
        if not command -q $cmd
            echo "ripgrep_search: missing dependency: $cmd" >&2
            commandline -f repaint
            return 1
        end
    end

    set -l field_separator (printf '\t')
    set -l RG_PREFIX "rg --column --line-number --no-heading --color=always --smart-case --field-match-separator='\\t'"
    set -l result (
        FZF_DEFAULT_COMMAND="$RG_PREFIX ''" fzf \
            --ansi \
            --disabled \
            --query (commandline -t) \
            --bind "change:reload:$RG_PREFIX {q} || true" \
            --bind 'ctrl-o:execute(nvim {1} +{2})' \
            --preview 'bat --color=always {1} --highlight-line {2}' \
            --preview-window 'right:60%:~3:+{2}+3/3' \
            --delimiter $field_separator
    )
    if test -n "$result"
        set -l parts (string split -m 3 $field_separator -- $result)
        if test (count $parts) -ge 2
            commandline -t -- "$parts[1]:$parts[2]"
        end
    end
    commandline -f repaint
end
