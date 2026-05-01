function disk
    set dev (diskutil list | awk '/internal,/{print $1; exit}' | sed 's|/dev/||')
    smartctl -a /dev/$dev
end
