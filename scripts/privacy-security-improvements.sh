#!/usr/bin/env bash
# https://privacy.sexy — v0.13.8 — Wed, 18 Feb 2026 17:58:55 GMT
if [ "$EUID" -ne 0 ]; then
    script_path=$([[ "$0" = /* ]] && echo "$0" || echo "$PWD/${0#./}")
    sudo TARGET_USER="$USER" TARGET_HOME="$HOME" "$script_path" || (
        echo 'Administrator privileges are required.'
        exit 1
    )
    exit 0
fi

TARGET_USER="${TARGET_USER:-${SUDO_USER:-$(id -un)}}"
TARGET_HOME="${TARGET_HOME:-$(dscl . -read "/Users/$TARGET_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')}"
TARGET_HOME="${TARGET_HOME:-$HOME}"
export HOME="$TARGET_HOME"


# ----------------------------------------------------------
# -------Disable incoming SSH and SFTP remote logins--------
# ----------------------------------------------------------
echo '--- Disable incoming SSH and SFTP remote logins'
echo 'yes' | sudo systemsetup -setremotelogin off
# ----------------------------------------------------------


# ----------------------------------------------------------
# ------------Disable the insecure TFTP service-------------
# ----------------------------------------------------------
echo '--- Disable the insecure TFTP service'
sudo launchctl disable 'system/com.apple.tftpd'
# ----------------------------------------------------------


# ----------------------------------------------------------
# ----------Disable Bonjour multicast advertising-----------
# ----------------------------------------------------------
echo '--- Disable Bonjour multicast advertising'
sudo defaults write /Library/Preferences/com.apple.mDNSResponder.plist NoMulticastAdvertisements -bool true
# ----------------------------------------------------------


# ----------------------------------------------------------
# -------------Disable insecure telnet protocol-------------
# ----------------------------------------------------------
echo '--- Disable insecure telnet protocol'
sudo launchctl disable system/com.apple.telnetd
# ----------------------------------------------------------


# ----------------------------------------------------------
# ----Disable local printer sharing with other computers----
# ----------------------------------------------------------
echo '--- Disable local printer sharing with other computers'
cupsctl --no-share-printers
# ----------------------------------------------------------


# Disable printing from external addresses, including the internet
echo '--- Disable printing from external addresses, including the internet'
cupsctl --no-remote-any
# ----------------------------------------------------------


# ----------------------------------------------------------
# ----------Disable remote printer administration-----------
# ----------------------------------------------------------
echo '--- Disable remote printer administration'
cupsctl --no-remote-admin
# ----------------------------------------------------------


# ----------------------------------------------------------
# -------------Disable captive portal detection-------------
# ----------------------------------------------------------
echo '--- Disable captive portal detection'
sudo defaults write '/Library/Preferences/SystemConfiguration/com.apple.captive.control.plist' Active -bool false
# ----------------------------------------------------------


# ----------------------------------------------------------
# ---------------Disable guest account login----------------
# ----------------------------------------------------------
echo '--- Disable guest account login'
sudo defaults write '/Library/Preferences/com.apple.loginwindow' 'GuestEnabled' -bool NO
if ! command -v 'sysadminctl' &> /dev/null; then
    echo 'Skipping because "sysadminctl" is not found.'
else
    sudo sysadminctl -guestAccount off
fi
# ----------------------------------------------------------


# ----------------------------------------------------------
# -----------Disable guest file sharing over SMB------------
# ----------------------------------------------------------
echo '--- Disable guest file sharing over SMB'
sudo defaults write '/Library/Preferences/SystemConfiguration/com.apple.smb.server' 'AllowGuestAccess' -bool NO
if ! command -v 'sysadminctl' &> /dev/null; then
    echo 'Skipping because "sysadminctl" is not found.'
else
    sudo sysadminctl -smbGuestAccess off
fi
# ----------------------------------------------------------


# ----------------------------------------------------------
# -----------Disable guest file sharing over AFP------------
# ----------------------------------------------------------
echo '--- Disable guest file sharing over AFP'
sudo defaults write '/Library/Preferences/com.apple.AppleFileServer' 'guestAccess' -bool NO
if ! command -v 'sysadminctl' &> /dev/null; then
    echo 'Skipping because "sysadminctl" is not found.'
else
    sudo sysadminctl -afpGuestAccess off
fi
sudo killall -HUP AppleFileServer
# ----------------------------------------------------------


echo 'Your privacy and security is now hardened 🎉💪'
echo 'Press any key to exit.'
read -n 1 -s
