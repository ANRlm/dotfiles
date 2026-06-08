function _ghostty_theme_list --description "List available Ghostty theme names"
    set -l builtin_dir /Applications/Ghostty.app/Contents/Resources/ghostty/themes
    set -l user_dir ~/.config/ghostty/themes

    set -l dirs
    test -d $builtin_dir; and set -a dirs $builtin_dir
    test -d $user_dir; and set -a dirs $user_dir

    if test (count $dirs) -eq 0
        return 1
    end

    find $dirs -maxdepth 1 -type f -exec basename {} \; | sort -fu
end
