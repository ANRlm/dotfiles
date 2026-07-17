# dotfiles

面向 Apple Silicon macOS 的个人配置仓库。配置文件保存在 Git 中，并通过符号链接部署到 `$HOME` 与 `~/.config`。

## 支持范围

仓库按平台维护两个长期分支：

| 分支 | 平台 | Shell | 内容 |
| --- | --- | --- | --- |
| `main` | Apple Silicon macOS | Fish | 完整桌面配置 |
| [`Linux`](https://github.com/ANRlm/dotfiles/tree/Linux) | Linux 服务器与 TUI 环境 | Zsh | CLI/TUI 配置与 Homebrew/Linuxbrew，不包含 macOS 桌面组件 |

本文档描述 `main` 分支。Linux 的安装和恢复细节以 `Linux` 分支中的 README 为准。

## 工具栈

| 类别 | 工具 |
| --- | --- |
| Shell | Fish + Starship |
| 终端 | Ghostty + tmux |
| 编辑器 | Neovim + AstroNvim v6 |
| Git | lazygit + delta |
| 文件管理 | yazi + eza + fd |
| 搜索 | fzf + ripgrep |
| 系统工具 | btop + bat |
| 键位映射 | Karabiner-Elements + Goku |
| 包与环境管理 | Homebrew + pnpm + bun + uv + Conda |

## 安装

### 前置条件

- Apple Silicon Mac 和可用的网络连接。
- 可登录的 GitHub 账户；首次安装会引导添加 SSH 公钥。
- 管理员权限；设置 Fish 为登录 Shell 时可能需要 `sudo`。
- 如需安装 `Brewfile` 中的 MAS 应用，请先登录 Mac App Store。

### 全新 macOS

在终端运行远程引导脚本：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ANRlm/dotfiles/main/scripts/setup.sh)"
```

[`scripts/setup.sh`](scripts/setup.sh) 会交互式配置 GitHub SSH、安装
Homebrew 和 Git、将仓库克隆到 `~/dotfiles`，然后调用恢复脚本。

### 已有 macOS

Homebrew、Git 和 GitHub SSH 已可用时，克隆仓库并执行恢复：

```bash
git clone git@github.com:ANRlm/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash scripts/restore.sh
```

如果仓库已经位于 `~/dotfiles`，只需执行后两行。

### 恢复前注意

- `main` 分支的 [`scripts/restore.sh`](scripts/restore.sh) 没有 dry-run 模式。
- 目标位置已有普通文件或目录时，脚本会拒绝覆盖并退出；请先备份或迁移现有配置。
- 已有符号链接会被重新创建。
- 脚本按顺序执行且不会回滚；后续步骤失败时，之前的改动会保留。
- 准备阶段会创建或更新时间戳 `~/.hushlogin`。
- Fisher 会精确同步 `fish/fish_plugins`，并删除未在清单中声明的 Fish 插件。
- 脚本会安装软件和插件、生成 Karabiner 配置，并可能修改默认登录 Shell。

## 恢复内容

`restore.sh` 会依次执行以下操作：

1. 将配置目录链接到 `~/.config/`。
2. 将 [`claude/CLAUDE.md`](claude/CLAUDE.md) 链接到 `~/.claude/CLAUDE.md`。
3. 链接 Karabiner 配置源，并通过 Goku 生成 JSON 配置。
4. 使用 [`Brewfile`](Brewfile) 安装 formula、cask 和 MAS 应用。
5. 同步 Fisher、TPM 和 Yazi 插件。
6. 将 Fish 设为默认 Shell；Cargo 可用时安装 `cargo-cache` 和 `cargo-update`。

## 目录结构

```text
dotfiles/
├── bat/         # bat 配置
├── btop/        # btop 配置
├── claude/      # Claude Code 全局指令源文件
├── conda/       # Conda/Miniforge 配置
├── fish/        # Fish 配置、函数与插件清单
├── ghostty/     # Ghostty 配置与 shader
├── git/         # Git 全局配置
├── karabiner/   # Goku EDN 源文件与生成目录
├── lazygit/     # lazygit 配置
├── nvim/        # AstroNvim v6 配置
├── scripts/     # setup.sh 与 restore.sh
├── starship/    # Starship 提示符配置
├── tmux/        # tmux 配置
├── yazi/        # Yazi 配置与插件清单
├── Brewfile     # Homebrew Bundle 清单
└── README.md    # 安装、恢复与维护说明
```

## 常用命令

- `bash scripts/setup.sh`
  引导新的 macOS 机器，并调用 `restore.sh`。
- `bash scripts/restore.sh`
  恢复符号链接、软件、插件和默认 Shell。
- `brew bundle --file=Brewfile`
  安装 `Brewfile` 中声明的项目。
- `brew bundle dump --force --file=Brewfile --no-vscode`
  将当前 Homebrew 状态写回 `Brewfile`。
- `goku`
  从 `karabiner/edn/karabiner.edn` 生成 Karabiner JSON。

## 更新

在 Fish 中运行：

```fish
u
```

`u` 会更新 Homebrew、Conda、npm/pnpm 全局包、uv 工具、Fisher、TPM、
Neovim/AstroNvim（Lazy 插件、Treesitter parser 和 Mason 工具）、Yazi 和 MAS，
并执行 Mole 清理。它还会强制重写 `~/dotfiles/Brewfile`，因此仓库应保持在该路径。

`u` 不会拉取 dotfiles 仓库。Neovim 可执行文件由 Homebrew 更新阶段负责；
AstroNvim 生态则由后续三个同步步骤完整更新。
