set -g fish_greeting ""

# ── Core Environment ──────────────────────────────────────────────────

set -gx EDITOR nvim

set -gx STARSHIP_CONFIG $HOME/.config/starship/starship.toml
set -gx PNPM_HOME $HOME/Library/pnpm
set -gx CLAUDE_CONFIG_DIR $HOME/.claude

# ── Homebrew ──────────────────────────────────────────────────────────

set -gx HOMEBREW_NO_AUTO_UPDATE 1

if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv fish | source
end

# ── PATH ──────────────────────────────────────────────────────────────

set -l extra_paths "$HOME/.local/bin" "$PNPM_HOME/bin"

set -l jdk /opt/homebrew/opt/openjdk@17
if test -d $jdk/libexec/openjdk.jdk/Contents/Home
    set -gx JAVA_HOME $jdk/libexec/openjdk.jdk/Contents/Home
    set -a extra_paths $jdk/bin
end

fish_add_path -g $extra_paths

if not status is-interactive
    return
end

# ── Interactive Integrations ──────────────────────────────────────────

if command -q fnm
    fnm env --use-on-cd --corepack-enabled --version-file-strategy recursive --resolve-engines=false --log-level quiet --shell fish | source
end

if test -f ~/.orbstack/shell/init2.fish
    source ~/.orbstack/shell/init2.fish 2>/dev/null
end

if type -q zoxide
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
abbr -a ports 'lsof -i -P | grep -i "listen"'

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

# ── Abbreviations: Tmux ───────────────────────────────────────────────

abbr -a ts 'tmux source-file ~/.config/tmux/tmux.conf'
abbr -a tls 'tmux ls'
abbr -a tn 'tmux new -s'
abbr -a tk 'tmux kill-session -t'
abbr -a ta 'tmux attach'
abbr -a trw 'tmux rename-window'
abbr -a trs 'tmux rename-session'

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
