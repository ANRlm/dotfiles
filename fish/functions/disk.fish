function disk --description "Show SMART information for the internal disk"
    if not command -q smartctl
        echo "disk: missing dependency: smartctl" >&2
        return 1
    end

    if command -q diskutil
        set -l dev (diskutil list | awk '/internal,/{print $1; exit}' | sed 's|/dev/||')
        if test -n "$dev"
            smartctl -a /dev/$dev
            return $status
        end
    end

    set -l scan_entry
    for line in (smartctl --scan-open 2>/dev/null)
        set scan_entry (string trim (string split -m 1 '#' -- $line)[1])
        if test -n "$scan_entry"
            break
        end
    end

    if test -z "$scan_entry"
        echo "disk: no SMART-capable disk found" >&2
        return 1
    end

    set -l scan_parts (string split ' ' -- $scan_entry)
    set -l device $scan_parts[1]
    set -l device_args $scan_parts[2..]
    smartctl -a $device_args $device
end
