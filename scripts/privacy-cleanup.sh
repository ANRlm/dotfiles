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

user_defaults() {
    sudo -u "$TARGET_USER" HOME="$TARGET_HOME" defaults "$@"
}


# ----------------------------------------------------------
# --------------------Clear bash history--------------------
# ----------------------------------------------------------
echo '--- Clear bash history'
rm -f ~/.bash_history
# ----------------------------------------------------------


# ----------------------------------------------------------
# --------------------Clear zsh history---------------------
# ----------------------------------------------------------
echo '--- Clear zsh history'
rm -f ~/.zsh_history
# ----------------------------------------------------------


# ----------------------------------------------------------
# ------------------Clear diagnostic logs-------------------
# ----------------------------------------------------------
echo '--- Clear diagnostic logs'
# Clear directory contents: "/private/var/db/diagnostics"
glob_pattern="/private/var/db/diagnostics/*"
sudo rm -rfv $glob_pattern
# ----------------------------------------------------------


# ----------------------------------------------------------
# ---------------Clear diagnostic log details---------------
# ----------------------------------------------------------
echo '--- Clear diagnostic log details'
# Clear directory contents: "/private/var/db/uuidtext"
glob_pattern="/private/var/db/uuidtext/*"
sudo rm -rfv $glob_pattern
# ----------------------------------------------------------


# ----------------------------------------------------------
# --------------Clear Apple System Logs (ASL)---------------
# ----------------------------------------------------------
echo '--- Clear Apple System Logs (ASL)'
# Clear directory contents: "/private/var/log/asl"
glob_pattern="/private/var/log/asl/*"
sudo rm -rfv $glob_pattern
# Delete files matching pattern: "/private/var/log/asl.log"
glob_pattern="/private/var/log/asl.log"
sudo rm -fv $glob_pattern
# Delete files matching pattern: "/private/var/log/asl.db"
glob_pattern="/private/var/log/asl.db"
sudo rm -fv $glob_pattern
# ----------------------------------------------------------


# ----------------------------------------------------------
# -----------------Clear installation logs------------------
# ----------------------------------------------------------
echo '--- Clear installation logs'
# Delete files matching pattern: "/private/var/log/install.log"
glob_pattern="/private/var/log/install.log"
sudo rm -fv $glob_pattern
# ----------------------------------------------------------


# ----------------------------------------------------------
# ------------------Clear all system logs-------------------
# ----------------------------------------------------------
echo '--- Clear all system logs'
# Clear directory contents: "/private/var/log"
glob_pattern="/private/var/log/*"
sudo rm -rfv $glob_pattern
# ----------------------------------------------------------


# ----------------------------------------------------------
# --------------Clear system application logs---------------
# ----------------------------------------------------------
echo '--- Clear system application logs'
# Clear directory contents: "/Library/Logs"
glob_pattern="/Library/Logs/*"
sudo rm -rfv $glob_pattern
# ----------------------------------------------------------


# ----------------------------------------------------------
# ---------------Clear user application logs----------------
# ----------------------------------------------------------
echo '--- Clear user application logs'
# Clear directory contents: "$HOME/Library/Logs"
glob_pattern="$HOME/Library/Logs/*"
 rm -rfv $glob_pattern
# ----------------------------------------------------------


# ----------------------------------------------------------
# -------------------Clear Mail app logs--------------------
# ----------------------------------------------------------
echo '--- Clear Mail app logs'
# Clear directory contents: "$HOME/Library/Containers/com.apple.mail/Data/Library/Logs/Mail"
glob_pattern="$HOME/Library/Containers/com.apple.mail/Data/Library/Logs/Mail/*"
 rm -rfv $glob_pattern
# ----------------------------------------------------------


# Clear user activity audit logs (login, logout, authentication, etc.)
echo '--- Clear user activity audit logs (login, logout, authentication, etc.)'
# Clear directory contents: "/private/var/audit"
glob_pattern="/private/var/audit/*"
sudo rm -rfv $glob_pattern
# ----------------------------------------------------------


# ----------------------------------------------------------
# --------------Clear system maintenance logs---------------
# ----------------------------------------------------------
echo '--- Clear system maintenance logs'
# Delete files matching pattern: "/private/var/log/daily.out"
glob_pattern="/private/var/log/daily.out"
sudo rm -fv $glob_pattern
# Delete files matching pattern: "/private/var/log/weekly.out"
glob_pattern="/private/var/log/weekly.out"
sudo rm -fv $glob_pattern
# Delete files matching pattern: "/private/var/log/monthly.out"
glob_pattern="/private/var/log/monthly.out"
sudo rm -fv $glob_pattern
# ----------------------------------------------------------


# ----------------------------------------------------------
# ---------------Clear app installation logs----------------
# ----------------------------------------------------------
echo '--- Clear app installation logs'
# Clear directory contents: "/private/var/db/receipts"
glob_pattern="/private/var/db/receipts/*"
sudo rm -rfv $glob_pattern
# Delete files matching pattern: "/Library/Receipts/InstallHistory.plist"
glob_pattern="/Library/Receipts/InstallHistory.plist"
 rm -fv $glob_pattern
# ----------------------------------------------------------


# ----------------------------------------------------------
# --------------------Clear Chrome cache--------------------
# ----------------------------------------------------------
echo '--- Clear Chrome cache'
sudo rm -rfv "$HOME/Library/Application Support/Google/Chrome/Default/Application Cache/"* &>/dev/null
# ----------------------------------------------------------


# ----------------------------------------------------------
# ------Clear Safari cached blobs, URLs and timestamps------
# ----------------------------------------------------------
echo '--- Clear Safari cached blobs, URLs and timestamps'
rm -f ~/Library/Caches/com.apple.Safari/Cache.db
# ----------------------------------------------------------


# ----------------------------------------------------------
# -----------Clear Safari URL bar web page icons------------
# ----------------------------------------------------------
echo '--- Clear Safari URL bar web page icons'
rm -f ~/Library/Safari/WebpageIcons.db
# ----------------------------------------------------------


# ----------------------------------------------------------
# --------Clear Safari webpage previews (thumbnails)--------
# ----------------------------------------------------------
echo '--- Clear Safari webpage previews (thumbnails)'
rm -rfv ~/Library/Caches/com.apple.Safari/Webpage\ Previews
# ----------------------------------------------------------


# ----------------------------------------------------------
# --------------Clear Safari browsing history---------------
# ----------------------------------------------------------
echo '--- Clear Safari browsing history'
rm -f ~/Library/Safari/History.db
rm -f ~/Library/Safari/History.db-lock
rm -f ~/Library/Safari/History.db-shm
rm -f ~/Library/Safari/History.db-wal
# For older versions of Safari
rm -f ~/Library/Safari/History.plist # URL, visit count, webpage title, last visited timestamp, redirected URL, autocomplete
rm -f ~/Library/Safari/HistoryIndex.sk # History index
# ----------------------------------------------------------


# ----------------------------------------------------------
# --------------Clear Safari downloads history--------------
# ----------------------------------------------------------
echo '--- Clear Safari downloads history'
rm -f ~/Library/Safari/Downloads.plist
# ----------------------------------------------------------


# ----------------------------------------------------------
# ----------Clear Safari frequently visited sites-----------
# ----------------------------------------------------------
echo '--- Clear Safari frequently visited sites'
rm -f ~/Library/Safari/TopSites.plist
# ----------------------------------------------------------


# ----------------------------------------------------------
# ------Clear Safari last session (open tabs) history-------
# ----------------------------------------------------------
echo '--- Clear Safari last session (open tabs) history'
rm -f ~/Library/Safari/LastSession.plist
# ----------------------------------------------------------


# ----------------------------------------------------------
# ----------------Clear Safari history copy-----------------
# ----------------------------------------------------------
echo '--- Clear Safari history copy'
rm -rfv ~/Library/Caches/Metadata/Safari/History
# ----------------------------------------------------------


# ----------------------------------------------------------
# -Clear search term history embedded in Safari preferences-
# ----------------------------------------------------------
echo '--- Clear search term history embedded in Safari preferences'
user_defaults write com.apple.Safari RecentSearchStrings '( )'
# ----------------------------------------------------------


# ----------------------------------------------------------
# -------------------Clear Safari cookies-------------------
# ----------------------------------------------------------
echo '--- Clear Safari cookies'
rm -f ~/Library/Cookies/Cookies.binarycookies
# Used before Safari 5.1
rm -f ~/Library/Cookies/Cookies.plist
# ----------------------------------------------------------


# ----------------------------------------------------------
# -------Clear Safari zoom level preferences per site-------
# ----------------------------------------------------------
echo '--- Clear Safari zoom level preferences per site'
rm -f ~/Library/Safari/PerSiteZoomPreferences.plist
# ----------------------------------------------------------


# ----------------------------------------------------------
# -------Clear allowed URLs for Safari notifications--------
# ----------------------------------------------------------
echo '--- Clear allowed URLs for Safari notifications'
rm -f ~/Library/Safari/UserNotificationPreferences.plist
# ----------------------------------------------------------


# Clear Safari preferences for downloads, geolocation, pop-ups, and autoplay per site
echo '--- Clear Safari preferences for downloads, geolocation, pop-ups, and autoplay per site'
rm -f ~/Library/Safari/PerSitePreferences.db
# ----------------------------------------------------------


# ----------------------------------------------------------
# ------------Clear privacy.sexy script history-------------
# ----------------------------------------------------------
echo '--- Clear privacy.sexy script history'
# Clear directory contents: "$HOME/Library/Application Support/privacy.sexy/runs"
rm -rfv "$HOME/Library/Application Support/privacy.sexy/runs/"*
# ----------------------------------------------------------


# ----------------------------------------------------------
# -------------Clear privacy.sexy activity logs-------------
# ----------------------------------------------------------
echo '--- Clear privacy.sexy activity logs'
# Clear directory contents: "$HOME/Library/Logs/privacy.sexy"
glob_pattern="$HOME/Library/Logs/privacy.sexy/*"
 rm -rfv $glob_pattern
# ----------------------------------------------------------


# ----------------------------------------------------------
# --------------------Clear Adobe cache---------------------
# ----------------------------------------------------------
echo '--- Clear Adobe cache'
sudo rm -rfv "$HOME/Library/Application Support/Adobe/Common/Media Cache Files/"* &>/dev/null
# ----------------------------------------------------------


# ----------------------------------------------------------
# --------------------Clear Gradle cache--------------------
# ----------------------------------------------------------
echo '--- Clear Gradle cache'
if [ -d "$HOME/.gradle/caches" ]; then
    rm -rfv "$HOME/.gradle/caches/" &> /dev/null
fi
# ----------------------------------------------------------


# ----------------------------------------------------------
# -------------------Clear Dropbox cache--------------------
# ----------------------------------------------------------
echo '--- Clear Dropbox cache'
if [ -d "$HOME/Dropbox/.dropbox.cache" ]; then
    sudo rm -rfv "$HOME/Dropbox/.dropbox.cache/"* &>/dev/null
fi
# ----------------------------------------------------------


# ----------------------------------------------------------
# -----------Clear Google Drive File Stream cache-----------
# ----------------------------------------------------------
echo '--- Clear Google Drive File Stream cache'
killall "Google Drive File Stream"
rm -rfv "$HOME"/Library/Application\ Support/Google/DriveFS/[0-9a-zA-Z]*/content_cache &>/dev/null
# ----------------------------------------------------------


# ----------------------------------------------------------
# -------------------Clear Composer cache-------------------
# ----------------------------------------------------------
echo '--- Clear Composer cache'
if type "composer" &> /dev/null; then
    composer clearcache &> /dev/null
fi
# ----------------------------------------------------------


# ----------------------------------------------------------
# -------------------Clear Homebrew cache-------------------
# ----------------------------------------------------------
echo '--- Clear Homebrew cache'
if type "brew" &>/dev/null; then
    brew cleanup -s &>/dev/null
    brew_cache="$(brew --cache)"
    rm -rfv "$brew_cache" &>/dev/null
    brew tap --repair &>/dev/null
fi
# ----------------------------------------------------------


# ----------------------------------------------------------
# ---------------Clear old Ruby gem versions----------------
# ----------------------------------------------------------
echo '--- Clear old Ruby gem versions'
if type "gem" &> /dev/null; then
    gem cleanup &>/dev/null
fi
# ----------------------------------------------------------


# ----------------------------------------------------------
# -----------------Clear unused Docker data-----------------
# ----------------------------------------------------------
echo '--- Clear unused Docker data'
if type "docker" &> /dev/null; then
    docker system prune -af
fi
# ----------------------------------------------------------


# ----------------------------------------------------------
# ---------------Clear Pyenv-Virtualenv cache---------------
# ----------------------------------------------------------
echo '--- Clear Pyenv-Virtualenv cache'
if [ -n "${PYENV_VIRTUALENV_CACHE_PATH:-}" ]; then
    rm -rfv "$PYENV_VIRTUALENV_CACHE_PATH" &>/dev/null
fi
# ----------------------------------------------------------


# ----------------------------------------------------------
# ---------------------Clear NPM cache----------------------
# ----------------------------------------------------------
echo '--- Clear NPM cache'
if type "npm" &> /dev/null; then
    npm cache clean --force
fi
# ----------------------------------------------------------


# ----------------------------------------------------------
# ---------------------Clear Yarn cache---------------------
# ----------------------------------------------------------
echo '--- Clear Yarn cache'
if type "yarn" &> /dev/null; then
    echo 'Cleanup Yarn Cache...'
    yarn cache clean --force
fi
# ----------------------------------------------------------


# ----------------------------------------------------------
# -------------Clear iOS app copies from iTunes-------------
# ----------------------------------------------------------
echo '--- Clear iOS app copies from iTunes'
rm -rfv ~/Music/iTunes/iTunes\ Media/Mobile\ Applications/* &>/dev/null
# ----------------------------------------------------------


# ----------------------------------------------------------
# ------------------Clear iOS photo cache-------------------
# ----------------------------------------------------------
echo '--- Clear iOS photo cache'
rm -rf ~/Pictures/iPhoto\ Library/iPod\ Photo\ Cache/*
# ----------------------------------------------------------


# ----------------------------------------------------------
# -----------------Clear iOS Device Backups-----------------
# ----------------------------------------------------------
echo '--- Clear iOS Device Backups'
rm -rfv ~/Library/Application\ Support/MobileSync/Backup/* &>/dev/null
# ----------------------------------------------------------


# ----------------------------------------------------------
# -------------------Clear iOS simulators-------------------
# ----------------------------------------------------------
echo '--- Clear iOS simulators'
if type "xcrun" &>/dev/null; then
    osascript -e 'tell application "com.apple.CoreSimulator.CoreSimulatorService" to quit'
    osascript -e 'tell application "iOS Simulator" to quit'
    osascript -e 'tell application "Simulator" to quit'
    xcrun simctl shutdown all
    xcrun simctl erase all
fi
# ----------------------------------------------------------


# ----------------------------------------------------------
# -----------Clear list of connected iOS devices------------
# ----------------------------------------------------------
echo '--- Clear list of connected iOS devices'
sudo defaults delete "$HOME/Library/Preferences/com.apple.iPod.plist" "conn:128:Last Connect"
sudo defaults delete "$HOME/Library/Preferences/com.apple.iPod.plist" Devices
sudo defaults delete /Library/Preferences/com.apple.iPod.plist "conn:128:Last Connect"
sudo defaults delete /Library/Preferences/com.apple.iPod.plist Devices
sudo rm -rfv /var/db/lockdown/*
# ----------------------------------------------------------


# ----------------------------------------------------------
# ---------------Clear CUPS printer job cache---------------
# ----------------------------------------------------------
echo '--- Clear CUPS printer job cache'
sudo rm -rfv /var/spool/cups/c0*
sudo rm -rfv /var/spool/cups/tmp/*
sudo rm -rfv /var/spool/cups/cache/job.cache*
# ----------------------------------------------------------


# ----------------------------------------------------------
# ----------------Empty trash on all volumes----------------
# ----------------------------------------------------------
echo '--- Empty trash on all volumes'
# on all mounted volumes
sudo rm -rfv /Volumes/*/.Trashes/* &>/dev/null
# on main HDD
sudo rm -rfv ~/.Trash/* &>/dev/null
# ----------------------------------------------------------


# ----------------------------------------------------------
# --------------------Clear system cache--------------------
# ----------------------------------------------------------
echo '--- Clear system cache'
sudo rm -rfv /Library/Caches/* &>/dev/null
sudo rm -rfv /System/Library/Caches/* &>/dev/null
sudo rm -rfv ~/Library/Caches/* &>/dev/null
# ----------------------------------------------------------


# ----------------------------------------------------------
# ---------Clear Xcode's derived data and archives----------
# ----------------------------------------------------------
echo '--- Clear Xcode'\''s derived data and archives'
rm -rfv ~/Library/Developer/Xcode/DerivedData/* &>/dev/null
rm -rfv ~/Library/Developer/Xcode/Archives/* &>/dev/null
rm -rfv ~/Library/Developer/Xcode/iOS Device Logs/* &>/dev/null
# ----------------------------------------------------------


# ----------------------------------------------------------
# ---------------------Clear DNS cache----------------------
# ----------------------------------------------------------
echo '--- Clear DNS cache'
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
# ----------------------------------------------------------


# ----------------------------------------------------------
# ------------------Clear inactive memory-------------------
# ----------------------------------------------------------
echo '--- Clear inactive memory'
sudo purge
# ----------------------------------------------------------


# ----------------------------------------------------------
# --------------------Remove Guest User---------------------
# ----------------------------------------------------------
echo '--- Remove Guest User'
if ! command -v 'sysadminctl' &> /dev/null; then
    echo 'Skipping because "sysadminctl" is not found.'
else
    sudo sysadminctl -deleteUser Guest
fi
if ! command -v 'fdesetup' &> /dev/null; then
    echo 'Skipping because "fdesetup" is not found.'
else
    sudo fdesetup remove -user Guest
fi
if ! command -v 'dscl' &> /dev/null; then
    echo 'Skipping because "dscl" is not found.'
else
    sudo dscl . delete /Users/Guest
fi
# ----------------------------------------------------------


echo 'Your privacy and security is now hardened 🎉💪'
echo 'Press any key to exit.'
read -n 1 -s
