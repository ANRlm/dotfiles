# AGENTS.md

这是 ANRlm 的 macOS（Apple Silicon）个人配置仓库。各目录通过符号链接部署到应用的配置位置，改仓库里的文件即改本机配置。

## 规则

- 仓库固定在 `~/dotfiles`，符号链接和 `u` 都依赖这个路径。
- 仓库只放配置。凭证、会话、缓存和插件下载留在本机目录，由 `.gitignore` 排除。`pi/` 用白名单：新增文件先确认不含凭证，再在 `.gitignore` 中显式放行。
- 配置文件按功能分组，分组标题沿用 `fish/config.fish` 的 `# ── 类别 ──…` 样式；Lua 文件用 `--` 注释。
- 登录、密钥、系统授权和覆盖已有配置，交给本人：给出完整命令，等本人确认完成。
- 改了行为就更新本文件的对应小节。README 只写给人看，仅在目录、安装方式或常用命令变化时修改。
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
mkdir -p ~/.config ~/.pi/agent/extensions "$HOME/Library/Application Support/lazygit"
for dir in fish ghostty git helix herdr mise starship tmux yazi
    ln -s ~/dotfiles/$dir ~/.config/$dir
end
ln -s ~/dotfiles/herdr/plugins/config/herdr-automatic-rename ~/.config/herdr-automatic-rename
# Pi 和 lazygit 只链接单个文件，本机的凭证和会话留在原目录
ln -s ~/dotfiles/pi/extensions/minimal-statusline.ts ~/.pi/agent/extensions/minimal-statusline.ts
ln -s ~/dotfiles/lazygit/config.yml "$HOME/Library/Application Support/lazygit/config.yml"
```

完成标准：每个链接都存在，`readlink` 指向 `~/dotfiles` 中的对应路径。

### 3. 安装插件

```fish
ya pkg install
herdr plugin install qu8n/herdr-automatic-rename
herdr plugin link ~/dotfiles/herdr/plugins/local/fm-short-label
```

tmux 首次启动时自动安装 TPM 和插件。

`fm-short-label` 需要 Python 3，`herdr-automatic-rename` 需要 Bash 和 jq。首次 link 不会触发 startup hook，要在每个目标 Herdr 会话的 pane 内手动刷新一次：

```sh
bash ~/.config/herdr/plugins/local/fm-short-label/short-label.sh
```

Herdr server 通过 SSH 跑在远端时，插件装在**远端**并在远端 link。`fm-short-label` 依赖 `herdr/plugins/local/metadata_refresh.py`，同步到别处时保留 `herdr/plugins/local/` 的目录结构。

完成标准：以上命令都返回 0，Firstmate 子工作区在 Herdr 侧栏中不显示 `p:<token>`。

### 4. 交给本人

- [git/config](git/config) 写有个人姓名和邮箱，换人使用前修改。
- 把 Fish 设为登录 Shell：确认 `command -v fish` 已列在 `/etc/shells`，再 `chsh -s (command -v fish)`。
- Pi 的模型、设置、凭证和会话不在仓库里：在 Pi 中 `/login`，再设置默认模型等偏好。

完成标准：本人确认以上事项已处理或不需要。

## 修改配置前要知道的

### Fish 与 Node

- 缩写和函数在 [fish/config.fish](fish/config.fish) 和 [fish/functions/](fish/functions/)。`claude` 展开为 `claude --allow-dangerously-skip-permissions`。
- 全局 Node 和 pnpm 来自 Homebrew。mise 在交互式 Shell 中按项目的 `.node-version` / `.nvmrc` 切换 Node，缺版本时在项目目录 `mise install`。pnpm 版本跟随 `package.json` 的 `packageManager`。

### 终端工具

- **lazygit** 不读 `core.pager`，所以 Delta 在 [lazygit/config.yml](lazygit/config.yml) 里单独配置。Diff 视图关闭了自动换行：lazygit 的续行从第 0 列开始，会盖住 Delta 的行号栏。
- **Git** 全局忽略 `.env`、`.env.*`、`*.key`、`*.pem` 等凭证文件，但放行 `.env.example` 和 `.env.template`。
- **Ghostty** 把 Option 当 Alt 发送；终端程序读剪贴板时要确认。**Helix** 和 **tmux** 的复制都写入系统剪贴板。

### Herdr 侧栏

布局贴近 Herdr 默认。

Agent 面板每个 Agent 两行：

| 行 | 内容 |
| --- | --- |
| 1 | 状态圆点、终端标题 `terminal_title_stripped`（加粗，实时更新） |
| 2 | 远端主机名、项目名（Firstmate 子工作区用 `$short` 代替）、Agent 名称 |

Spaces 面板每项两行：工作区名（Firstmate 子工作区同样用 `$short`），以及 Herdr 自带的分支和 Git 状态。分支取 shell 的 cwd，Firstmate 子任务的 shell 停在主 clone，所以这里显示的是主 clone 的分支。

样式上的取舍：

- 本地机器名 `Local` 被规则隐藏，远端主机用 Rose Pine foam（`#9ccfd8`）标出。其余字段用主题默认色。
- 项目名不设颜色，否则 Herdr 不再显示选中态高亮。
- `[theme.custom]` 调亮了 `surface_dim`，因为 Rose Pine 自带的分隔符色几乎和背景同色。
- Pi 的标题带 `π - ` 前缀，Herdr 规则不能改写文字，保留原样。

### Herdr 插件

**`fm-short-label`**（本地）把 Firstmate 子工作区名 `└ task · p:<token>` 去掉 token 后作为 `$short` 发布到工作区和其中的 pane，不改工作区和 tab 的实际名称。刷新按 socket 串行，锁文件在 `~/.cache/herdr/plugin-locks/`；herdr 调用有 10 秒超时；刷新途中关掉的 pane 或工作区直接跳过。

**`herdr-automatic-rename`**（GitHub）自动命名 tab，保留首次见到的自定义 tab 名，适合 Firstmate 的 `firstmate` / `fm-*`。不用 `kryptamine/herdr-auto-title`，因为它第一次轮询就会接管未锁定的 tab 和 pane 名。

### Pi 状态栏

代码在 [pi/extensions/minimal-statusline.ts](pi/extensions/minimal-statusline.ts)，改完在 Pi 中 `/reload`。只有一种布局。

```text
路径 [分支]                         ↑输入 ↓输出 · cache 命中率 · r 缓存读 w 缓存写
ctx 剩余/窗口 进度条 剩余% left                        活动 · 本轮耗时 · ~tok/s · 模型 · effort
```

- 第一行右侧是会话累计 token、会话加权的 cache 命中率和缓存读写。命中率低不标警告。
- 第二行右侧是活动、本轮耗时、生成中的 `~tok/s`、模型和 effort；空闲时仍显示模型和 effort。
- 活动文案用英文：`waiting`、`thinking`、`streaming`、`tool` / `tools×N`、`compacting`、`finishing`。工具按调用 ID 跟踪，直到 `agent_settled` 才停表。扩展 API 不暴露重试事件，所以不显示重试。
- 其他扩展的状态全部显示，按宽度换行，带 warning、error、警告等字样的排前面。没有结构化的严重级别，这只是启发式。
- 窄屏时路径和分支先缩短，放不下的指标追加到下面，不隐藏。

**ctx** 显示整个窗口的剩余量，如 `ctx 108k/200k ━━━━━━━╸────── 54% left`：

- 剩余低于 30% 变黄、低于 10% 变红。
- 空间不够时进度条从 14 列缩到 10、6 列，再去掉，然后改用 `ctx 54% left`，仍放不下就换行。
- 用量未知时显示 `ctx —/200k · usage pending`。

**统计口径**：

- `~tok/s` 按中英文字符权重估算，按模型分别校准，结果按模型原子写入 `~/.pi/agent/statusline-rate.json.d/`，不同模型的并发会话互不覆盖；同模型更新前先读回最新记录，多个会话收敛。这是估算，不是服务端吞吐量。
- `/statusline default` 临时切回默认状态栏，`/statusline custom` 切回来，不带参数时来回切换。

## 更新

`u`（[fish/functions/u.fish](fish/functions/u.fish)）依次：

- Homebrew：更新、升级、清理，并把本机新装的软件追加进 Brewfile。
- Node：更新 npm 全局包，清理 pnpm store。
- Agent skill 与插件：见 [AGENT-TOOLS.md](AGENT-TOOLS.md#更新)。
- 其他：清理 uv 缓存，更新 Mac App Store 应用、tmux 插件（Git 快进）、Herdr 的 GitHub 插件（保留 ref 和配置）、Yazi 插件（最多重试三次），最后跑 Mole 清理。

单步失败不中断，结束时返回失败。`u` 不拉取本仓库。

Brewfile 是全量清单，本机只装了一部分。`u` 只追加新出现的条目（放在同类末尾），从不删除；npm 全局包不记录。卸载软件后手动删掉对应行。

## 测试

改 `u.fish`、Herdr 本地插件或 Pi 状态栏后运行。全部离线，只用临时目录和 mock：

```sh
fish --no-config --no-execute fish/functions/u.fish
python3 fish/tests/runtime.test.py
python3 fish/tests/sync-skills.test.py
python3 herdr/plugins/local/test_refresh.py
python3 herdr/plugins/local/fm-short-label/test_short_label.py
node --test pi/tests/statusline.test.mjs
```
