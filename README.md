# dotfiles

基于软链接管理的 macOS 个人配置文件。

## 分支说明

这个仓库按使用场景拆成两个长期分支：

| 分支 | 用途 | Shell | 说明 |
|------|------|-------|------|
| `main` | macOS 桌面环境 | Fish | 包含 Ghostty、AeroSpace、Karabiner、Homebrew cask/mas 等桌面配置 |
| `Linux` | Linux 服务器 / TUI 环境 | zsh | 只保留 CLI/TUI 配置，使用 Homebrew/Linuxbrew 管理工具，不包含 macOS 桌面配置 |

Linux 服务器使用 `Linux` 分支：

```sh
git clone --branch Linux git@github.com:ANRlm/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash scripts/restore.sh
```

## 工具栈

| 类别 | 工具 |
|------|------|
| Shell | Fish + Starship |
| 终端 | Ghostty + tmux |
| 编辑器 | Neovim (AstroNvim) |
| Git | lazygit + delta |
| 文件管理 | yazi + eza + fd |
| 搜索 | fzf + ripgrep |
| 系统工具 | btop + bat |
| 窗口管理 | AeroSpace |
| 键位映射 | Karabiner-Elements |
| 包/环境管理 | Homebrew + pnpm + uv + Conda |

## 目录结构

```text
dotfiles/
├── aerospace/   # AeroSpace 窗口管理配置
├── bat/         # bat 语法高亮配置
├── btop/        # btop 系统监控配置
├── claude/      # Claude Code AI 助手配置
├── conda/       # Conda (Miniforge) 环境配置
├── fish/        # Fish shell 配置
├── ghostty/     # Ghostty 终端配置
├── git/         # Git 配置
├── karabiner/   # Karabiner 键位配置
├── lazygit/     # lazygit 配置
├── nvim/        # Neovim 配置 (AstroNvim)
├── starship/    # Starship 终端提示符配置
├── tmux/        # tmux 配置
├── yazi/        # yazi 文件管理器配置
├── scripts/     # 安装与恢复脚本
└── Brewfile     # Homebrew 软件包列表
```

## 安装

**全新 macOS 机器**（包含 SSH、Homebrew、克隆仓库等完整流程）：

```sh
bash scripts/setup.sh
```

**已有 macOS 机器**（仅恢复软链接和安装软件包）：

```sh
bash scripts/restore.sh
```

`restore.sh` 会将各配置目录软链接到 `~/.config/`，安装 Brewfile 中的所有软件包，并将默认 Shell 切换为 Fish。

## 更新

```fish
u
```

一键更新所有内容：Homebrew、Neovim 插件、语言工具链、Shell 插件等。
