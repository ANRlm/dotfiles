#!/bin/bash

set -Eeuo pipefail
IFS=$'\n\t'

# ──────────────────────────────────────────────────
# Colors & logging
# ──────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
section() { echo -e "\n${YELLOW}── $* ──${NC}"; }
die() {
	echo -e "${RED}[✗]${NC} $*" >&2
	exit 1
}

trap 'die "Error on line $LINENO"' ERR

find_brew() {
	local candidate

	if command -v brew &>/dev/null; then
		command -v brew
		return 0
	fi

	for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
		if [[ -x "$candidate" ]]; then
			echo "$candidate"
			return 0
		fi
	done

	return 1
}

setup_homebrew_env() {
	local brew_path

	brew_path="$(find_brew)" || return 1
	eval "$("$brew_path" shellenv)"
}

get_login_shell() {
	local login_shell=""

	if command -v dscl &>/dev/null; then
		login_shell="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk -F ': ' '/^UserShell: / { print $2 }' || true)"
	fi

	printf '%s\n' "${login_shell:-${SHELL:-}}"
}
# ──────────────────────────────────────────────────
# Preparation
# ──────────────────────────────────────────────────
section "Preparation"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$HOME/.config"

info "Dotfiles: $DOTFILES_DIR"
info "Config:   $CONFIG_DIR"

mkdir -p "$CONFIG_DIR"
touch "$HOME/.hushlogin"
# ──────────────────────────────────────────────────
# Functions
# ──────────────────────────────────────────────────
link_dir() {
	local src="$1" dst="$2"
	[[ -d "$src" ]] || die "Missing source dir: $src"
	mkdir -p "$(dirname "$dst")"
	if [[ -L "$dst" ]]; then
		rm "$dst"
	elif [[ -e "$dst" ]]; then
		warn "$dst exists and is not a symlink, refusing to replace it"
		return 1
	fi
	ln -s "$src" "$dst"
	info "Linked dir  $dst → $src"
}

link_file() {
	local src="$1" dst="$2"
	[[ -f "$src" ]] || die "Missing source file: $src"
	mkdir -p "$(dirname "$dst")"
	if [[ -L "$dst" ]]; then
		rm "$dst"
	elif [[ -e "$dst" ]]; then
		warn "$dst exists and is not a symlink, refusing to replace it"
		return 1
	fi
	ln -s "$src" "$dst"
	info "Linked file $dst → $src"
}
# ──────────────────────────────────────────────────
# Config dirs
# ──────────────────────────────────────────────────
section "Config dirs"

for dir in bat btop claude conda fish ghostty git lazygit nvim starship tmux yazi; do
	link_dir "$DOTFILES_DIR/$dir" "$CONFIG_DIR/$dir"
done
# ──────────────────────────────────────────────────
# Claude
# ──────────────────────────────────────────────────
section "Claude"

link_file "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
# ──────────────────────────────────────────────────
# Brew bundle
# ──────────────────────────────────────────────────
section "Brew bundle"

setup_homebrew_env || die "Homebrew not found. Install Homebrew first or run scripts/setup.sh"
brew bundle --file="$DOTFILES_DIR/Brewfile"
# ──────────────────────────────────────────────────
# Fish plugins
# ──────────────────────────────────────────────────
section "Fish plugins"

FISH_PATH="$(command -v fish 2>/dev/null || true)"
[[ -n "$FISH_PATH" ]] || die "fish not found after Brew bundle"

FISH_PLUGINS_FILE="$DOTFILES_DIR/fish/fish_plugins"
[[ -f "$FISH_PLUGINS_FILE" ]] || die "Missing Fish plugin manifest: $FISH_PLUGINS_FILE"

restore_fish_plugins_manifest() {
	local snapshot="${FISH_PLUGINS_SNAPSHOT:-}"
	local manifest="${FISH_PLUGINS_FILE:-}"
	local snapshot_ready="${FISH_PLUGINS_SNAPSHOT_READY:-0}"

	[[ -n "$snapshot" && -n "$manifest" && -f "$snapshot" ]] || return 0
	if [[ "$snapshot_ready" == "1" ]]; then
		cp "$snapshot" "$manifest" || return 1
	fi
	rm -f "$snapshot"
}

FISH_PLUGINS_SNAPSHOT="$(mktemp)"
FISH_PLUGINS_SNAPSHOT_READY=0
trap 'restore_fish_plugins_manifest || true' EXIT
if ! cp "$FISH_PLUGINS_FILE" "$FISH_PLUGINS_SNAPSHOT"; then
	die "Unable to snapshot Fish plugin manifest"
fi
FISH_PLUGINS_SNAPSHOT_READY=1

if ! FISH_PLUGINS_SNAPSHOT="$FISH_PLUGINS_SNAPSHOT" "$FISH_PATH" -c '
set -l desired_plugins
while read -l plugin
    set plugin (string trim -- "$plugin")
    test -n "$plugin"; or continue
    string match --quiet -- "#*" "$plugin"; and continue
    contains -- "$plugin" $desired_plugins; or set --append desired_plugins "$plugin"
end <"$FISH_PLUGINS_SNAPSHOT"

if not set --query desired_plugins[1]
    echo "restore: Fish plugin manifest is empty" >&2
    exit 1
end

if not type -q fisher
    curl --fail --silent --show-error --location --connect-timeout 10 --max-time 60 --retry 2 \
        https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    set -l bootstrap_status $pipestatus
    for code in $bootstrap_status
        if test "$code" -ne 0
            echo "restore: Unable to bootstrap Fisher" >&2
            exit 1
        end
    end
end
type -q fisher; or begin
    echo "restore: Fisher is unavailable after bootstrap" >&2
    exit 1
end

set -l desired_normalized
for plugin in $desired_plugins
    set --append desired_normalized (string lower -- "$plugin")
    set -l synced 0

    for attempt in 1 2 3
        set -l action install
        contains -- (string lower -- "$plugin") (fisher list); and set action update

        set -l output (fisher "$action" "$plugin" 2>&1)
        set -l command_status $status
        test (count $output) -eq 0; or printf "%s\n" $output

        if test $command_status -eq 0
            and not string match --quiet --ignore-case --regex "fisher:" $output ""
            and contains -- (string lower -- "$plugin") (fisher list)
            set synced 1
            break
        end

        if test $attempt -lt 3
            echo "restore: Retrying Fisher $action for $plugin ($attempt/3)" >&2
            sleep 1
        end
    end

    if test $synced -ne 1
        echo "restore: Failed to synchronize Fish plugin: $plugin" >&2
        exit 1
    end
end

for plugin in (fisher list)
    contains -- (string lower -- "$plugin") $desired_normalized; and continue

    set -l output (fisher remove "$plugin" 2>&1)
    set -l command_status $status
    test (count $output) -eq 0; or printf "%s\n" $output
    if test $command_status -ne 0; or string match --quiet --ignore-case --regex "fisher:" $output ""
        echo "restore: Failed to remove undeclared Fish plugin: $plugin" >&2
        exit 1
    end
end

for plugin in $desired_normalized
    contains -- "$plugin" (fisher list); or begin
        echo "restore: Fish plugin verification failed: $plugin" >&2
        exit 1
    end
end
'; then
	die "Fish plugin synchronization failed"
fi

if ! restore_fish_plugins_manifest; then
	die "Unable to restore Fish plugin manifest"
fi
trap - EXIT

info "Fish plugins installed"
# ──────────────────────────────────────────────────
# TPM
# ──────────────────────────────────────────────────
section "TPM"

TPM_DIR="$CONFIG_DIR/tmux/plugins/tpm"

if [[ -d "$TPM_DIR" ]]; then
	info "TPM already installed, skipping"
else
	git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
	info "TPM installed"
fi

info "Installing tmux plugins..."
bash "$TPM_DIR/bin/install_plugins"
info "Tmux plugins installed"
# ──────────────────────────────────────────────────
# Yazi plugins
# ──────────────────────────────────────────────────
section "Yazi plugins"

command -v ya &>/dev/null || die "ya not found after Brew bundle"
ya pkg install
info "Yazi plugins installed"
# ──────────────────────────────────────────────────
# Default shell → fish
# ──────────────────────────────────────────────────
section "Default shell"

if ! grep -qxF "$FISH_PATH" /etc/shells; then
	echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
	info "Added $FISH_PATH to /etc/shells"
fi

CURRENT_SHELL="$(get_login_shell)"

if [[ "$CURRENT_SHELL" == "$FISH_PATH" ]]; then
	info "fish is already the default shell"
else
	chsh -s "$FISH_PATH"
	info "Default shell set to $FISH_PATH"
fi
# ──────────────────────────────────────────────────
# Cargo packages
# ──────────────────────────────────────────────────
section "Cargo packages"

if ! command -v cargo &>/dev/null; then
	warn "cargo not found in PATH, skipping cargo installs"
else
	INSTALLED_CARGO_PACKAGES="$(cargo install --list)"
	for pkg in cargo-cache cargo-update; do
		if grep -q "^${pkg} " <<<"$INSTALLED_CARGO_PACKAGES"; then
			info "$pkg is already installed, skipping"
		else
			cargo install "$pkg"
			info "Installed $pkg"
		fi
	done
fi

echo -e "\n${GREEN}Dotfiles restored successfully!${NC}"
