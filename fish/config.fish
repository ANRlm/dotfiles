set -g fish_greeting ""

# ── Core Environment ──────────────────────────────────────────────────

set -gx EDITOR nvim

set -gx CONDA_ROOT /opt/homebrew/Caskroom/miniforge/base
set -gx STARSHIP_CONFIG $HOME/.config/starship/starship.toml
set -gx NPM_CONFIG_USERCONFIG $HOME/.config/npm/npmrc
set -gx PNPM_HOME $HOME/Library/pnpm

# ── Tool Flags ────────────────────────────────────────────────────────

set -gx CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS 1
set -gx OMO_SEND_ANONYMOUS_TELEMETRY 0

# ── Homebrew ──────────────────────────────────────────────────────────

set -gx HOMEBREW_NO_AUTO_UPDATE 1
set -gx HOMEBREW_NO_ANALYTICS 1

if not set -q HOMEBREW_MAKE_JOBS
    set -l logical_cpu (sysctl -n hw.logicalcpu 2>/dev/null)
    if test -n "$logical_cpu"
        set -gx HOMEBREW_MAKE_JOBS $logical_cpu
    end
end

if test -x /opt/homebrew/bin/brew
    set -gx HOMEBREW_PREFIX /opt/homebrew
    set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
    set -gx HOMEBREW_REPOSITORY /opt/homebrew

    fish_add_path --global --move --path /opt/homebrew/bin /opt/homebrew/sbin

    if test -n "$MANPATH[1]"
        set -gx MANPATH '' $MANPATH
    end

    if not contains /opt/homebrew/share/info $INFOPATH
        set -gx INFOPATH /opt/homebrew/share/info $INFOPATH
    end
end

# ── PATH ──────────────────────────────────────────────────────────────

fish_add_path -g "$PNPM_HOME/bin"
fish_add_path -g "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# ── Lazy Conda ────────────────────────────────────────────────────────

function conda
    if not set -q CONDA_ROOT
        echo "lazyconda: \$CONDA_ROOT is not set" >&2
        return 1
    end

    set -l conda_argv $argv
    functions --erase conda

    if test -f $CONDA_ROOT/bin/conda
        eval $CONDA_ROOT/bin/conda shell.fish hook | source
        or return $status
    else if test -f $CONDA_ROOT/etc/fish/conf.d/conda.fish
        source $CONDA_ROOT/etc/fish/conf.d/conda.fish
        or return $status
    else
        fish_add_path -g $CONDA_ROOT/bin
    end

    conda $conda_argv
end

if not status is-interactive
    return
end

# ── Interactive Integrations ──────────────────────────────────────────

if test -f ~/.orbstack/shell/init.fish
    source ~/.orbstack/shell/init.fish 2>/dev/null
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
abbr -a v nvim
abbr -a lg lazygit
abbr -a py python
abbr -a ip 'ipconfig getifaddr en0'
abbr -a copy pbcopy
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

# ── Abbreviations: Conda ──────────────────────────────────────────────

abbr -a ca 'conda activate'
abbr -a cde 'conda deactivate'
abbr -a cel 'conda env list'
abbr -a ci 'conda install'
abbr -a cui 'conda remove'
abbr -a cs 'conda search'
abbr -a cl 'conda list'
abbr -a cc 'conda clean --all -y'
abbr -a cu 'conda update conda -y; and conda update --all -y'

# ── Abbreviations: Yazi ───────────────────────────────────────────────

abbr -a yau 'ya pkg upgrade'
abbr -a yaa 'ya pkg add'
abbr -a yad 'ya pkg delete'
abbr -a yal 'ya pkg list'

# ── Abbreviations: Eza ────────────────────────────────────────────────

abbr -a el 'eza --long --header --icons --git --all'
abbr -a et 'eza --tree --level=2 --long --header --icons --git'

# ── FZF ───────────────────────────────────────────────────────────────

set -gx FZF_DEFAULT_OPTS "\
    --height 75% \
    --layout=reverse \
    --border \
    --info=inline"

set -g fzf_fd_opts "--hidden --follow --exclude .git"
set -g fzf_preview_dir_cmd eza --all --color=always --icons --git --tree --level=2
set -g fzf_preview_file_cmd bat --style=numbers --color=always --line-range :500
set -g fzf_diff_highlighter "delta --paging=never --features='nord' --syntax-theme='Nord'"
set -g fzf_history_time_format %d-%m-%y

function fish_user_key_bindings
    fzf_configure_bindings --directory=\ct --history=\cr
    bind \cg ripgrep_search
end

# >>> otty shell integration >>>
# Added by Otty — toggle in Settings > Shell > Shell Integration.
# Inert unless launched by Otty (it sets $OTTY_SHELL_INTEGRATION).
if test -n "$OTTY_SHELL_INTEGRATION" -a -r "$OTTY_SHELL_INTEGRATION/otty-integration.fish"
    source "$OTTY_SHELL_INTEGRATION/otty-integration.fish"
end
# <<< otty shell integration <<<

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
