function _ghostty_theme_resolve --description "Resolve a theme name to its file path"
    set -l name $argv[1]
    test -n "$name"; or return 1

    set -l builtin_dir /Applications/Ghostty.app/Contents/Resources/ghostty/themes
    set -l user_dir ~/.config/ghostty/themes

    # User themes win over built-in
    for dir in $user_dir $builtin_dir
        if test -f "$dir/$name"
            echo "$dir/$name"
            return 0
        end
    end
    return 1
end
