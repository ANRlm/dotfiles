# dotfiles

macOS（Apple Silicon）上的个人配置。管的是终端里这一层：Fish、Ghostty、Helix、tmux、Herdr、Yazi，加上 Git、lazygit、starship、mise，以及几个编码 Agent 的配置。

顶层每个目录对应一个应用，目录名就是应用名；`Brewfile` 是软件清单，几份 `.md` 是文档。仓库只放配置，凭证、会话和缓存留在本机，由 `.gitignore` 挡住。

## 安装

仓库固定在 `~/dotfiles`，各应用的配置位置用符号链接指过来，所以改这里的文件就是改本机配置。

```sh
git clone git@github.com:ANRlm/dotfiles.git ~/dotfiles
brew bundle --file=~/dotfiles/Brewfile
```

装完软件后的链接、插件和 Agent 集成的步骤在 [AGENTS.md](AGENTS.md#部署新机器)，可以直接交给 Agent 跑。

## 日常

`u` 一条命令更新软件、Agent 的技能与插件并清理缓存；它不拉取本仓库，同步配置用 `git pull`。其余常用入口：`s` 重启 Shell，`y` 开 Yazi 并在退出后进入所选目录，`lg` 开 lazygit，`ts` 重载 tmux 配置。

按键和别名都在各自的配置里，改了立即或重载后生效。

## 文档

- [AGENTS.md](AGENTS.md)：部署步骤、各配置为什么这么写、维护和测试规则。
- [AGENT-TOOLS.md](AGENT-TOOLS.md)：编码 Agent 的 skill 与插件清单，只在部分机器上装。
