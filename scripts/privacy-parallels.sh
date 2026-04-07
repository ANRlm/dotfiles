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
# Disable automatic downloads for Parallels Desktop updates-
# ----------------------------------------------------------
echo '--- Disable automatic downloads for Parallels Desktop updates'
user_defaults write 'com.parallels.Parallels Desktop' 'Application preferences.Download updates automatically' -bool no
# ----------------------------------------------------------

# ----------------------------------------------------------
# --Disable automatic checks for Parallels Desktop updates--
# ----------------------------------------------------------
echo '--- Disable automatic checks for Parallels Desktop updates'
user_defaults write 'com.parallels.Parallels Desktop' 'Application preferences.Check for updates' -int 0
# ----------------------------------------------------------

# ----------------------------------------------------------
# ---------Disable Parallels Desktop advertisements---------
# ----------------------------------------------------------
echo '--- Disable Parallels Desktop advertisements'
user_defaults write 'com.parallels.Parallels Desktop' 'ProductPromo.ForcePromoOff' -bool yes
user_defaults write 'com.parallels.Parallels Desktop' 'WelcomeScreenPromo.PromoOff' -bool yes
# ----------------------------------------------------------

echo 'Your privacy and security is now hardened 🎉💪'
echo 'Press any key to exit.'
read -n 1 -s
