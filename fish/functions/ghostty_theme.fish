function ghostty_theme --description "Live-switch Ghostty themes with fzf preview"
    set -l config_file ~/.config/ghostty/config

    if not test -f $config_file
        echo "ghostty_theme: config not found at $config_file" >&2
        return 1
    end

    if not type -q fzf
        echo "ghostty_theme: fzf is required" >&2
        return 1
    end

    set -l themes (_ghostty_theme_list)
    if test (count $themes) -eq 0
        echo "ghostty_theme: no themes found" >&2
        return 1
    end

    set -l original_theme (_ghostty_theme_current)

    set -l query_args
    if test -n "$original_theme"
        set query_args --query "$original_theme"
    end

    set -l selected (printf '%s\n' $themes | fzf \
        --prompt='ghostty theme  ' \
        --height=90% \
        --border \
        --ansi \
        --preview 'fish -c "_ghostty_theme_preview {}"' \
        --preview-window='right,60%,border-left' \
        --bind 'focus:execute-silent(fish -c "_ghostty_theme_apply {}")' \
        --bind 'esc:abort' \
        $query_args)
    set -l fzf_status $status

    if test $fzf_status -ne 0
        if test -n "$original_theme"
            _ghostty_theme_apply "$original_theme"
            echo "ghostty_theme: cancelled, restored '$original_theme'"
        end
        return 0
    end

    _ghostty_theme_apply "$selected"
    echo "ghostty_theme: applied '$selected'"
end