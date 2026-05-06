function bat_theme_preview --description "Preview bat themes with fzf"
    if not command -q bat
        echo "bat_theme_preview: bat is not installed" >&2
        return 1
    end

    if not command -q fzf
        echo "bat_theme_preview: fzf is not installed" >&2
        return 1
    end

    set -l preview_target "$HOME/.config/fish/config.fish"
    if test (count $argv) -gt 0
        set preview_target $argv[1]
    end

    if not test -f "$preview_target"
        echo "bat_theme_preview: file not found: $preview_target" >&2
        return 1
    end

    set -l bat_config "$HOME/.config/bat/config"
    if test -L "$bat_config"
        set bat_config (readlink "$bat_config")
    end

    if not test -f "$bat_config"
        echo "bat_theme_preview: bat config not found: $bat_config" >&2
        return 1
    end

    set -l theme (bat --list-themes | fzf \
        --prompt="bat theme> " \
        --preview "bat --theme={} --color=always --style=numbers,changes,header --paging=never \"$preview_target\"" \
        --preview-window="right,70%,border-left" \
        --header "Enter: apply theme | Previewing: $preview_target")

    if test -n "$theme"
        set -l replacement "--theme=\"$theme\""
        set -l current_config (cat "$bat_config")
        set -l updated_config (string replace -r -- '^--theme=.*$' "$replacement" $current_config)

        if not string match -rq -- '^--theme=.*$' $current_config
            set updated_config $replacement
            for line in $current_config
                if test -n "$line"
                    set updated_config $line $updated_config
                end
            end
        end

        printf '%s\n' $updated_config > "$bat_config"
        or return 1

        bat cache --build
        or begin
            echo "bat_theme_preview: updated config but failed to rebuild bat cache" >&2
            return 1
        end

        echo "Applied bat theme: $theme"
    end
end
