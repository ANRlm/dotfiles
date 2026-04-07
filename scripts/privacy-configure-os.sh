#!/usr/bin/env bash
# https://privacy.sexy — v0.13.8 — Wed, 18 Feb 2026 17:58:55 GMT
if [ "$EUID" -ne 0 ]; then
    script_path=$([[ "$0" = /* ]] && echo "$0" || echo "$PWD/${0#./}")
    sudo TARGET_USER="$USER" TARGET_HOME="$HOME" TARGET_UID="$UID" "$script_path" || (
        echo 'Administrator privileges are required.'
        exit 1
    )
    exit 0
fi

TARGET_USER="${TARGET_USER:-${SUDO_USER:-$(id -un)}}"
TARGET_HOME="${TARGET_HOME:-$(dscl . -read "/Users/$TARGET_USER" NFSHomeDirectory 2>/dev/null | awk '{print $2}')}"
TARGET_HOME="${TARGET_HOME:-$HOME}"
TARGET_UID="${TARGET_UID:-$(id -u "$TARGET_USER" 2>/dev/null || echo "$UID")}"
export HOME="$TARGET_HOME"

user_defaults() {
    sudo -u "$TARGET_USER" HOME="$TARGET_HOME" defaults "$@"
}


# ----------------------------------------------------------
# ------------Disable remote management service-------------
# ----------------------------------------------------------
echo '--- Disable remote management service'
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -stop
# ----------------------------------------------------------


# ----------------------------------------------------------
# -----------Remove Apple Remote Desktop Settings-----------
# ----------------------------------------------------------
echo '--- Remove Apple Remote Desktop Settings'
sudo rm -rf /var/db/RemoteManagement
sudo defaults delete /Library/Preferences/com.apple.RemoteDesktop.plist
user_defaults delete com.apple.RemoteDesktop
sudo rm -rf /Library/Application\ Support/Apple/Remote\ Desktop/
rm -rf "$HOME/Library/Application Support/Remote Desktop/"
rm -rf "$HOME/Library/Containers/com.apple.RemoteDesktop"
# ----------------------------------------------------------


# ----------------------------------------------------------
# --------------------Disable "Ask Siri"--------------------
# ----------------------------------------------------------
echo '--- Disable "Ask Siri"'
user_defaults write com.apple.assistant.support 'Assistant Enabled' -bool false
# ----------------------------------------------------------


# ----------------------------------------------------------
# ---------------Disable Siri voice feedback----------------
# ----------------------------------------------------------
echo '--- Disable Siri voice feedback'
user_defaults write com.apple.assistant.backedup 'Use device speaker for TTS' -int 3
# ----------------------------------------------------------


# ----------------------------------------------------------
# -------Disable Siri services (Siri and assistantd)--------
# ----------------------------------------------------------
echo '--- Disable Siri services (Siri and assistantd)'
launchctl disable "user/$TARGET_UID/com.apple.assistantd"
launchctl disable "gui/$TARGET_UID/com.apple.assistantd"
sudo launchctl disable 'system/com.apple.assistantd'
launchctl disable "user/$TARGET_UID/com.apple.Siri.agent"
launchctl disable "gui/$TARGET_UID/com.apple.Siri.agent"
sudo launchctl disable 'system/com.apple.Siri.agent'
if [ $(/usr/bin/csrutil status | awk '/status/ {print $5}' | sed 's/\.$//') = "enabled" ]; then
    >&2 echo 'This script requires SIP to be disabled. Read more: https://developer.apple.com/documentation/security/disabling_and_enabling_system_integrity_protection'
fi
# ----------------------------------------------------------


# ----------------------------------------------------------
# -------Disable "Do you want to enable Siri?" pop-up-------
# ----------------------------------------------------------
echo '--- Disable "Do you want to enable Siri?" pop-up'
user_defaults write com.apple.SetupAssistant 'DidSeeSiriSetup' -bool true
# ----------------------------------------------------------


# ----------------------------------------------------------
# ----------------Remove Siri from menu bar-----------------
# ----------------------------------------------------------
echo '--- Remove Siri from menu bar'
user_defaults write com.apple.systemuiserver 'NSStatusItem Visible Siri' 0
# ----------------------------------------------------------


# ----------------------------------------------------------
# ---------------Remove Siri from status menu---------------
# ----------------------------------------------------------
echo '--- Remove Siri from status menu'
user_defaults write com.apple.Siri 'StatusMenuVisible' -bool false
user_defaults write com.apple.Siri 'UserHasDeclinedEnable' -bool true
# ----------------------------------------------------------


# ----------------------------------------------------------
# ------Disable participation in Siri data collection-------
# ----------------------------------------------------------
echo '--- Disable participation in Siri data collection'
user_defaults write com.apple.assistant.support 'Siri Data Sharing Opt-In Status' -int 2
# ----------------------------------------------------------


# ----------------------------------------------------------
# ------Disable display of recent applications on Dock------
# ----------------------------------------------------------
echo '--- Disable display of recent applications on Dock'
user_defaults write com.apple.dock show-recents -bool false
# ----------------------------------------------------------


# Disable personalized advertisements and identifier tracking
echo '--- Disable personalized advertisements and identifier tracking'
user_defaults write com.apple.AdLib allowIdentifierForAdvertising -bool false
user_defaults write com.apple.AdLib allowApplePersonalizedAdvertising -bool false
user_defaults write com.apple.AdLib forceLimitAdTracking -bool true
# ----------------------------------------------------------


# ----------------------------------------------------------
# --Disable automatic storage of documents in iCloud Drive--
# ----------------------------------------------------------
echo '--- Disable automatic storage of documents in iCloud Drive'
user_defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
# ----------------------------------------------------------


# ----------------------------------------------------------
# ---------------Disable remote Apple events----------------
# ----------------------------------------------------------
echo '--- Disable remote Apple events'
sudo systemsetup -setremoteappleevents off
# ----------------------------------------------------------


# ----------------------------------------------------------
# -------------Disable online spell correction--------------
# ----------------------------------------------------------
echo '--- Disable online spell correction'
user_defaults write NSGlobalDomain WebAutomaticSpellingCorrectionEnabled -bool false
# ----------------------------------------------------------


echo 'Your privacy and security is now hardened 🎉💪'
echo 'Press any key to exit.'
read -n 1 -s
