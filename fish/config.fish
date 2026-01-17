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

# PATH Configuration (Global)
# Use fish_add_path which handles duplicates automatically
fish_add_path -g "/opt/homebrew/opt/make/libexec/gnubin"
fish_add_path -g "/usr/local/share/dotnet"
fish_add_path -g "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
fish_add_path -g "$HOME/.lmstudio/bin"
fish_add_path -g "/opt/homebrew/opt/openjdk/bin"
fish_add_path -g "/opt/homebrew/opt/llvm/bin"
fish_add_path -g "$HOME/.antigravity/antigravity/bin"
fish_add_path -g "$CONDA_ROOT/bin"

# Tool Initializations (Global/Conditional)
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

# Interactive Configuration
if status is-interactive
    # zoxide
    if type -q zoxide
        zoxide init fish --cmd cd | source
    end
    
    # Theme
    fish_config theme choose "Rosé Pine"

    # Starship
    if command -q starship
        starship init fish | source
    end

    # Abbreviations (Preferred over aliases for expansion)
    # General
    abbr -a c clear
    abbr -a s 'exec fish'
    abbr -a py python
    abbr -a ip 'ipconfig getifaddr en0'
    abbr -a ports 'lsof -i -P | grep -i "listen"'
    abbr -a disk 'smartctl -a disk3'
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
    abbr -a lg lazygit

    # Tmux
    abbr -a ts 'tmux source-file ~/.config/tmux/tmux.conf'
    abbr -a tls 'tmux ls'
    abbr -a tn 'tmux new -s'
    abbr -a tk 'tmux kill-session -t'
    abbr -a ta 'tmux attach'

    # Conda
    abbr -a cel 'conda env list'
    abbr -a ci 'conda install'
    abbr -a cui 'conda remove'
    abbr -a cu 'conda update --all'
    abbr -a cs 'conda search'
    abbr -a cl 'conda list'
    abbr -a cc 'conda clean --all -y'
    abbr -a ca 'conda activate'
    abbr -a cde 'conda deactivate'

    # Tools
    abbr -a mf musicfox

    # Aliases
    # Use alias for things where you want to shadow a command or it's not just a shortcut
    alias el 'eza --long --header --icons --git --all'
    alias et 'eza --tree --level=2 --long --header --icons --git'
    alias df 'df -h'

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
    set -gx FZF_DEFAULT_OPTS '--style full --preview "fzf-preview.sh {}" --bind "focus:transform-header:file --brief {}"'
    
    function fzd
        set -l dir (find * -type d | fzf)
        if test -n "$dir"
            cd "$dir"
        end
    end

    function fzh
        history | fzf
    end

    function vzf
        set -l file (fzf)
        if test -n "$file"
            nvim "$file"
        end
    end

    function fzb
        set -l branch (git branch | fzf | string trim)
        if test -n "$branch"
            git checkout "$branch"
        end
    end

    function fzp
        ps aux | fzf
    end
end
