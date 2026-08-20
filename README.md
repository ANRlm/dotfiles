# dotfiles

面向 Apple Silicon macOS 的个人配置仓库。配置文件保存在 Git 中，并通过符号链接部署到 `~/.config`。

## 工具栈

| 类别 | 工具 |
| --- | --- |
| Shell | Fish + Starship |
| 终端 | Ghostty + tmux |
| 编辑器 | Neovim |
| Git | lazygit + delta |
| 文件管理 | yazi + eza + fd |
| 搜索 | fzf + ripgrep |
| 系统工具 | btop + bat |
| 包与环境管理 | Homebrew + pnpm + bun + uv + Conda |

## 部署方式

仓库中的每个配置目录通过符号链接挂载到 `~/.config`，应用直接读写仓库内的文件：

```text
~/.config/btop     -> ~/dotfiles/btop
~/.config/conda    -> ~/dotfiles/conda
~/.config/fish     -> ~/dotfiles/fish
~/.config/ghostty  -> ~/dotfiles/ghostty
~/.config/git      -> ~/dotfiles/git
~/.config/lazygit  -> ~/dotfiles/lazygit
~/.config/starship -> ~/dotfiles/starship
~/.config/tmux     -> ~/dotfiles/tmux
~/.config/yazi     -> ~/dotfiles/yazi
```

## 安装

### 前置条件

- Apple Silicon Mac 和可用的网络连接。
- 可登录的 GitHub 账户，并已配置好 GitHub SSH。
- Homebrew 与 Git 已安装。
- 如需安装 `Brewfile` 中的 MAS 应用，请先登录 Mac App Store。
- 管理员权限；设置 Fish 为登录 Shell 时可能需要 `sudo`。

### 克隆仓库

```bash
git clone git@github.com:ANRlm/dotfiles.git ~/dotfiles
```

### 创建符号链接

目标位置已有同名文件或目录时，请先备份或迁移：

```fish
for dir in btop conda fish ghostty git lazygit starship tmux yazi
    ln -s ~/dotfiles/$dir ~/.config/$dir
end
```

### 安装软件

```bash
brew bundle --file=~/dotfiles/Brewfile
```

### 同步插件

```fish
# Fisher：按 fish/fish_plugins 清单安装 Fish 插件
curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
fisher install

# Yazi：按 yazi/package.toml 清单安装插件
ya pkg install
```

```bash
# TPM：安装 tmux 插件
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
bash ~/.config/tmux/plugins/tpm/bin/install_plugins
```

### 默认 Shell

```fish
chsh -s (command -v fish)
```

## 目录结构

```text
dotfiles/
├── btop/        # btop 配置
├── conda/       # Conda/Miniforge 配置
├── fish/        # Fish 配置、函数与插件清单
├── ghostty/     # Ghostty 配置与 shader
├── git/         # Git 全局配置、忽略规则与 delta 主题
├── lazygit/     # lazygit 配置
├── starship/    # Starship 提示符配置
├── tmux/        # tmux 配置
├── yazi/        # Yazi 配置与插件清单
├── Brewfile     # Homebrew Bundle 清单
└── README.md
```

## 更新

在 Fish 中运行：

```fish
u
```

`u` 会更新 Homebrew、Conda、npm/pnpm 全局包、uv 工具与缓存、Fisher、TPM、Yazi 和 MAS，并执行 Mole 清理。Yazi 插件更新遇到瞬时失败时最多重试三次。它还会强制重写 `~/dotfiles/Brewfile`，因此仓库应保持在 `~` 目录下。

`u` 不会拉取 dotfiles 仓库，Git 拉取请手动执行。

## 常用命令

- `u` — 更新全部
- `brew bundle --file=Brewfile` — 按 Brewfile 安装软件
- `brew bundle dump --force --file=Brewfile --no-vscode` — 将当前 Homebrew 状态写回 Brewfile
