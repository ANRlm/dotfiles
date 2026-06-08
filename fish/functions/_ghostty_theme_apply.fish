function _ghostty_theme_apply --description "Apply a Ghostty theme: rewrite config, reload Ghostty, repaint current TTY"
    set -l name $argv[1]
    test -n "$name"; or return 1

    set -l config_file ~/.config/ghostty/config
    test -f $config_file; or return 1

    # Refuse to write a theme name that doesn't resolve to a real file.
    # This protects the user from typos breaking their Ghostty config.
    set -l file (_ghostty_theme_resolve "$name")
    if test -z "$file" -o ! -f "$file"
        return 1
    end

    # ── 1. Rewrite the `theme = ...` line, preserve the rest byte-for-byte ──
    set -l tmp (mktemp -t ghostty_theme.XXXXXX)
    awk -v new="$name" '
        BEGIN { replaced = 0 }
        /^[[:space:]]*theme[[:space:]]*=/ {
            match($0, /^[[:space:]]*/)
            indent = substr($0, RSTART, RLENGTH)
            print indent "theme = " new
            replaced = 1
            next
        }
        { print }
        END {
            if (!replaced) print "theme = " new
        }
    ' $config_file >$tmp
    or begin
        rm -f $tmp
        return 1
    end
    mv $tmp $config_file
    or begin
        rm -f $tmp
        return 1
    end

    # ── 2. Reload config in every running Ghostty (affects new cells/windows) ──
    set -l pids (pgrep -x ghostty 2>/dev/null)
    if test (count $pids) -gt 0
        kill -USR2 $pids 2>/dev/null
    end

    # ── 3. Repaint the current terminal so the window background updates ──
    # Ghostty (like xterm) only applies new theme colors to NEWLY written cells
    # after a config reload; existing cells and the window background layer keep
    # the old colors. We push OSC 10/11/12 to the current TTY so the window
    # background, default foreground, and cursor are updated immediately.
    # We intentionally do NOT clear the screen here: this hook is called from
    # fzf's focus binding while fzf is drawing on the main buffer, so a clear
    # would wipe the fzf UI. The previously-rendered cells will repaint as
    # soon as fish redraws its prompt (i.e. when fzf exits).
    set -l bg ""
    set -l fg ""
    set -l cursor ""
    while read -l line
        set line (string trim -- $line)
        test -z "$line"; and continue
        string match -q '#*' -- $line; and continue

        set -l m (string match -rg '^background\s*=\s*#?([0-9A-Fa-f]{6})' -- $line)
        test (count $m) -eq 1; and set bg $m[1]; and continue

        set m (string match -rg '^foreground\s*=\s*#?([0-9A-Fa-f]{6})' -- $line)
        test (count $m) -eq 1; and set fg $m[1]; and continue

        set m (string match -rg '^cursor-color\s*=\s*#?([0-9A-Fa-f]{6})' -- $line)
        test (count $m) -eq 1; and set cursor $m[1]; and continue
    end <$file

    # OSC 10 = default foreground, 11 = default background, 12 = cursor.
    # ST terminator = ESC \.
    set -l seq ""
    test -n "$fg"; and set seq $seq(printf '\e]10;#%s\e\\' $fg)
    test -n "$bg"; and set seq $seq(printf '\e]11;#%s\e\\' $bg)
    test -n "$cursor"; and set seq $seq(printf '\e]12;#%s\e\\' $cursor)

    # Write to /dev/tty via `tee` so fish never touches the fd directly.
    # `tee /dev/tty` lets tee open /dev/tty itself, avoiding fish's
    # "redirecting file '/dev/tty'" warning when the calling context has
    # no controlling terminal. If /dev/tty isn't writable, tee fails
    # silently — we ignore that since the config rewrite is the source of
    # truth and Ghostty will pick up the new theme on next reload anyway.
    if test -n "$seq"
        printf '%s' $seq | tee /dev/tty >/dev/null 2>/dev/null
    end

    # Always succeed if the config was rewritten; the OSC repaint is best-effort.
    return 0
end
