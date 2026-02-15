function ripgrep_search --description "Live ripgrep search with fzf"
    set -l RG_PREFIX 'rg --column --line-number --no-heading --color=always --smart-case'
    set -l result (
        FZF_DEFAULT_COMMAND="$RG_PREFIX ''" fzf \
            --ansi \
            --disabled \
            --query (commandline -t) \
            --bind "change:reload:$RG_PREFIX {q} || true" \
            --bind 'ctrl-o:execute(nvim {1} +{2})' \
            --preview 'bat --color=always {1} --highlight-line {2}' \
            --preview-window 'right:60%:~3:+{2}+3/3' \
            --delimiter ':'
    )
    if test -n "$result"
        set -l parts (string split : $result)
        commandline -t -- "$parts[1]:$parts[2]"
    end
    commandline -f repaint
end
