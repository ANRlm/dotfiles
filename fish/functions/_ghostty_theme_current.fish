function _ghostty_theme_current --description "Read current Ghostty theme from config"
    set -l config_file ~/.config/ghostty/config
    test -f $config_file; or return 1

    # Last `theme = xxx` wins (matches Ghostty's own behavior)
    string match -rg '^\s*theme\s*=\s*(.+?)\s*$' < $config_file | tail -n1
end
