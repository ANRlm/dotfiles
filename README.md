# dotfiles

Apple Silicon macOS 的个人配置，用符号链接部署到各应用的配置位置。Ghostty、Helix 和 Herdr 统一使用 Rose Pine 主题。

## 目录

| 目录 / 文件 | 内容 |
| --- | --- |
| [fish/](fish/) | 环境变量、PATH、工具集成、缩写、辅助函数、`u` 更新函数及离线测试 |
| [ghostty/](ghostty/) | 字体、主题、窗口和剪贴板 |
| [git/](git/) | 用户信息、Delta、同步策略及全局忽略规则 |
| [helix/](helix/) | 主题、编辑行为、诊断和快捷键 |
| [herdr/](herdr/) | 界面、侧栏布局、通知、快捷键、automatic-rename 插件配置及三个本地插件 |
| [lazygit/](lazygit/) | Delta 差异渲染配置 |
| [mise/](mise/) | 全局设置：读取项目的 `.node-version` / `.nvmrc` |
| [pi/](pi/) | 自定义状态栏扩展 |
| [starship/](starship/) | 提示符及各模块的符号 |
| [tmux/](tmux/) | 终端、窗口、快捷键及 TPM 插件 |
| [yazi/](yazi/) | 文件管理、预览、快捷键及插件清单 |
| [Brewfile](Brewfile) | Homebrew、Cask 和 Mac App Store 软件清单 |
| [AGENTS.md](AGENTS.md) | 给 Agent 的详细文档：部署步骤、配置说明和维护约定 |
| [AGENT-TOOLS.md](AGENT-TOOLS.md) | Claude Code、Codex、Pi、Grok 的 skill、插件和配套工具部署清单，只在部分机器上执行 |

## 安装

先安装 Homebrew 和 Git，配置好 GitHub SSH 访问，再克隆到 `~/dotfiles`（路径固定）：

```sh
git clone git@github.com:ANRlm/dotfiles.git ~/dotfiles
brew bundle --file=~/dotfiles/Brewfile
```

之后让 Agent 按 [AGENTS.md](AGENTS.md#部署) 创建链接、安装插件；需要 Agent 工具的机器再按 [AGENT-TOOLS.md](AGENT-TOOLS.md) 部署。

## 常用

| 命令 / 按键 | 功能 |
| --- | --- |
| `u` | 更新全部工具、应用和插件，并执行清理 |
| `s` | 重启 Shell（`exec fish`） |
| `y` | 打开 Yazi，退出后切换到其中选定的目录 |
| `lg` | 打开 lazygit |
| `ts` | 重新加载 tmux 配置 |
| `Ctrl-G` | ripgrep + fzf 实时搜索，回车填入 `文件:行号`，`Ctrl-O` 在编辑器中打开 |
| `Ctrl-T` / `Alt-C` | fzf 选择文件 / 目录 |
| `cd` | 由 zoxide 接管 |

- **Helix**（默认编辑器 `hx`）：`Space+w` 保存、`Space+q` 退出，`:config-reload` 重新加载配置。
- **tmux**：前缀键 `Ctrl-A`；`=` / `-` 分屏，`h/j/k/l` 选择窗格，`r` 调整大小（`q` 或 `Escape` 退出），`R` 重新加载配置。
- **Herdr**：前缀键同为 `Ctrl-A`；`=` 垂直分屏，`↑` / `↓` 切换 Agent，`1..9` 切换 Tab，`Shift+1..9` 切换工作区；`Alt+1..9` 聚焦侧栏中对应的 Agent 行。
- **Pi**：默认快捷键，`/hotkeys` 查看；`/statusline` 在自定义和默认状态栏间切换。

`u` 不会拉取本仓库，配置同步需要自己执行 Git 操作。
