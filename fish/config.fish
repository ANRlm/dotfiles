# ── Core Environment ──────────────────────────────────────────────────

set -g fish_greeting ""
set -gx EDITOR hx
set -gx STARSHIP_CONFIG $HOME/.config/starship/starship.toml

# ── Homebrew ──────────────────────────────────────────────────────────

set -gx HOMEBREW_NO_AUTO_UPDATE 1

if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
end

# ── PATH ──────────────────────────────────────────────────────────────

set -gx PNPM_HOME $HOME/Library/pnpm
set -l extra_paths "$PNPM_HOME/bin"

set -l jdk /opt/homebrew/opt/openjdk@17
if test -d $jdk/libexec/openjdk.jdk/Contents/Home
    set -gx JAVA_HOME $jdk/libexec/openjdk.jdk/Contents/Home
    set -a extra_paths $jdk/bin
end

fish_add_path -g $extra_paths
fish_add_path --move --prepend --path "$HOME/.local/bin" /opt/homebrew/bin /usr/local/bin

# ── Agents ────────────────────────────────────────────────────────────

set -e CLAUDE_CONFIG_DIR
set -e GROK_HOME

if set -q CLAUDECODE; or set -q CODEX_THREAD_ID
    set -gx OP_SERVICE_ACCOUNT_TOKEN (security find-generic-password -a "$USER" -s op-service-account -w 2>/dev/null)
end

set -gx PONYTAIL_HIDE_STATUS 1

if not status is-interactive
    return
end

# ── Interactive Integrations ──────────────────────────────────────────

if command -q mise
    mise activate fish | source
end

if test -f ~/.orbstack/shell/init2.fish
    source ~/.orbstack/shell/init2.fish 2>/dev/null
end

if command -q zoxide
    zoxide init fish --cmd cd | source
end

if command -q starship
    starship init fish --print-full-init | source
end

# ── Abbreviations: General ────────────────────────────────────────────

abbr -a c clear
abbr -a s 'exec fish'
abbr -a lg lazygit
abbr -a copy pbcopy
abbr -a ip 'ipconfig getifaddr en0'
abbr -a ports 'lsof -nP -iTCP -sTCP:LISTEN'

# ── Abbreviations: Agents ─────────────────────────────────────────────

abbr -a claude 'claude --allow-dangerously-skip-permissions'

# ── Abbreviations: Homebrew ───────────────────────────────────────────

abbr -a bi 'brew install'
abbr -a bri 'brew reinstall'
abbr -a bui 'brew uninstall --zap'
abbr -a bs 'brew search'
abbr -a bif 'brew info'
abbr -a bl 'brew leaves; and brew list --cask'
abbr -a bd 'brew deps --installed --tree'
abbr -a bu 'brew update; and brew upgrade'
abbr -a bc 'brew autoremove; and brew cleanup --prune=all'

# ── Abbreviations: Eza ────────────────────────────────────────────────

abbr -a el 'eza --long --header --icons --git --all'
abbr -a et 'eza --tree --level=2 --long --header --icons --git'

# ── FZF ───────────────────────────────────────────────────────────────

set -gx FZF_DEFAULT_OPTS --height=75% --layout=reverse --border --info=inline

set -gx FZF_CTRL_T_COMMAND "fd --type=file --hidden --follow --exclude=.git"
set -gx FZF_CTRL_T_OPTS "--preview='bat --style=numbers --color=always --line-range=:500 {}'"
set -gx FZF_ALT_C_COMMAND "fd --type=directory --hidden --follow --exclude=.git"
set -gx FZF_ALT_C_OPTS "--preview='eza --all --color=always --icons --git --tree --level=2 {}'"

if command -q fzf
    fzf --fish | source
end

function fish_user_key_bindings
    bind \cg ripgrep_search
end
