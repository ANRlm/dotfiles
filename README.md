# dotfiles

Apple Silicon macOS 的个人配置，用符号链接部署到各应用的配置位置。Ghostty、Helix 和 Herdr 统一使用 Rose Pine 主题；cmux 单独使用 Lovelace。

## 目录

| 目录 / 文件 | 内容 |
| --- | --- |
| [cmux/](cmux/) | 应用设置、Tab 快捷键及 cmux 专用终端配置 |
| [fish/](fish/) | 环境变量、PATH、工具集成、缩写、辅助函数、`u` 更新函数及离线测试 |
| [ghostty/](ghostty/) | 字体、主题、窗口和剪贴板 |
| [git/](git/) | 用户信息、Delta、同步策略及全局忽略规则 |
| [helix/](helix/) | 主题、编辑行为、诊断和快捷键 |
| [herdr/](herdr/) | 界面、侧栏布局、通知、快捷键、automatic-rename 插件配置及两个本地插件 |
| [lazygit/](lazygit/) | Delta 差异渲染配置 |
| [pi/](pi/) | 自定义状态栏扩展 |
| [starship/](starship/) | 提示符及各模块的符号 |
| [tmux/](tmux/) | 终端、窗口、快捷键及 TPM 插件 |
| [yazi/](yazi/) | 文件管理、预览、快捷键及插件清单 |
| [Brewfile](Brewfile) | Homebrew、Cask 和 Mac App Store 软件清单 |
| [AGENT-TOOLS.md](AGENT-TOOLS.md) | Claude Code、Codex、Pi 的 skill、插件、配套命令行工具及 Firstmate 部署清单 |

## 安装

### 1. 克隆并安装软件

先安装 Homebrew 和 Git，并配置好 GitHub SSH 访问。Brewfile 中的 Mac App Store 应用需要先登录对应账户。仓库必须放在 `~/dotfiles`，`u` 按这个路径更新 Brewfile。

```sh
git clone git@github.com:ANRlm/dotfiles.git ~/dotfiles
brew bundle --file=~/dotfiles/Brewfile
```

### 2. 创建链接

以下命令在 Fish 中运行。目标位置已有配置时，先备份或移走。

整个目录链接到 `~/.config`：

```fish
mkdir -p ~/.config
for dir in fish ghostty git helix herdr starship tmux yazi
    ln -s ~/dotfiles/$dir ~/.config/$dir
end
ln -s ~/dotfiles/herdr/plugins/config/herdr-automatic-rename ~/.config/herdr-automatic-rename
```

Pi、cmux 和 lazygit 只链接单个文件，凭证、会话和缓存留在本机目录中：

```fish
mkdir -p ~/.pi/agent/extensions ~/.config/cmux "$HOME/Library/Application Support/com.cmuxterm.app" "$HOME/Library/Application Support/lazygit"
ln -s ~/dotfiles/pi/extensions/minimal-statusline.ts ~/.pi/agent/extensions/minimal-statusline.ts
ln -s ~/dotfiles/cmux/cmux.json ~/.config/cmux/cmux.json
ln -s ~/dotfiles/cmux/config.ghostty "$HOME/Library/Application Support/com.cmuxterm.app/config.ghostty"
ln -s ~/dotfiles/lazygit/config.yml "$HOME/Library/Application Support/lazygit/config.yml"
```

`cmux/config.ghostty` 只给 cmux 用，与 `ghostty/config.ghostty` 各自独立。

### 3. 安装插件

```fish
ya pkg install
herdr plugin install qu8n/herdr-automatic-rename
herdr plugin link ~/dotfiles/herdr/plugins/local/fm-short-label
herdr plugin link ~/dotfiles/herdr/plugins/local/sidebar-short-title
```

tmux 首次启动时会自动安装 TPM 及声明的插件。

### 4. 收尾

- [git/config](git/config) 写有个人姓名和邮箱，换人使用前先修改。
- 如需把 Fish 设为登录 Shell，先确认 `command -v fish` 的路径已列在 `/etc/shells`，再运行 `chsh -s (command -v fish)`。
- Pi 的 `models.json`、`settings.json`（默认模型、主题等）、`auth.json`、会话、模型缓存、其他扩展和 skills 都不在仓库里。新机器上在 Pi 中执行 `/login`，再设置模型等偏好。
- Agent 的 skill、插件和配套命令行工具按 [AGENT-TOOLS.md](AGENT-TOOLS.md) 部署。

## 日常使用

### Fish

| 命令 / 按键 | 功能 |
| --- | --- |
| `u` | 更新全部工具、应用和插件，并执行清理（见[更新与维护](#更新与维护)） |
| `s` | 展开为 `exec fish`，重启 Shell |
| `y` | 打开 Yazi，退出后切换到其中选定的目录 |
| `lg` | 打开 lazygit |
| `ts` | 重新加载 tmux 配置 |
| `Ctrl-G` | 用 ripgrep 和 fzf 实时搜索，回车把 `文件:行号` 填入命令行，`Ctrl-O` 在编辑器中打开 |
| `Ctrl-T` / `Alt-C` | fzf 选择文件 / 目录（由 `fzf --fish` 加载） |
| `cd` | 由 zoxide 接管 |

`claude` 展开为 `claude --allow-dangerously-skip-permissions`。Homebrew（`b*`）、tmux（`t*`）、eza（`el`、`et`）等其余缩写见 [fish/config.fish](fish/config.fish)。

全局 Node 和 pnpm 由 Homebrew 管理。进入项目时，fnm 按 `.node-version` 或 `.nvmrc` 切换 Node；版本未安装时运行 `fnm use --install-if-missing`。

### 终端与编辑器

- **Ghostty**：Option 作为 Alt 发送；终端程序读取系统剪贴板时会询问确认。
- **Helix**（默认编辑器 `hx`）：普通模式下 `Space+w` 保存、`Space+q` 退出；`Tab` / `Shift-Tab` 跳到父语法节点末尾 / 开头，选择模式下改为扩展选区。复制默认写入系统剪贴板。`:config-reload` 重新加载配置。
- **tmux**：前缀键 `Ctrl-A`，之后按 `=` / `-` 分屏，`h/j/k/l` 选择窗格，`r` 进入调整大小模式（`h/j/k/l` 调整，`q` 或 `Escape` 退出），`R` 重新加载配置。复制模式使用 vi 键位，`y` 复制到系统剪贴板。
- **cmux**：`Option+H/L` 切换到上一个 / 下一个 Tab，修改配置后执行 `cmux reload-config`。
- **lazygit**：lazygit 不读取 `core.pager`，Delta 在 [lazygit/config.yml](lazygit/config.yml) 中单独配置。Diff 视图关闭了自动换行：lazygit 折行时续行从第 0 列开始，会覆盖 Delta 的行号栏。
- **Git**：全局规则忽略 `.env`、`.env.*`、`*.key`、`*.pem` 等凭证文件，但允许提交不含凭证的 `.env.example` 和 `.env.template`。
- **Pi**：使用默认快捷键，在 Pi 中运行 `/hotkeys` 查看。

### Herdr

#### 快捷键

前缀键同为 `Ctrl-A`。

| 按键 | 功能 |
| --- | --- |
| `prefix` `=` | 垂直分屏 |
| `prefix` `↑` / `↓` | 上一个 / 下一个 Agent |
| `prefix` `1..9` | 切换 Tab |
| `prefix` `Shift+1..9` | 切换工作区 |
| `Alt+1..9` | 聚焦侧栏中对应的 Agent 行 |

#### 侧栏

Agent 面板按项目分组，状态只用第一行的圆点表示：

| 行 | 内容 |
| --- | --- |
| 1 | 状态圆点、短任务名（`$sidebar_title`） |
| 2 | 远端主机名、项目名；Firstmate 子工作区显示 `$short` 代替项目名 |
| 3 | Agent 名称（如 `pi`、`claude`） |

- 本地 Agent 的机器名 `Local` 被规则隐藏，以减少 ` · ` 分隔符，远端主机也更显眼。
- 所有字段加粗，不加 `dim`。机器名、Agent 名和自定义字段默认与分组标题、Pane 边框共用同一个色槽，无法单独调亮，因此改用 Rose Pine 色板中的固定颜色：任务名 `text`、远端主机名 `teal`（foam）、Agent 名 `overlay1`、`$short` 用 `subtext0`（与未选中的工作区名一致）。
- 项目名不设颜色：设定前景色会让 Herdr 不再提供选中态高亮。
- 分隔符同样改成固定颜色，因为 Rose Pine 原本的 `surface_dim` 几乎与面板背景同色。Herdr 0.9.3 不能修改分隔符本身，同一行的多个字段之间仍是原生的 ` · `。
- 色值及其用途集中列在 [herdr/config.toml](herdr/config.toml) 的 `[theme]` 下，换主题时按该列表替换。

Spaces 面板每项两行：工作区名（Firstmate 子工作区同样显示 `$short`）、分支与 Git 状态。

#### 短任务名

`sidebar-short-title` 插件为每个 Agent 生成 `$sidebar_title`，依次取：

1. **原生 pane 名**：与分屏边框共用的稳定任务别名。用 `herdr pane rename <pane-id> <短任务名>` 设置，`herdr pane rename <pane-id> --clear` 恢复自动标题。
2. **手动改过的 tab 名**：仅当该 tab 只有一个 Agent 时采用，避免多个 Agent 同名。手动状态由 `herdr-automatic-rename` 记录；Firstmate 创建时指定的 `fm-<mate>` 也算手动名。
3. **终端标题**：去掉其中重复的项目名和目录名；Pi 标题还会去掉开头的 `π - `。

插件不截断短任务名，由 Herdr 按侧栏当前宽度和中英文显示宽度截断并加 `…`；完整终端标题不变。Herdr 0.9.3 没有标题变化事件，短标题在启动、Agent 状态变化、焦点切换和改名等事件时刷新。

`fm-short-label` 插件处理 Firstmate 子工作区：其名称形如 `└ task · p:<token>`，插件把去掉 token 的 `└ task` 作为 `$short` 发布，不改动工作区或 tab 的实际名称。

#### 插件部署与刷新

- 两个本地插件都需要 Python 3，并共用 `herdr/plugins/local/metadata_refresh.py`。部署时保留整个 `herdr/plugins/local/` 目录结构，只同步插件目录和这个共享文件；凭证、Herdr 会话、socket、日志和锁文件等运行态留在原机器。
- `herdr-automatic-rename` 需要 Bash 和 jq。它保留首次见到的自定义 tab 名，适合 Firstmate 使用的 `firstmate` / `fm-*` 标签。本机不使用 `kryptamine/herdr-auto-title`：它首次轮询时就会接管未记录手动锁定的 tab 和 pane 名称。
- 首次 link 或重新启用插件时不会运行 startup hook。在每个目标 Herdr 会话的 pane 内执行以下命令，立即补齐元数据：

  ```sh
  bash ~/.config/herdr/plugins/local/fm-short-label/short-label.sh
  python3 ~/.config/herdr/plugins/local/sidebar-short-title/short_title.py
  ```

- 刷新按插件和 Herdr socket 串行执行，锁文件位于运行插件的机器上的 `~/.cache/herdr/plugin-locks/`，进程退出或报错时释放。刷新途中关闭的 pane 或工作区会被跳过，其他错误照常报告。
- 通过 SSH 在远端运行 Herdr server 时，两个本地插件要部署在**远端**，并在远端执行上面两条 `herdr plugin link`。缺少 `fm-short-label` 就没有 `$short`，缺少 `sidebar-short-title` 就没有短任务名；远端未安装 `herdr-automatic-rename` 时，侧栏不会采用手动 tab 名。

### Pi 状态栏

状态栏只有一种完整布局，没有预设或详情视图，也不再读写旧的 `~/.pi/agent/statusline.json`。修改扩展后在 Pi 中执行 `/reload` 生效。

```text
路径 [分支]                         ↑输入 ↓输出 · ≈$成本 · cache 命中率 · r 缓存读 w 缓存写
ctx 剩余/窗口 进度条 剩余% left · auto in ≈余量        活动 · 本轮耗时 · ~tok/s · 模型 · effort
```

以上为示意，实际内容随用量数据、活动状态和可用宽度变化。

- **第一行**：左侧为路径和分支；右侧为会话累计 token（`↑` 输入 / `↓` 输出）、估算成本、最近一次 assistant 请求的 `cache` 命中率及缓存读写（`r` / `w`）。单次命中率低不标警告。
- **第二行**：左侧为 ctx 模块；右侧为活动、本轮累计耗时、生成中的 `~tok/s`、模型和 effort。空闲时仍显示模型和 effort。
- **活动**文案统一为英文：`waiting`、`thinking`、`streaming`、`tool` / `tools×N`、`compacting`、`finishing`。并行或嵌套的工具按调用 ID 跟踪，直到 `agent_settled` 才停止计时。Pi 1.1.0 没有专用的重试事件，因此不推测重试状态；`waiting` / `finishing` 也不代表已经完全结束。
- **其他扩展的状态**全部显示，长文本按终端宽度换行，带 warning、error、警告等明确标记的优先显示，原文不翻译。状态 API 没有结构化的严重级别，标记识别只是启发式。
- **窄屏**：宽度足够时主体为两行，路径和分支按列宽缩短，模型与 effort 固定在第二行右侧。放不下的指标和活动追加到下方，不会被隐藏；极窄时较长的模型名和 ctx 也会换行。

#### ctx 与自动压缩

ctx 显示剩余量，例如 `ctx 108k/200k ━━━━━━━╸────── 54% left · auto in ≈91.6k`：数值和百分比是整个窗口的剩余容量，进度条随用量增加而缩短。

- `auto in ≈…` 是距自动压缩阈值的估算余量。达到阈值显示 `auto due`，不代表已经开始压缩；实际压缩由活动区的 `compacting` 表示。关闭自动压缩时显示 `auto off`。
- 颜色按有效容量的剩余比例变化：低于 30% 变黄，低于 10% 变红。开启自动压缩时，有效容量为窗口减去预留量；关闭时为整个窗口。强调色只用在进度条和余量上，关闭自动压缩时百分比也会强调。
- 空间不足时，进度条依次从 14 列缩到 10 列、6 列，再去掉进度条，然后改用 `ctx 54% left · auto ≈91.6k` 简写；连简写都放不下时，把完整数值换行显示。
- 用量未知时显示 `ctx —/200k · usage pending`，不画空进度条，也不推断压缩阈值状态。

#### 统计口径与命令

- `≈$` 按模型价格配置和已上报用量估算整个会话的成本，包含历史分支、工具及压缩记录，不是服务商账单；未上报的用量无法计入。
- `~tok/s` 只在思考和生成时显示，按中英文字符权重估算，并按模型分别校准：校准结果写入 `~/.pi/agent/statusline-rate.json.d/` 并原子替换，避免不同模型的并发会话互相覆盖；同一模型的并发会话以最后写入为准。旧的 `statusline-rate.json` 仍可读取。混合文本和工具调用的样本无法分别测出两类误差，因此这只是启发式估算，不是服务端的实际吞吐量。
- `/statusline default` 临时恢复默认状态栏，`/statusline custom` 切回，不带参数时在两者间切换。`/reload` 或重启后默认使用自定义状态栏。

## 更新与维护

### `u`

`u` 不接受参数，依次执行：

- **Homebrew**：更新、升级、清理依赖和缓存，并把本机新装的软件追加到 Brewfile。
- **Node**：更新 npm 全局包，清理 pnpm store。
- **Agent skill 与插件**：见 [AGENT-TOOLS.md](AGENT-TOOLS.md#更新)。
- **其他**：清理 uv 缓存，更新 Mac App Store 应用，用 Git 快进更新 tmux 插件，重装 Herdr 的 GitHub 插件到最新提交（保留配置），更新 Yazi 插件（最多尝试三次），最后运行 Mole 清理。

某一步失败时会继续执行其余步骤，结束时返回失败状态。`u` 不会拉取本仓库，配置同步需要自己执行 Git 操作。

### Brewfile

Brewfile 是完整软件清单，本机只装其中一部分。`u` 只追加 `brew bundle dump` 中新出现的条目（放在同类条目末尾），从不删除本机没装的条目；npm 全局包不记录。卸载软件后需手动删除对应行。

### 版本管理范围

- `.gitignore` 排除各工具下载的插件、Fish 运行状态，以及 Herdr 的会话、日志和 socket；Herdr 插件配置（`herdr/plugins/config/`）纳入版本管理。
- `pi/` 和 `cmux/` 采用白名单，只放行 Pi 状态栏扩展和两份 cmux 配置。Pi 状态栏的测试（`pi/tests/`）只留在本机。新增配置时先检查是否含凭证，再在 `.gitignore` 中显式放行。
- 配置文件按功能分组，分组标题沿用 `fish/config.fish` 的 `# ── 类别 ──…` 样式；Lua 文件使用 `--` 注释符。

### 离线测试

测试只使用临时目录和 mock，不执行真实的更新或清理：

```sh
fish --no-config --no-execute fish/functions/u.fish
python3 fish/tests/runtime.test.py
python3 fish/tests/sync-skills.test.py
python3 herdr/plugins/local/test_refresh.py
python3 herdr/plugins/local/fm-short-label/test_short_label.py
python3 herdr/plugins/local/sidebar-short-title/test_short_title.py
```
