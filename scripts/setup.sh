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
# ──────────────────────────────────────────────────
# SSH
# ──────────────────────────────────────────────────
section "SSH"

SSH_OUTPUT=$(ssh -T git@github.com 2>&1 || true)

if echo "$SSH_OUTPUT" | grep -q "successfully authenticated"; then
	info "GitHub SSH 连接已配置且正常，跳过 SSH 设置"
else
	warn "GitHub SSH 尚未配置，开始设置..."

	# Generate key
	if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
		info "SSH key already exists, skipping generation"
	else
		ssh-keygen -t ed25519 -C "nai.ying.cnhyk@gmail.com"
		info "SSH key generated"
	fi

	# Start ssh-agent
	eval "$(ssh-agent -s)"
	info "ssh-agent started"

	# Add key to ssh-agent
	ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519"
	info "Key added to ssh-agent"

	# Configure ~/.ssh/config
	SSH_CONFIG="$HOME/.ssh/config"
	BLOCK="Host github.com
  HostName ssh.github.com
  Port 443
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519"

	touch "$SSH_CONFIG"

	if grep -q "Host github.com" "$SSH_CONFIG"; then
		info "GitHub config already exists in ~/.ssh/config, skipping"
	else
		echo "" >>"$SSH_CONFIG"
		echo "$BLOCK" >>"$SSH_CONFIG"
		info "GitHub config written to ~/.ssh/config"
	fi

	# Copy public key and wait for user
	pbcopy <"$HOME/.ssh/id_ed25519.pub"
	info "Public key copied to clipboard"

	echo ""
	open "https://github.com/settings/keys"
	echo -e "${YELLOW}已在浏览器中打开 GitHub SSH Keys 页面${NC}"
	echo -e "${YELLOW}点击 New SSH key，粘贴公钥，保存后回到此处按回车继续...${NC}"
	read -r || true

	# Test connection
	SSH_OUTPUT=$(ssh -T git@github.com 2>&1 || true)

	if echo "$SSH_OUTPUT" | grep -q "successfully authenticated"; then
		info "SSH 连接成功！"
	else
		die "SSH 连接失败：$SSH_OUTPUT"
	fi
fi
# ──────────────────────────────────────────────────
# Homebrew
# ──────────────────────────────────────────────────
section "Homebrew"

if command -v brew &>/dev/null; then
	info "Homebrew already installed, skipping"
else
	info "Installing Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	if [[ -f /opt/homebrew/bin/brew ]]; then
		eval "$(/opt/homebrew/bin/brew shellenv)"
	elif [[ -f /usr/local/bin/brew ]]; then
		eval "$(/usr/local/bin/brew shellenv)"
	fi

	info "Homebrew installed"
fi

brew update
# ──────────────────────────────────────────────────
# Git
# ──────────────────────────────────────────────────
section "Git"

if command -v git &>/dev/null; then
	info "git already installed ($(git --version)), skipping"
else
	brew install git
	info "git installed"
fi
# ──────────────────────────────────────────────────
# Clone dotfiles
# ──────────────────────────────────────────────────
section "Dotfiles"

DOTFILES_DIR="$HOME/dotfiles"

if [[ -d "$DOTFILES_DIR" ]]; then
	info "Dotfiles already exist at $DOTFILES_DIR, skipping"
else
	git clone git@github.com:ANRlm/dotfiles.git "$DOTFILES_DIR"
	info "Cloned dotfiles to $DOTFILES_DIR"
fi
# ──────────────────────────────────────────────────
# Restore
# ──────────────────────────────────────────────────
section "Restore"

RESTORE_SCRIPT="$DOTFILES_DIR/scripts/restore.sh"

[[ -f "$RESTORE_SCRIPT" ]] || die "restore.sh not found at $RESTORE_SCRIPT"

bash "$RESTORE_SCRIPT"
