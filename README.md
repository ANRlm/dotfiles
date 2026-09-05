# dotfiles

面向 Apple Silicon macOS 的个人配置仓库。配置文件保存在 Git 中，并通过符号链接部署到 `~/.config`。

## 工具栈

| 类别 | 工具 |
| --- | --- |
| Shell | Fish + Starship |
| 终端 | Ghostty + tmux + herdr |
| 编辑器 | Helix（`hx`） |
| Git | lazygit |
| 文件管理 | yazi + eza + fd |
| 搜索 | fzf + ripgrep |
| 系统工具 | bat + macmon |
| 包与环境管理 | Homebrew + fnm + pnpm + bun + uv |

## 部署方式

仓库中的每个配置目录通过符号链接挂载到 `~/.config`，应用直接读写仓库内的文件：

```text
~/.config/fish     -> ~/dotfiles/fish
~/.config/ghostty  -> ~/dotfiles/ghostty
~/.config/git      -> ~/dotfiles/git
~/.config/helix    -> ~/dotfiles/helix
~/.config/herdr    -> ~/dotfiles/herdr
~/.config/starship -> ~/dotfiles/starship
~/.config/tmux     -> ~/dotfiles/tmux
~/.config/yazi     -> ~/dotfiles/yazi
```

herdr 把 socket 和日志固定写在配置目录下，链接后它们会落在 `herdr/` 里，已由 `.gitignore` 排除。`herdr/config.toml` 由 herdr 自身管理并会被重写，其中的注释无法保留。

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
mkdir -p ~/.config
for dir in fish ghostty git helix herdr starship tmux yazi
    ln -s ~/dotfiles/$dir ~/.config/$dir
end
```

### 安装软件

```bash
brew bundle --file=~/dotfiles/Brewfile
```

### 默认编辑器

Fish 的 `EDITOR` 和 Git 的 `core.editor` 均设为 `hx`；Fish 的 `Ctrl-G` 搜索中，`Ctrl-O` 使用 `$EDITOR` 打开匹配文件并跳转到对应行，未设置时回退到 `hx`。

Helix 配置位于 `helix/config.toml`，使用 `adwaita-dark` 主题，按界面、编辑行为、文件选择、诊断和键位分组。复制与粘贴默认使用系统剪贴板；文件选择器显示隐藏文件，同时遵循 Git 忽略规则。

`Tab` / `Shift-Tab` 使用官方 Smart Tab 导航配置：普通模式跳到父语法节点末尾 / 开头，选择模式扩展到对应位置；插入模式保留默认 Smart Tab，`Shift-Tab` 跳到父节点开头。

在 Helix 中运行 `:config-open` 编辑配置，`:config-reload` 重新加载。语言服务器与格式化器需按使用的语言另行安装，可用 `hx --health <语言>` 检查。

参考：[配置文件](https://docs.helix-editor.com/configuration.html)、[编辑器选项](https://docs.helix-editor.com/editor.html)、[键位映射](https://docs.helix-editor.com/remapping.html)。

### Node 版本管理

全局 Node 与 pnpm 由 Homebrew 管理；Fish 通过 fnm 自动读取项目根目录的 `.node-version` 或 `.nvmrc`，切换项目使用的 Node。首次进入一个尚未安装对应 Node 的项目时运行：

```fish
fnm use --install-if-missing
```

新项目应把精确版本写入 `.node-version` 并提交到 Git；pnpm 版本使用 `package.json` 的 `packageManager` 字段固定。

### 同步插件

```fish
# Yazi：按 yazi/package.toml 清单安装插件
ya pkg install
```

tmux 插件无需手动安装：首次启动 tmux 时，`tmux.conf` 会自动克隆 TPM 并安装插件。

Fish 不使用插件管理器，fzf 的键位集成由 `fzf --fish` 在 `config.fish` 中直接加载。

插件采用跟随最新版的策略；日常更新使用 `u plugins`，与全局工具链更新分开执行。

### 默认 Shell

```fish
chsh -s (command -v fish)
```

## 目录结构

```text
dotfiles/
├── fish/        # Fish 配置与函数
├── ghostty/     # Ghostty 配置与 shader
├── git/         # Git 全局配置与忽略规则
├── helix/       # Helix 编辑器配置
├── herdr/       # herdr 键位与界面配置
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
u plugins
```

`u` 会更新 Homebrew、npm/pnpm/bun 全局包、uv 工具与缓存和 MAS，并执行 Mole 清理。它始终使用 Homebrew 的全局 Node 工具链，不会改动 fnm 管理的项目 Node。

`u plugins` 会把 TPM 和 Yazi 插件更新到最新版本；Yazi 遇到瞬时失败时最多重试三次。

`u` 还会强制重写 `~/dotfiles/Brewfile`，因此仓库应保持在 `~` 目录下。

`u` 不会拉取 dotfiles 仓库，Git 拉取请手动执行。
