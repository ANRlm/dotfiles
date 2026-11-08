# dotfiles

Apple Silicon macOS 个人配置

| 路径 | 用途 |
| --- | --- |
| [fish/](fish/) | Shell：缩写、函数 |
| [zsh/](zsh/) | 编码 Agent 执行命令用的 zsh 环境 |
| [helix/](helix/) | 编辑器 |
| [yazi/](yazi/) | 文件管理器 |
| [git/](git/)、[lazygit/](lazygit/) | Git 与 lazygit |
| [starship/](starship/) | 提示符 |
| [mise/](mise/) | 按项目切换 Node 版本 |
| [Brewfile](Brewfile) | 软件清单 |

## 安装

仓库固定在 `~/dotfiles`，各应用的配置位置用符号链接指过来，所以改这里的文件就是改本机配置。

```sh
git clone git@github.com:ANRlm/dotfiles.git ~/dotfiles
brew bundle --file=~/dotfiles/Brewfile
```

之后的步骤在 [AGENTS.md](AGENTS.md#部署新机器)，可以直接交给 Agent 执行。

## 文档

- [AGENTS.md](AGENTS.md)：写给 Agent 的部署步骤、配置说明和维护规则。
