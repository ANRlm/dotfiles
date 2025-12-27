# FZF 基础配置
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="
  --height 80%
  --layout=reverse
  --border
  --preview-window=right:60%
  --bind='ctrl-/:toggle-preview'
  --bind='ctrl-u:preview-page-up'
  --bind='ctrl-d:preview-page-down'
  --color=fg:#c0caf5,bg:#1a1b26,hl:#bb9af7
  --color=fg+:#c0caf5,bg+:#292e42,hl+:#7dcfff
  --color=info:#7aa2f7,prompt:#f7768e,pointer:#73daca
  --color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a"

# Ctrl+T - 文件/目录搜索
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
  --preview '([[ -f {} ]] && (bat --style=numbers --color=always {} 2>/dev/null || cat {})) || ([[ -d {} ]] && tree -C {} | head -200) || echo {}'"

# Alt+C - 目录跳转
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_ALT_C_OPTS="
  --preview 'tree -C {} | head -200'"

# Ctrl+R - 历史记录搜索
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window=down:3:hidden:wrap
  --bind='ctrl-/:toggle-preview'"

# 加载 fzf 的关键绑定和补全
[ -f /opt/homebrew/opt/fzf/shell/completion.zsh ] && source /opt/homebrew/opt/fzf/shell/completion.zsh
[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
