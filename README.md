# dotfiles

我的 macOS（Apple Silicon）配置：Fish、Ghostty、Helix、tmux、Herdr、Yazi 等，用符号链接部署。

## 内容

| 路径 | 内容 |
| --- | --- |
| [fish/](fish/) | Shell 环境、缩写、函数，以及更新命令 `u` |
| [ghostty/](ghostty/) | 终端：字体、主题、窗口、剪贴板 |
| [helix/](helix/) | 编辑器：主题、编辑行为、快捷键 |
| [tmux/](tmux/) | 终端复用：快捷键和 TPM 插件 |
| [herdr/](herdr/) | Agent 终端复用：界面、侧栏、快捷键和三个本地插件 |
| [yazi/](yazi/) | 文件管理器：预览、快捷键、插件 |
| [git/](git/)、[lazygit/](lazygit/) | Git 设置、Delta 差异显示、全局忽略规则 |
| [starship/](starship/) | 提示符 |
| [mise/](mise/) | 按项目切换 Node 版本 |
| [pi/](pi/) | Pi 的状态栏扩展 |
| [Brewfile](Brewfile) | 软件清单 |

## 安装

```sh
git clone git@github.com:ANRlm/dotfiles.git ~/dotfiles
brew bundle --file=~/dotfiles/Brewfile
```

仓库必须放在 `~/dotfiles`。之后的链接和插件安装写在 [AGENTS.md](AGENTS.md#部署新机器)，可以直接交给 Agent 执行。

## 常用

| 命令 / 按键 | 作用 |
| --- | --- |
| `u` | 更新所有软件和插件，并清理缓存 |
| `s` | 重启 Shell |
| `y` | 打开 Yazi，退出后进入选中的目录 |
| `lg` | 打开 lazygit |
| `ts` | 重新加载 tmux 配置 |
| `Ctrl-G` | 全文搜索，回车填入 `文件:行号`，`Ctrl-O` 用编辑器打开 |
| `Ctrl-T` / `Alt-C` | 选择文件 / 目录 |
| `cd` | 由 zoxide 接管 |

- **tmux**：前缀 `Ctrl-A`；`=` / `-` 分屏，`h/j/k/l` 切换窗格，`r` 调整大小，`R` 重载配置。
- **Herdr**：前缀同为 `Ctrl-A`；`=` 分屏，`↑` / `↓` 切换 Agent，`1..9` 切换 Tab，`Shift+1..9` 切换工作区；`Alt+1..9` 直接跳到侧栏中的 Agent。
- **Helix**：`Space+w` 保存，`Space+q` 退出，`:config-reload` 重载配置。
- **Pi**：`/hotkeys` 查看快捷键，`/statusline` 切换状态栏。

`u` 不会拉取本仓库，换机器同步配置用 `git pull`。

## 文档

- [AGENTS.md](AGENTS.md)：给 Agent 的说明，包括部署步骤、各配置的设计原因和维护规则。
- [AGENT-TOOLS.md](AGENT-TOOLS.md)：Claude Code、Codex、Pi、Grok 的 skill 和插件部署清单，只在部分机器上用。
