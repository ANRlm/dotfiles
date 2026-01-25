set -g fish_greeting ""

# Environment Variables
set -gx EDITOR nvim

# PATH Configuration (Global)
# Use fish_add_path which handles duplicates automatically
fish_add_path -g "/usr/local/share/dotnet"

# Tool Initializations (Global/Conditional)
# Conda
if test -f /opt/miniforge/bin/conda
    eval /opt/miniforge/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/opt/miniforge/etc/fish/conf.d/conda.fish"
        . "/opt/miniforge/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/opt/miniforge/bin" $PATH
    end
end

function clean
    sudo find /var/cache/pacman/pkg/ -name 'download-*' -type d -delete 2>/dev/null

    echo "y" | sudo paru -Sc
    echo "y" | paru -c

    echo -e "y\ny" | sudo pacman -Scc

    sudo journalctl --vacuum-time=7d

    for dir in ~/.cache/{paru,yay,pip,go-build,yarn,npm}
        if test -d $dir
            rm -rf $dir
        end
    end

    set orphans (pacman -Qtdq 2>/dev/null)
    if test -n "$orphans"
        sudo pacman -Rns $orphans --noconfirm
    end

    command -v npm >/dev/null; and npm cache clean --force 2>/dev/null
    command -v cargo >/dev/null; and cargo cache -a 2>/dev/null

    sudo find /etc -name '*.pacsave' -o -name '*.pacnew' 2>/dev/null | head -5

    rm -rf ~/.local/share/Trash/*
end

# Interactive Configuration
if status is-interactive
    # zoxide
    if type -q zoxide
        zoxide init fish --cmd cd | source
    end
    
    # Theme
    fish_config theme choose "Catppuccin Mocha"

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
    set -gx FZF_DEFAULT_COMMAND 'rg --files --hidden --follow --glob "!.git/*"'

    set -gx fzf_preview_dir_cmd eza --all --color=always
    set -gx fzf_preview_file_cmd bat -n
    set fzf_diff_highlighter delta --paging=never --features="mellow-barbet" --syntax-theme="rose-pine"
    set fzf_history_time_format %d-%m-%y

    # Bat
    if not test -d ~/.cache/bat
        bat cache --build 2>/dev/null
    end
end
