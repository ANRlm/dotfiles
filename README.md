# dotfiles

基于软链接管理的 macOS 个人配置。

## 工具栈

| 类别 | 工具 |
|------|------|
| Shell | Fish + Starship |
| 终端 | Ghostty + tmux |
| 编辑器 | Neovim (AstroNvim) |
| Git | lazygit + delta |
| 文件管理 | yazi + eza + fd |
| 搜索 | fzf + ripgrep |
| 窗口管理 | AeroSpace |
| 包管理 | Homebrew + pnpm + bun + uv |

## 使用

新机器初始化：

```sh
bash scripts/setup.sh
```

已有机器恢复软链接和包：

```sh
bash scripts/restore.sh
```

## 更新

```fish
u
```

一条命令更新所有内容：Homebrew、Neovim 插件、各语言工具链、Shell 插件等。
