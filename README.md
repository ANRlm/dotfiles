# dotfiles

Apple Silicon macOS 的个人配置，通过符号链接部署到 `~/.config`。

## 配置

| 目录 / 文件 | 内容 |
| --- | --- |
| [fish/](fish/) | 环境变量、PATH、工具集成、缩写及辅助函数 |
| [ghostty/](ghostty/) | 字体、主题、窗口和剪贴板 |
| [git/](git/) | 用户信息、Delta、同步策略及全局忽略规则 |
| [helix/](helix/) | 主题、编辑行为、诊断和快捷键 |
| [herdr/](herdr/) | 界面、通知和快捷键 |
| [starship/](starship/) | 提示符及各模块的符号 |
| [tmux/](tmux/) | 终端、窗口、快捷键及 TPM 插件 |
| [yazi/](yazi/) | 文件管理、预览、快捷键及插件清单 |
| [Brewfile](Brewfile) | Homebrew、Cask 和 Mac App Store 软件清单 |

## 安装

先安装 Homebrew 和 Git，并配置好 GitHub SSH 访问。安装 Brewfile 中的 Mac App Store 应用需要登录对应账户。

```sh
git clone git@github.com:ANRlm/dotfiles.git ~/dotfiles
brew bundle --file=~/dotfiles/Brewfile
```

以下命令在 Fish 中运行。若目标位置已有配置，先备份或移走，再创建链接：

```fish
mkdir -p ~/.config
for dir in fish ghostty git helix herdr starship tmux yazi
    ln -s ~/dotfiles/$dir ~/.config/$dir
end
```

Git 配置包含个人姓名和邮箱，使用前请检查 [git/config](git/config)。

如需将 Fish 设为登录 Shell，先确认 `command -v fish` 的路径已列在 `/etc/shells`，再运行：

```fish
chsh -s (command -v fish)
```

安装 Yazi 插件：

```fish
ya pkg install
```

tmux 首次启动时会自动安装 TPM 及声明的插件。Fish 的 fzf 键位由 `fzf --fish` 加载。

## 常用操作

以下命令在 Fish 中使用：

| 命令 / 按键 | 功能 |
| --- | --- |
| `s` | 展开为 `exec fish`，重新启动 Shell |
| `lg` | 打开 lazygit |
| `y` | 打开 Yazi，退出后切换到其中选定的目录 |
| `Ctrl-G` | 使用 ripgrep 和 fzf 搜索；`Ctrl-O` 在编辑器中打开匹配位置 |
| `ts` | 重新加载 tmux 配置 |
| `u` | 更新全局工具、应用及 tmux / Yazi 插件，并执行清理 |

默认编辑器为 Helix（`hx`）。普通模式下，`Space+w` 保存、`Space+q` 退出；`Tab` / `Shift-Tab` 跳到父语法节点末尾 / 开头，选择模式下扩展选区。使用 `:config-reload` 重新加载配置。

tmux 的前缀键为 `Ctrl-A`：随后按 `=` / `-` 分屏，`h/j/k/l` 选择窗格，`r` 进入调整大小模式，再按 `h/j/k/l` 调整，`q` 或 `Escape` 退出该模式。

全局 Node 和 pnpm 由 Homebrew 管理。Fish 通过 fnm 根据项目的 `.node-version` 或 `.nvmrc` 切换 Node；首次使用未安装的版本时运行 `fnm use --install-if-missing`。

## 更新与维护

`u` 更新 Homebrew、npm/pnpm/bun 全局包、uv 工具、Mac App Store 应用，以及已安装的 tmux 和 Yazi 插件，清理相关缓存并运行 Mole 清理。它会重写 `~/dotfiles/Brewfile`，因此仓库需放在 `~/dotfiles`。

更新统一使用 `u`，不需要参数。tmux 插件仅执行 Git 快进更新，Yazi 更新失败最多尝试三次；某项失败会继续执行其他独立步骤，最终返回失败状态。`u` 不会拉取本仓库，配置同步需自行执行 Git 操作。

配置按功能分组，标题沿用 `fish/config.fish` 的 `# ── 类别 ──…` 样式；Lua 使用 `--` 注释符。

Brewfile 由 `u` 重新生成，保留工具生成的格式。插件目录、Fish 运行状态及 herdr 会话、日志和 socket 已由 `.gitignore` 排除。
