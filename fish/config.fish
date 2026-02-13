set -g fish_greeting ""

# Environment Variables
set -gx EDITOR nvim
set -gx HOMEBREW_API_DOMAIN "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
set -gx HOMEBREW_BOTTLE_DOMAIN "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
set -gx HOMEBREW_BREW_GIT_REMOTE "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
set -gx HOMEBREW_CORE_GIT_REMOTE "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
set -gx HOMEBREW_NO_AUTO_UPDATE 1
set -gx HOMEBREW_NO_INSTALL_CLEANUP 0
set -gx HOMEBREW_NO_ANALYTICS 1
set -gx HOMEBREW_NO_ENV_HINTS 0
set -gx HOMEBREW_MAKE_JOBS (sysctl -n hw.logicalcpu)
set -gx CONDA_ROOT "/opt/homebrew/Caskroom/miniforge/base"

# PATH Configuration
fish_add_path "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
fish_add_path "/opt/homebrew/opt/openjdk/bin"
fish_add_path "$HOME/.antigravity/antigravity/bin"
fish_add_path "/opt/homebrew/opt/rustup/bin"

# Interactive Configuration
if status is-interactive
    # Homebrew
    if test -x /opt/homebrew/bin/brew
        /opt/homebrew/bin/brew shellenv | source
    end

    # OrbStack
    if test -f ~/.orbstack/shell/init.fish
        source ~/.orbstack/shell/init.fish 2>/dev/null
    end

    # Conda
    if test -f "$CONDA_ROOT/bin/conda"
        eval "$CONDA_ROOT/bin/conda" "shell.fish" "hook" $argv | source
    else
        if test -f "$CONDA_ROOT/etc/fish/conf.d/conda.fish"
            source "$CONDA_ROOT/etc/fish/conf.d/conda.fish"
        else
            fish_add_path -g "$CONDA_ROOT/bin"
        end
    end

    # zoxide
    if type -q zoxide
        zoxide init fish --cmd cd | source
    end
    
    # Theme
    fish_config theme choose "ayu"

    # Starship
    if command -q starship
        starship init fish | source
    end

    # Abbreviations
    # General
    abbr -a c 'clear'
    abbr -a s 'exec fish'
    abbr -a ip 'ipconfig getifaddr en0'
    abbr -a ports 'lsof -i -P | grep -i "listen"'
    abbr -a df 'df -h'

    abbr -a disk 'smartctl -a disk3'
    abbr -a mf 'musicfox'
    abbr -a py 'python'
    abbr -a v 'nvim'

    abbr -a u \
    'brew update; and \
     brew upgrade; and \
     brew upgrade --cask --greedy; and \
     brew autoremove; and brew cleanup --prune=all; and \
     brew bundle dump --force --file ~/dotfiles/Brewfile; and \
     conda update conda -y; and \
     conda update --all -y; and \
     conda clean --all -y; and \
     ya pkg upgrade; and \
     fisher update; and \
     npm update -g; and \
     npm cache clean --force; and \
     pnpm update -g; and \
     pnpm store prune; and \
     mas update; and \
     fish -c "cd ~/dotfiles/oh-my-tmux/ && git pull"; and \
     rustup update; and \
     pnpm store prune; and \
     mo clean; and \
     mo purge'

    # Xcode
    abbr -a xcode-clt 'sudo xcode-select -s /Library/Developer/CommandLineTools'
    abbr -a xcode-app 'sudo xcode-select -s /Applications/Xcode.app/Contents/Developer'

    # Homebrew
    abbr -a bi 'brew install'
    abbr -a bri 'brew reinstall'
    abbr -a bui 'brew uninstall --zap'
    abbr -a bs 'brew search'
    abbr -a bif 'brew info'
    abbr -a bu 'brew update; and brew upgrade; and brew upgrade --cask --greedy'
    abbr -a bc 'brew autoremove; and brew cleanup --prune=all'
    abbr -a bl 'brew leaves; and brew list --cask'
    abbr -a bd 'brew deps --installed --tree'

    # Git
    abbr -a gs 'git status'
    abbr -a ga 'git add'
    abbr -a gc 'git commit -m'
    abbr -a gp 'git push'
    abbr -a gpl 'git pull'
    abbr -a gd 'git diff'
    abbr -a glg 'git log --oneline --graph --all'
    abbr -a lg 'lazygit'

    # Tmux
    abbr -a ts 'tmux source-file ~/.config/tmux/tmux.conf'
    abbr -a tls 'tmux ls'
    abbr -a tn 'tmux new -s'
    abbr -a tk 'tmux kill-session -t'
    abbr -a ta 'tmux attach'
    abbr -a trw 'tmux rename-window'
    abbr -a trs 'tmux rename-session'

    # Conda
    abbr -a cel 'conda env list'
    abbr -a ci 'conda install'
    abbr -a cui 'conda remove'
    abbr -a cu 'conda update conda -y; and conda update --all -y'
    abbr -a cs 'conda search'
    abbr -a cl 'conda list'
    abbr -a cc 'conda clean --all -y'
    abbr -a ca 'conda activate'
    abbr -a cde 'conda deactivate'

    # Yazi
    abbr -a yau 'ya pkg upgrade'
    abbr -a yaa 'ya pkg add'
    abbr -a yad 'ya pkg delete'
    abbr -a yal 'ya pkg list'

    # Eza
    abbr -a el 'eza --long --header --icons --git --all'
    abbr -a et 'eza --tree --level=2 --long --header --icons --git'

    # Yazi 
    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        command yazi $argv --cwd-file="$tmp"
        if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end

    # FZF
    set -Ux FZF_DEFAULT_OPTS "\
    --height 75% \
    --layout=reverse \
    --border \
    --info=inline"

    set -g fzf_fd_opts --hidden --follow --exclude .git
    # fzf_configure_bindings --directory=\ct --history=\cr
    set -g fzf_preview_dir_cmd eza --all --color=always --icons --git --tree --level=2
    set -g fzf_preview_file_cmd bat --style=numbers --color=always --line-range :500
    set -g fzf_diff_highlighter delta --paging=never --features="mellow-barbet" --syntax-theme="Catppuccin Mocha"
    set -g fzf_history_time_format %d-%m-%y

    bind \cg ripgrep_search

    # Bat
    if not test -d ~/.cache/bat
        bat cache --build 2>/dev/null
    end

    # Mole
    set -l output (mole completion fish 2>/dev/null); and echo "$output" | source
end
