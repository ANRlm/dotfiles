set -g fish_greeting ""

# ── Environment Variables
set -gx EDITOR nvim
set -gx CONDA_ROOT /opt/homebrew/Caskroom/miniforge/base
set -gx STARSHIP_CONFIG "$HOME/.config/starship/starship.toml"
set -gx NPM_CONFIG_USERCONFIG ~/.config/npm/npmrc
set -gx OMO_SEND_ANONYMOUS_TELEMETRY 0
set -gx CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS 1
set -gx BUN_INSTALL "$HOME/.bun"

# ── Homebrew
set -gx HOMEBREW_NO_AUTO_UPDATE 1
set -gx HOMEBREW_NO_ANALYTICS 1
set -gx HOMEBREW_MAKE_JOBS (sysctl -n hw.logicalcpu)

# ── PATH
fish_add_path -g "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
fish_add_path -g /opt/homebrew/opt/openjdk/bin
fish_add_path -g /opt/homebrew/opt/rustup/bin
fish_add_path -g "$BUN_INSTALL/bin"

# ── Homebrew Shell Environment
if test -x /opt/homebrew/bin/brew
    /opt/homebrew/bin/brew shellenv | source
end

# ── Conda
function conda
    if not set -q CONDA_ROOT
        echo "lazyconda: \$CONDA_ROOT is not set" >&2
        return 1
    end

    if test -f "$CONDA_ROOT/bin/conda"
        eval "$CONDA_ROOT/bin/conda" "shell.fish" hook | source
        or return $status
    else if test -f "$CONDA_ROOT/etc/fish/conf.d/conda.fish"
        source "$CONDA_ROOT/etc/fish/conf.d/conda.fish"
        or return $status
    else
        fish_add_path -g "$CONDA_ROOT/bin"
        functions --erase conda
    end

    conda $argv
end

# ── Interactive
if status is-interactive

    # OrbStack
    if test -f ~/.orbstack/shell/init.fish
        source ~/.orbstack/shell/init.fish 2>/dev/null
    end

    # zoxide
    if type -q zoxide
        zoxide init fish --cmd cd | source
    end

    # Starship
    if command -q starship
        starship init fish | source
    end

    # Theme
    fish_config theme choose "Rosé Pine"

    # ── Abbreviations

    # General
    abbr -a c clear
    abbr -a s 'exec fish'
    abbr -a v nvim
    abbr -a lg lazygit
    abbr -a py python
    abbr -a ip 'ipconfig getifaddr en0'
    abbr -a disk 'smartctl -a disk3'
    abbr -a copy pbcopy
    abbr -a ports 'lsof -i -P | grep -i "listen"'

    # Xcode
    abbr -a xcode-clt 'sudo xcode-select -s /Library/Developer/CommandLineTools'
    abbr -a xcode-app 'sudo xcode-select -s /Applications/Xcode.app/Contents/Developer'

    # Homebrew
    abbr -a bi 'brew install'
    abbr -a bri 'brew reinstall'
    abbr -a bui 'brew uninstall --zap'
    abbr -a bs 'brew search'
    abbr -a bif 'brew info'
    abbr -a bl 'brew leaves; and brew list --cask'
    abbr -a bd 'brew deps --installed --tree'
    abbr -a bu 'brew update; and brew upgrade'
    abbr -a bc 'brew autoremove; and brew cleanup --prune=all'

    # Tmux
    abbr -a ts 'tmux source-file ~/.config/tmux/tmux.conf'
    abbr -a tls 'tmux ls'
    abbr -a tn 'tmux new -s'
    abbr -a tk 'tmux kill-session -t'
    abbr -a ta 'tmux attach'
    abbr -a trw 'tmux rename-window'
    abbr -a trs 'tmux rename-session'

    # Conda
    abbr -a ca 'conda activate'
    abbr -a cde 'conda deactivate'
    abbr -a cel 'conda env list'
    abbr -a ci 'conda install'
    abbr -a cui 'conda remove'
    abbr -a cs 'conda search'
    abbr -a cl 'conda list'
    abbr -a cc 'conda clean --all -y'
    abbr -a cu 'conda update conda -y; and conda update --all -y'

    # Yazi
    abbr -a yau 'ya pkg upgrade'
    abbr -a yaa 'ya pkg add'
    abbr -a yad 'ya pkg delete'
    abbr -a yal 'ya pkg list'

    # Eza
    abbr -a el 'eza --long --header --icons --git --all'
    abbr -a et 'eza --tree --level=2 --long --header --icons --git'

    # ── FZF
    set -gx FZF_DEFAULT_OPTS "\
    --height 75% \
    --layout=reverse \
    --border \
    --info=inline"

    set -g fzf_fd_opts "--hidden --follow --exclude .git"
    set -g fzf_preview_dir_cmd eza --all --color=always --icons --git --tree --level=2
    set -g fzf_preview_file_cmd bat --style=numbers --color=always --line-range :500
    set -g fzf_diff_highlighter "delta --paging=never --features='mellow-barbet' --syntax-theme='Catppuccin Mocha'"
    set -g fzf_history_time_format %d-%m-%y

    fzf_configure_bindings --directory=\ct --history=\cr
    bind \cg ripgrep_search

end
