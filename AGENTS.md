# AGENTS.md

这是 ANRlm 的 macOS（Apple Silicon）个人配置仓库。各目录通过符号链接部署到应用的配置位置，改仓库里的文件即改本机配置。

## 规则

- 仓库固定在 `~/dotfiles`，符号链接和 `u` 都依赖这个路径。
- 仓库只放配置。凭证、会话、缓存和插件下载留在本机目录，由 `.gitignore` 排除；`pi/` 整个目录不进仓库。
- 配置文件按功能分组，分组标题沿用 `fish/config.fish` 的 `# ── 类别 ──…` 样式；Lua 文件用 `--` 注释。
- 登录、密钥、系统授权和覆盖已有配置，交给本人：给出完整命令，等本人确认完成。
- 改了行为就更新本文件的对应小节。README 只写给人看，仅在目录、安装方式或常用命令变化时修改。
- 文档只写当下的事实：读者是第一次打开仓库的人，不写「以前是…现在是…」「去掉了…保留了…」这类沿革。
- Agent 的 skill、插件和配套工具只装在部分机器上，清单在 [AGENT-TOOLS.md](AGENT-TOOLS.md)，本人要求时才执行。

## 部署新机器

按顺序执行，满足完成标准再进入下一步。

### 1. 安装软件

前提（本人完成）：Homebrew、Git、GitHub SSH 访问，以及 Brewfile 中 Mac App Store 应用所需的账户登录。

```sh
git clone git@github.com:ANRlm/dotfiles.git ~/dotfiles
brew bundle --file=~/dotfiles/Brewfile
```

完成标准：`brew bundle check --file=~/dotfiles/Brewfile` 通过，或未通过的条目已交本人确认。

### 2. 创建链接

在 Fish 中运行。目标位置已有配置时，先交本人确认，再备份或移走。

```fish
mkdir -p ~/.config "$HOME/Library/Application Support/lazygit"
for dir in fish ghostty git helix herdr mise starship tmux yazi
    ln -s ~/dotfiles/$dir ~/.config/$dir
end
# zsh 只从 $HOME 读 .zshenv
ln -s ~/dotfiles/zsh/zshenv ~/.zshenv
ln -s ~/dotfiles/herdr/plugins/config/herdr-automatic-rename ~/.config/herdr-automatic-rename
# lazygit 只链接配置文件，其余状态留在默认位置
ln -s ~/dotfiles/lazygit/config.yml "$HOME/Library/Application Support/lazygit/config.yml"
```

完成标准：每个链接都存在，`readlink` 指向 `~/dotfiles` 中的对应路径。

### 3. 安装插件

```fish
ya pkg install
pi install npm:@narumitw/pi-starship
pi install npm:pi-btw
pi install npm:@narumitw/pi-stamp
pi install npm:@juicesharp/rpiv-ask-user-question
pi install npm:@juicesharp/rpiv-todo
herdr plugin install qu8n/herdr-automatic-rename
herdr plugin link ~/dotfiles/herdr/plugins/local/fm-short-label
```

tmux 首次启动时自动安装 TPM 和插件。

Herdr 的 Agent 集成由 herdr 自己写进各 Agent 的配置目录，不在本仓库，要单独装：

```fish
herdr integration install claude
herdr integration install codex
herdr integration install pi
set -lx GROK_HOME $HOME/.grok-profiles/default
herdr integration install grok
```

`fm-short-label` 需要 Python 3，`herdr-automatic-rename` 需要 Bash 和 jq。首次 link 不会触发 startup hook，要在每个目标 Herdr 会话的 pane 内手动刷新一次：

```sh
bash ~/.config/herdr/plugins/local/fm-short-label/short-label.sh
```

Herdr server 通过 SSH 跑在远端时，插件装在**远端**并在远端 link。`fm-short-label` 依赖 `herdr/plugins/local/metadata_refresh.py`，同步到别处时保留 `herdr/plugins/local/` 的目录结构。

完成标准：以上命令都返回 0，`herdr integration status` 里四个集成都列在各自的 profile 路径下，Firstmate 子工作区在 Herdr 侧栏中不显示 `p:<token>`。

### 4. 交给本人

- [git/config](git/config) 写有个人姓名和邮箱，换人使用前修改。
- 把 Fish 设为登录 Shell：确认 `command -v fish` 已列在 `/etc/shells`，再 `chsh -s (command -v fish)`。
- Pi 的模型、设置、凭证和会话不在仓库里：在 Pi 中 `/login`，再设置默认模型等偏好。

完成标准：本人确认以上事项已处理或不需要。

## 修改配置前要知道的

### Shell 与 Node

- 缩写和函数在 [fish/config.fish](fish/config.fish) 和 [fish/functions/](fish/functions/)。`claude` 展开为 `claude --allow-dangerously-skip-permissions`。
- Agent 相关的环境变量集中在 `fish/config.fish` 的 Agents 一节。Claude Code 和 Codex 的 Shell（带 `CLAUDECODE` 或 `CODEX_THREAD_ID`）从钥匙串 `op-sa-lighthouser-test` 读取 1Password 服务账号令牌，导出为 `OP_SERVICE_ACCOUNT_TOKEN`；本人的 Shell 不导出，`op` 仍走 App 集成。两者实际在 zsh 里执行命令，所以 [zsh/zshenv](zsh/zshenv) 里有同样的判断。
- 全局 Node 和 pnpm 来自 Homebrew。mise 在交互式 Shell 中按项目的 `.node-version` / `.nvmrc` 切换 Node，缺版本时在项目目录 `mise install`。pnpm 版本跟随 `package.json` 的 `packageManager`。

### 终端工具

- **Ghostty** 把 Option 当 Alt 发送；终端程序读剪贴板时要确认。**Helix** 和 **tmux** 的复制都写入系统剪贴板。
- **Git** 全局忽略 `.env`、`.env.*`、`*.key`、`*.pem` 等凭证文件，但放行 `.env.example` 和 `.env.template`。
- **lazygit** 不读 `core.pager`，所以 Delta 在 [lazygit/config.yml](lazygit/config.yml) 里单独配置。Diff 视图关闭了自动换行：lazygit 的续行从第 0 列开始，会盖住 Delta 的行号栏。

### Herdr

#### 集成

会话恢复靠 integration：herdr 在 Agent 的配置目录里挂一个 `SessionStart` 钩子记录会话 ID，状态仍由 Herdr 自己检测。脚本由 herdr 管理，改了会被下次安装覆盖，要加钩子就放在它旁边另建文件。

| Agent | 集成 |
| --- | --- |
| Claude Code | `$CLAUDE_CONFIG_DIR/hooks/herdr-agent-state.sh`，注册在 `settings.json` |
| Codex | `~/.codex/herdr-agent-state.sh`，注册在 `hooks.json` |
| Grok | `$GROK_HOME/hooks/herdr-agent-state.sh`，注册在 `hooks/herdr.json` |
| Pi | `~/.pi/agent/extensions/herdr-agent-state.ts`，扩展直报全生命周期，Herdr 跳过屏幕检测 |

路径全跟环境变量走：Grok 不带 `GROK_HOME`、Claude 不带 `CLAUDE_CONFIG_DIR` 时，herdr 会写进并不存在的 `~/.grok` / `~/.claude`。Codex 的 `hooks.json` 同时有 Orca 和 Otty 的钩子，重装只动 herdr 自己那条。Codex 还会要求在新会话里信任钩子，交给本人在 `/hooks` 里确认。升级集成的方式见[更新](#更新)。

#### 侧栏

布局贴近 Herdr 默认，每项两行：

| 面板 | 第 1 行 | 第 2 行 |
| --- | --- | --- |
| Agent | 状态圆点、终端标题 `terminal_title_stripped`（加粗，实时更新） | 远端主机名、项目名、Agent 名称 |
| Spaces | 工作区名 | Herdr 自带的分支和 Git 状态 |

- Firstmate 子工作区的项目名和工作区名都用 `$short` 代替（见下文插件）。
- 分支取 shell 的 cwd，Firstmate 子任务的 shell 停在主 clone，所以显示的是主 clone 的分支。
- 本地机器名 `Local` 被规则隐藏，远端主机用 Rose Pine foam（`#9ccfd8`）标出，其余字段用主题默认色。项目名不设颜色，否则 Herdr 不显示选中态高亮。
- `[theme.custom]` 调亮了 `surface_dim`，因为 Rose Pine 自带的分隔符色几乎和背景同色。
- Pi 的标题带 `π - ` 前缀，Herdr 规则不能改写文字，保留原样。

#### 插件

- **`fm-short-label`**（本地）把 Firstmate 子工作区名 `└ task · p:<token>` 去掉 token 后作为 `$short` 发布到工作区和其中的 pane，不改工作区和 tab 的实际名称。刷新按 socket 串行，锁文件在 `~/.cache/herdr/plugin-locks/`；herdr 调用有 10 秒超时；刷新途中关掉的 pane 或工作区直接跳过。
- **`herdr-automatic-rename`**（GitHub）自动命名 tab，保留首次见到的自定义 tab 名，适合 Firstmate 的 `firstmate` / `fm-*`。不用 `kryptamine/herdr-auto-title`，因为它第一次轮询就会接管未锁定的 tab 和 pane 名。

#### 输入法

`[experimental]` 里开了两个为中文输入法准备的开关：

- `reveal_hidden_cursor_for_cjk_ime`：Claude Code、Pi、Codex、Grok 自己画光标，不开时候选框会飘到 pane 左上角。`cjk_ime_agents` 只列这四款，vim 之类隐藏光标的程序保持原样。
- `switch_ascii_input_source_in_prefix`：前缀键按下期间切到 ASCII 输入源，前缀快捷键不会被候选窗吞掉。

### Pi

Pi 的扩展都是 npm 包，装在 `~/.pi/agent/npm/`，条目写在 `~/.pi/agent/settings.json` 的 `packages` 里。条目不带版本号，`u` 的 `pi update --extensions` 把它们升到 npm 最新版。

| 包 | 作用 |
| --- | --- |
| `@narumitw/pi-starship` | 状态栏，见下文 |
| `pi-btw` | `/btw <问题>`（别名 `/side`）立刻开一个带工具的并行子会话，不打断主线程；`/btw:tangent` 不继承上下文，`/btw:ask` 只读，线程用 `/btw:inject` 或 `/btw:summarize` 注回主对话，内容默认不进主上下文 |
| `@narumitw/pi-stamp` | 每条消息右侧的时间戳，可选响应耗时、模型、用量和工具耗时；只写会话记录，不进模型上下文 |
| `@juicesharp/rpiv-ask-user-question` | `ask_user_question` 工具：结构化选项弹窗，最多四题，每题可写自定义答案 |
| `@juicesharp/rpiv-todo` | `todo` 工具和 `/todos` 命令，输入框上方常驻任务面板，列表从对话重建 |

- 两款 rpiv 会带进 `@juicesharp/rpiv-config` 和 `rpiv-i18n`（提供 `/languages`），它们不是独立条目。
- 不用 `@narumitw/pi-plan-mode`：它的策略默认拦掉其它扩展注册的工具，`todo` 和 `ask_user_question` 进 `/plan` 后就失效，除非在 `/plan tools` 里逐项勾选。

状态栏 `pi-starship` 的配置在 `~/.pi/agent/pi-starship.toml`，不在本仓库：

- 没有配置文件时保留 Pi 原生 footer，在 `/starship` 里选中预设或保存配置后才接管。
- `/starship` 预览预设、管理 profile、开配置会话；`/starship settings` 编辑 TOML，`/starship status` 看生效来源和诊断，`/starship help` 看字段说明。需要解释或改写字段时用包内 skill `/skill:configure-pi-starship`。
- 它和 `@narumitw/pi-statusline`、`pi-powerline-footer` 都占同一个 footer，同时装只有后加载的生效。

## 更新

`u`（[fish/functions/u.fish](fish/functions/u.fish)）依次：

- Homebrew：更新、升级、清理，并把本机新装的软件追加进 Brewfile。
- Node：更新 npm 全局包，清理 pnpm store，按全局 mise 配置升级工具（在 `$HOME` 里跑，不碰项目自己的 `mise.toml`；`.node-version` 这种精确 pin 不会被改）。
- Agent skill 与插件：见 [AGENT-TOOLS.md](AGENT-TOOLS.md#更新)。
- uv 缓存清理、Mac App Store 应用、tmux 插件（Git 快进）。
- Herdr：更新 GitHub 插件（保留 ref 和配置）。Herdr 升级可能提高集成版本号，`u` 只重装 `herdr integration status` 里标 `outdated` 的，因为重装会改写 Agent 自己的配置文件；全部 current 时只打一行 ✓，`not installed` 的不补，按部署步骤手动装。
- Yazi 插件（最多重试三次），最后跑 Mole 清理。

单步失败不中断，结束时返回失败。`u` 不拉取本仓库。

Brewfile 是全量清单，本机只装了一部分，按 tap、brew、cask、mas 分类。`u` 只追加新出现的条目（放在同类末尾），从不删除；npm 全局包不记录。卸载软件后手动删掉对应行。

## 测试

改 `u.fish` 或 Herdr 本地插件后运行。全部离线，只用临时目录和 mock：

```sh
fish --no-config --no-execute fish/functions/u.fish
python3 fish/tests/runtime.test.py
python3 fish/tests/sync-skills.test.py
python3 herdr/plugins/local/test_refresh.py
python3 herdr/plugins/local/fm-short-label/test_short_label.py
```
