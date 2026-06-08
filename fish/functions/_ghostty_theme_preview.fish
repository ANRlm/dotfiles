function _ghostty_theme_preview --description "Render a rich Ghostty theme preview using its own colors"
    set -l theme_name $argv[1]
    test -n "$theme_name"; or return 1

    set -l file (_ghostty_theme_resolve "$theme_name"); or begin
        echo "Theme not found: $theme_name"
        return 1
    end

    # ── Parse theme file ────────────────────────────────────────────────
    set -l palette
    for i in (seq 0 15)
        set palette[(math $i + 1)] ""
    end
    set -l bg ""
    set -l fg ""
    set -l cursor ""
    set -l cursor_text ""
    set -l sel_bg ""
    set -l sel_fg ""

    while read -l line
        set line (string trim -- $line)
        test -z "$line"; and continue
        string match -q '#*' -- $line; and continue

        set -l m (string match -rg '^palette\s*=\s*([0-9]+)\s*=\s*#?([0-9A-Fa-f]{6})' -- $line)
        if test (count $m) -eq 2
            set -l idx $m[1]
            if test $idx -ge 0 -a $idx -le 15
                set palette[(math $idx + 1)] $m[2]
            end
            continue
        end

        set m (string match -rg '^background\s*=\s*#?([0-9A-Fa-f]{6})' -- $line)
        test (count $m) -eq 1; and set bg $m[1]; and continue

        set m (string match -rg '^foreground\s*=\s*#?([0-9A-Fa-f]{6})' -- $line)
        test (count $m) -eq 1; and set fg $m[1]; and continue

        set m (string match -rg '^cursor-color\s*=\s*#?([0-9A-Fa-f]{6})' -- $line)
        test (count $m) -eq 1; and set cursor $m[1]; and continue

        set m (string match -rg '^cursor-text\s*=\s*#?([0-9A-Fa-f]{6})' -- $line)
        test (count $m) -eq 1; and set cursor_text $m[1]; and continue

        set m (string match -rg '^selection-background\s*=\s*#?([0-9A-Fa-f]{6})' -- $line)
        test (count $m) -eq 1; and set sel_bg $m[1]; and continue

        set m (string match -rg '^selection-foreground\s*=\s*#?([0-9A-Fa-f]{6})' -- $line)
        test (count $m) -eq 1; and set sel_fg $m[1]; and continue
    end <$file

    # ── ANSI helpers ────────────────────────────────────────────────────
    function __gtt_hex2rgb -a hex
        set -l h (string lower $hex)
        echo 0x(string sub -s 1 -l 2 $h) 0x(string sub -s 3 -l 2 $h) 0x(string sub -s 5 -l 2 $h)
    end

    function __gtt_fg -a hex
        test -z "$hex"; and return
        set -l rgb (__gtt_hex2rgb $hex | string split ' ')
        printf '\e[38;2;%d;%d;%dm' $rgb[1] $rgb[2] $rgb[3]
    end

    function __gtt_bg -a hex
        test -z "$hex"; and return
        set -l rgb (__gtt_hex2rgb $hex | string split ' ')
        printf '\e[48;2;%d;%d;%dm' $rgb[1] $rgb[2] $rgb[3]
    end

    set -l RESET (printf '\e[0m')
    set -l BOLD (printf '\e[1m')
    set -l ITAL (printf '\e[3m')
    set -l UNDR (printf '\e[4m')
    set -l DIM (printf '\e[2m')

    # Fallbacks
    test -z "$bg"; and set bg "1d1f21"
    test -z "$fg"; and set fg "c5c8c6"
    test -z "$cursor"; and set cursor $fg
    test -z "$cursor_text"; and set cursor_text $bg
    test -z "$sel_bg"; and set sel_bg $palette[8]
    test -z "$sel_fg"; and set sel_fg $bg

    set -l FG (__gtt_fg $fg)

    set -l c_red $palette[2]
    set -l c_grn $palette[3]
    set -l c_yel $palette[4]
    set -l c_blu $palette[5]
    set -l c_mag $palette[6]
    set -l c_cyn $palette[7]
    set -l c_bred $palette[10]
    set -l c_bgrn $palette[11]
    set -l c_byel $palette[12]
    set -l c_bblu $palette[13]
    set -l c_bmag $palette[14]
    set -l c_bcyn $palette[15]
    set -l c_dim $palette[9]

    set -l display_file (string replace "$HOME/" '~/' -- $file)

    # ── Header ──────────────────────────────────────────────────────────
    echo -n -e -s $BOLD $FG $theme_name $RESET
    echo
    echo -n -e -s $DIM $display_file $RESET
    echo
    echo

    # ── Compact palette row ─────────────────────────────────────────────
    for i in (seq 1 16)
        set -l hex $palette[$i]
        if test -z "$hex"
            echo -n '    '
        else
            echo -n -e -s (__gtt_bg $hex) '   ' $RESET ' '
        end
    end
    echo

    for i in (seq 1 16)
        set -l hex $palette[$i]
        set -l idx (math $i - 1)
        if test -z "$hex"
            echo -n -e -s $DIM $idx':-' $RESET ' '
        else
            echo -n -e -s (__gtt_fg $hex) $idx':'$hex $RESET ' '
        end
    end
    echo
    echo

    # ── Meta colors line ────────────────────────────────────────────────
    echo -n -e -s $DIM 'bg' $RESET ' ' (__gtt_bg $bg) '   ' $RESET '  '
    echo -n -e -s $DIM 'fg' $RESET ' ' (__gtt_bg $fg) '   ' $RESET '  '
    echo -n -e -s $DIM 'cursor' $RESET ' ' (__gtt_bg $cursor) '   ' $RESET '  '
    echo -n -e -s $DIM 'sel-bg' $RESET ' ' (__gtt_bg $sel_bg) '   ' $RESET '  '
    echo -n -e -s $DIM 'sel-fg' $RESET ' ' (__gtt_bg $sel_fg) '   ' $RESET
    echo
    echo

    # ── Shell session ───────────────────────────────────────────────────
    echo -n -e -s $DIM '-- shell' $RESET
    echo
    echo -n -e -s (__gtt_fg $c_grn) '❯' $RESET ' ' (__gtt_fg $c_bblu) '~/code/project' $RESET ' ' (__gtt_fg $c_mag) 'main' $RESET ' ' (__gtt_fg $c_yel) '✱' $RESET ' ' (__gtt_fg $c_red) '!2' $RESET ' ' (__gtt_fg $c_grn) '+1' $RESET
    echo
    echo -n -e -s (__gtt_fg $c_cyn) '$' $RESET ' git status ' $DIM '--short' $RESET
    echo
    echo -n -e -s ' ' (__gtt_fg $c_yel) 'M' $RESET ' src/main.ts'
    echo
    echo -n -e -s ' ' (__gtt_fg $c_grn) 'A' $RESET ' tests/api.test.ts'
    echo
    echo -n -e -s ' ' (__gtt_fg $c_red) 'D' $RESET ' README.old.md'
    echo
    echo

    # ── Git diff ────────────────────────────────────────────────────────
    echo -n -e -s $DIM '-- diff' $RESET
    echo
    echo -n -e -s $DIM 'diff ' $RESET (__gtt_fg $c_blu) '--git' $RESET $DIM ' a/auth.ts b/auth.ts' $RESET
    echo
    echo -n -e -s (__gtt_fg $c_cyn) '@@ -10,3 +10,3 @@' $RESET
    echo
    echo -n -e -s (__gtt_fg $c_red) '-' $RESET ' ' (__gtt_fg $c_mag) 'const' $RESET ' ' (__gtt_fg $c_blu) 'token' $RESET ' = ' (__gtt_fg $c_grn) '"abc"' $RESET
    echo
    echo -n -e -s (__gtt_fg $c_grn) '+' $RESET ' ' (__gtt_fg $c_mag) 'const' $RESET ' ' (__gtt_fg $c_blu) 'token' $RESET ' = ' (__gtt_fg $c_grn) 'env.JWT' $RESET
    echo
    echo -n -e -s '  ' (__gtt_fg $c_mag) 'return' $RESET ' ' (__gtt_fg $c_bblu) 'verify' $RESET '(' (__gtt_fg $c_blu) 'token' $RESET ')'
    echo
    echo

    # ── TypeScript code ─────────────────────────────────────────────────
    echo -n -e -s $DIM '-- code · typescript' $RESET
    echo
    echo -n -e -s $DIM '// Greet a user and log the result' $RESET
    echo
    echo -n -e -s (__gtt_fg $c_mag) 'import' $RESET ' { ' (__gtt_fg $c_bblu) 'logger' $RESET ' } ' (__gtt_fg $c_mag) 'from' $RESET ' ' (__gtt_fg $c_grn) '"./log"' $RESET ';'
    echo
    echo
    echo -n -e -s (__gtt_fg $c_mag) 'export async function' $RESET ' ' (__gtt_fg $c_bblu) 'greet' $RESET '(' (__gtt_fg $c_blu) 'name' $RESET ': ' (__gtt_fg $c_yel) 'string' $RESET ', ' (__gtt_fg $c_blu) 'n' $RESET ' = ' (__gtt_fg $c_byel) '3' $RESET '): ' (__gtt_fg $c_yel) 'Promise' $RESET '<' (__gtt_fg $c_yel) 'void' $RESET '> {'
    echo
    echo -n -e -s '  ' (__gtt_fg $c_mag) 'for' $RESET ' (' (__gtt_fg $c_mag) 'let' $RESET ' ' (__gtt_fg $c_blu) 'i' $RESET ' = ' (__gtt_fg $c_byel) '0' $RESET '; ' (__gtt_fg $c_blu) 'i' $RESET ' < ' (__gtt_fg $c_blu) 'n' $RESET '; ' (__gtt_fg $c_blu) 'i' $RESET '++) {'
    echo
    echo -n -e -s '    ' (__gtt_fg $c_bblu) 'logger' $RESET '.' (__gtt_fg $c_bblu) 'info' $RESET '(' (__gtt_fg $c_grn) '`hello ' $RESET (__gtt_fg $c_mag) '${' $RESET (__gtt_fg $c_blu) 'name' $RESET (__gtt_fg $c_mag) '}' $RESET (__gtt_fg $c_grn) '!`' $RESET ');'
    echo
    echo -n -e -s '    ' (__gtt_fg $c_mag) 'await' $RESET ' ' (__gtt_fg $c_bblu) 'delay' $RESET '(' (__gtt_fg $c_byel) '100' $RESET ');'
    echo
    echo -n -e -s '  }'
    echo
    echo -n -e -s '}'
    echo
    echo

    # ── Python code ─────────────────────────────────────────────────────
    echo -n -e -s $DIM '-- code · python' $RESET
    echo
    echo -n -e -s (__gtt_fg $c_mag) '@dataclass' $RESET
    echo
    echo -n -e -s (__gtt_fg $c_mag) 'class' $RESET ' ' (__gtt_fg $c_yel) 'User' $RESET ':'
    echo
    echo -n -e -s '    ' (__gtt_fg $c_blu) 'name' $RESET ': ' (__gtt_fg $c_yel) 'str' $RESET
    echo
    echo -n -e -s '    ' (__gtt_fg $c_blu) 'active' $RESET ': ' (__gtt_fg $c_yel) 'bool' $RESET ' = ' (__gtt_fg $c_mag) 'True' $RESET
    echo
    echo
    echo -n -e -s (__gtt_fg $c_mag) 'def' $RESET ' ' (__gtt_fg $c_bblu) 'fetch_user' $RESET '(' (__gtt_fg $c_blu) 'user_id' $RESET ': ' (__gtt_fg $c_yel) 'int' $RESET ') -> ' (__gtt_fg $c_yel) 'User' $RESET ':'
    echo
    echo -n -e -s '    ' (__gtt_fg $c_dim) '"""Retrieve a user by id."""' $RESET
    echo
    echo -n -e -s '    ' (__gtt_fg $c_blu) 'user' $RESET ' = ' (__gtt_fg $c_bblu) 'db' $RESET '.' (__gtt_fg $c_bblu) 'get' $RESET '(' (__gtt_fg $c_blu) 'user_id' $RESET ')'
    echo
    echo -n -e -s '    ' (__gtt_fg $c_mag) 'if' $RESET ' ' (__gtt_fg $c_blu) 'user' $RESET ' ' (__gtt_fg $c_mag) 'is' $RESET ' ' (__gtt_fg $c_mag) 'None' $RESET ':'
    echo
    echo -n -e -s '        ' (__gtt_fg $c_mag) 'raise' $RESET ' ' (__gtt_fg $c_yel) 'ValueError' $RESET '(' (__gtt_fg $c_grn) 'f"User {user_id} not found"' $RESET ')'
    echo
    echo -n -e -s '    ' (__gtt_fg $c_mag) 'return' $RESET ' ' (__gtt_fg $c_blu) 'user' $RESET
    echo
    echo

    # ── Rust code ───────────────────────────────────────────────────────
    echo -n -e -s $DIM '-- code · rust' $RESET
    echo
    echo -n -e -s (__gtt_fg $c_mag) 'use' $RESET ' ' (__gtt_fg $c_yel) 'std::fs' $RESET ';'
    echo
    echo
    echo -n -e -s (__gtt_fg $c_mag) 'pub fn' $RESET ' ' (__gtt_fg $c_bblu) 'read_config' $RESET '(' (__gtt_fg $c_blu) 'path' $RESET ': &' (__gtt_fg $c_yel) 'str' $RESET ') -> ' (__gtt_fg $c_yel) 'Result' $RESET '<' (__gtt_fg $c_yel) 'String' $RESET ', ' (__gtt_fg $c_yel) 'io::Error' $RESET '> {'
    echo
    echo -n -e -s '    ' (__gtt_fg $c_mag) 'match' $RESET ' ' (__gtt_fg $c_bblu) 'fs' $RESET '::' (__gtt_fg $c_bblu) 'read_to_string' $RESET '(' (__gtt_fg $c_blu) 'path' $RESET ') {'
    echo
    echo -n -e -s '        ' (__gtt_fg $c_yel) 'Ok' $RESET '(' (__gtt_fg $c_blu) 'data' $RESET ') => ' (__gtt_fg $c_yel) 'Ok' $RESET '(' (__gtt_fg $c_blu) 'data' $RESET '.' (__gtt_fg $c_bblu) 'trim' $RESET '().' (__gtt_fg $c_bblu) 'to_string' $RESET '()),'
    echo
    echo -n -e -s '        ' (__gtt_fg $c_yel) 'Err' $RESET '(' (__gtt_fg $c_blu) 'e' $RESET ') => {'
    echo
    echo -n -e -s '            ' (__gtt_fg $c_bblu) 'eprintln' $RESET '!(' (__gtt_fg $c_grn) '"read failed: {}"' $RESET ', ' (__gtt_fg $c_blu) 'e' $RESET ');'
    echo
    echo -n -e -s '            ' (__gtt_fg $c_yel) 'Err' $RESET '(' (__gtt_fg $c_blu) 'e' $RESET ')'
    echo
    echo -n -e -s '        }'
    echo
    echo -n -e -s '    }'
    echo
    echo -n -e -s '}'
    echo
    echo

    # ── Markdown / log ──────────────────────────────────────────────────
    echo -n -e -s $DIM '-- markdown' $RESET
    echo
    echo -n -e -s $BOLD (__gtt_fg $c_bmag) '# Release Notes' $RESET
    echo
    echo -n -e -s $BOLD '**Breaking:**' $RESET ' ' $ITAL 'Removed legacy API.' $RESET
    echo
    echo -n -e -s 'Run ' (__gtt_fg $c_grn) '`migrate --v2`' $RESET ' before upgrading.'
    echo
    echo -n -e -s $UNDR (__gtt_fg $c_bblu) 'https://example.com/docs' $RESET
    echo
    echo -n -e -s (__gtt_fg $c_grn) '  [OK]' $RESET '    build passed'
    echo
    echo -n -e -s (__gtt_fg $c_yel) '  [WARN]' $RESET '  deprecation notice'
    echo
    echo -n -e -s (__gtt_fg $c_red) '  [ERR]' $RESET '   network timeout'
    echo
    echo

    # ── Selection / cursor inline chips ─────────────────────────────────
    echo -n -e -s $DIM '-- cursor & selection' $RESET
    echo
    echo -n -e -s (__gtt_bg $sel_bg) (__gtt_fg $sel_fg) ' selected text ' $RESET '  ' (__gtt_bg $cursor) (__gtt_fg $cursor_text) ' cursor ' $RESET
    echo
    echo

    # ── Final reset ─────────────────────────────────────────────────────
    echo -n -e -s $RESET
    echo

    functions --erase __gtt_hex2rgb __gtt_fg __gtt_bg
end
