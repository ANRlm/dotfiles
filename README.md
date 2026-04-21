# dotfiles

基于软链接管理的 macOS 个人配置文件。

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
| 键位映射 | Karabiner-Elements |
| 包管理 | Homebrew + pnpm + uv |

## 目录结构

```
dotfiles/
├── fish/        # Fish shell 配置
├── nvim/        # Neovim 配置 (AstroNvim)
├── tmux/        # tmux 配置
├── ghostty/     # Ghostty 终端配置
├── git/         # Git 配置
├── yazi/        # yazi 文件管理器配置
├── aerospace/   # AeroSpace 窗口管理配置
├── karabiner/   # Karabiner 键位配置
├── scripts/     # 安装与恢复脚本
└── Brewfile     # Homebrew 软件包列表
```

## 安装

**全新机器**（包含 SSH、Homebrew、克隆仓库等完整流程）：

```sh
bash scripts/setup.sh
```

**已有机器**（仅恢复软链接和安装软件包）：

```sh
bash scripts/restore.sh
```

`restore.sh` 会将各配置目录软链接到 `~/.config/`，安装 Brewfile 中的所有软件包，并将默认 Shell 切换为 Fish。

## 更新

```fish
u
```

一键更新所有内容：Homebrew、Neovim 插件、语言工具链、Shell 插件等。
