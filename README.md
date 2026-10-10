# dotfiles

Apple Silicon macOS 的个人配置，通过符号链接部署到各应用的配置位置。

## 配置

| 目录 / 文件 | 内容 |
| --- | --- |
| [cmux/](cmux/) | 应用设置、Tab 快捷键及 cmux 专用终端配置 |
| [fish/](fish/) | 环境变量、PATH、工具集成、缩写及辅助函数 |
| [ghostty/](ghostty/) | 字体、主题、窗口和剪贴板 |
| [git/](git/) | 用户信息、Delta、同步策略及全局忽略规则 |
| [helix/](helix/) | 主题、编辑行为、诊断和快捷键 |
| [herdr/](herdr/) | 界面、通知、快捷键、automatic-rename 插件配置及 firstmate 短标签插件 |
| [lazygit/](lazygit/) | 差异渲染器（Delta）配置 |
| [pi/](pi/) | 对话滚动快捷键与自定义状态栏扩展 |
| [starship/](starship/) | 提示符及各模块的符号 |
| [tmux/](tmux/) | 终端、窗口、快捷键及 TPM 插件 |
| [yazi/](yazi/) | 文件管理、预览、快捷键及插件清单 |
| [Brewfile](Brewfile) | Homebrew、Cask 和 Mac App Store 软件清单 |
| [AGENT-TOOLS.md](AGENT-TOOLS.md) | Claude Code、Codex、Pi 的 skill、插件、配套命令行工具及 Firstmate 部署清单 |

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
ln -s ~/dotfiles/herdr/plugins/config/herdr-automatic-rename ~/.config/herdr-automatic-rename
```

Pi、cmux 和 lazygit 使用**文件级链接**，不要链接整个配置目录，以免将凭证、会话和缓存放进仓库。同样先备份或移走目标位置的同名文件，再运行：

```fish
mkdir -p ~/.pi/agent/extensions ~/.config/cmux "$HOME/Library/Application Support/com.cmuxterm.app" "$HOME/Library/Application Support/lazygit"
ln -s ~/dotfiles/pi/keybindings.json ~/.pi/agent/keybindings.json
ln -s ~/dotfiles/pi/extensions/minimal-statusline.ts ~/.pi/agent/extensions/minimal-statusline.ts
ln -s ~/dotfiles/cmux/cmux.json ~/.config/cmux/cmux.json
ln -s ~/dotfiles/cmux/config.ghostty "$HOME/Library/Application Support/com.cmuxterm.app/config.ghostty"
ln -s ~/dotfiles/lazygit/config.yml "$HOME/Library/Application Support/lazygit/config.yml"
```

`cmux/config.ghostty` 是 cmux 专用配置，与 `ghostty/config.ghostty` 分开管理；不要互相覆盖。Pi 的 `settings.json`（默认模型、主题等）、`models.json`、`auth.json`、会话、模型缓存、其他扩展和 skills，以及 cmux 和 lazygit（`state.yml`、PR 缓存）的运行数据留在本机。本仓库仅部署 Pi 快捷键和 `minimal-statusline.ts`，不链接整个扩展目录。新机器需单独执行 Pi 的 `/login` 并设置模型等偏好。

Git 配置包含个人姓名和邮箱，使用前请检查 [git/config](git/config)。Lazygit 不读取 `core.pager`，其 Delta 渲染器须在 [lazygit/config.yml](lazygit/config.yml) 中单独配置；该文件还关闭了 Diff 视图的自动换行——Delta 只在 side-by-side 模式下自行折行，lazygit 折行时续行从第 0 列开始，会压掉 Delta 的行号栏。

如需将 Fish 设为登录 Shell，先确认 `command -v fish` 的路径已列在 `/etc/shells`，再运行：

```fish
chsh -s (command -v fish)
```

安装 Yazi 和 herdr 插件：

```fish
ya pkg install
herdr plugin install qu8n/herdr-automatic-rename
herdr plugin link ~/dotfiles/herdr/plugins/local/fm-short-label
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
| `u` | 更新全局工具、应用、Agent skill 与插件及 Herdr / tmux / Yazi 插件，并执行清理 |

Pi 全屏模式下，`Option+K/J` 向上／下滚动一行，修改配置后在 Pi 中运行 `/reload`。cmux 中，`Option+H/L` 切换上一个／下一个 Tab，修改配置后执行 `cmux reload-config`。cmux 不拦截 `Option+J/K`，它们仅在 Pi 内绑定。

### Pi 状态栏

状态栏采用一种完整布局，不区分预设或详情视图，也不再读取／写入旧的 `~/.pi/agent/statusline.json`。修改扩展后执行 `/reload` 即可生效，无需选择预设。

```text
路径 [分支]                         ↑输入 ↓输出 · ≈$成本 · cache 命中率 · r 缓存读 w 缓存写
ctx 剩余/窗口 进度条 剩余% left · auto in ≈余量        活动 · 本轮耗时 · ~tok/s · 模型 · effort
```

布局示意，实际显示随用量数据、活动状态和可用宽度调整：

- 第一行：左侧路径、分支；右侧会话累计 token（`↑` 输入 / `↓` 输出）、估算成本、最近一次 assistant 请求的 `cache` 命中率、缓存读写（`r`/`w`）。单次低命中不标警告。
- 第二行：左侧为 ctx 模块；右侧为活动、本轮累计耗时、生成中的 `~tok/s`、模型和 effort。空闲时仍显示模型和 effort。
- 内置活动文案统一为英文：`waiting`、`thinking`、`streaming`、`tool` / `tools×N`、`compacting`、`finishing`。并行／嵌套工具按调用 ID 跟踪，直到 `agent_settled` 才结束计时。Pi 1.1.0 没有专用重试通知事件，因此不猜测重试状态；`waiting` / `finishing` 也不表示已经完全结束。

宽度足够时主体为两行；路径／分支按列宽缩短，模型与 effort 固定优先放在第二行右侧。窄屏放不下的指标和活动追加在下方，不再通过隐藏字段或详情入口丢掉信息；极窄时长模型和 ctx 也会换行。

#### 上下文与自动压缩

ctx 使用剩余口径，例如 `ctx 108k/200k ━━━━━━━╸────── 54% left · auto in ≈91.6k`，数值与百分比表示整个窗口的剩余容量，进度条随使用量增加而缩短；`left` 明确表示剩余。`auto in ≈…` 是距自动压缩阈值的估算余量；达到阈值显示 `auto due`（不代表已经开始压缩），关闭自动压缩显示 `auto off`，实际压缩仍由活动区的 `compacting` 表示。颜色依据有效容量剩余比例：开启自动压缩时以窗口减去预留量为有效容量，否则以整个窗口为有效容量；剩余低于 30% 变黄、低于 10% 变红，只强调条形和余量，关闭自动压缩时也强调百分比。

ctx 根据右侧实际占用调整：先把条形从 14 列缩到 10／6 列，再移除条形，必要时使用 `ctx 54% left · auto ≈91.6k` 简写；连简写也放不下时，将完整数值换行展示。未知用量显示 `ctx —/200k · usage pending`，不画空条、不推断压缩阈值状态。

#### 统计口径与命令

- `≈$` 是基于模型价格配置和已上报用量的会话估算，包含历史分支、工具及压缩等记录，不是服务商账单。未上报的用量无法计入。
- 流式 `~tok/s` 沿用中英文字符权重和已有模型校准文件（`~/.pi/agent/statusline-rate.json`），仅在思考／生成时显示，结束后隐藏，避免旧速率误导。混合文本／工具样本的校准属于启发式，不能独立测出两类误差，也不是服务端精确吞吐量。
- 其他扩展状态全部显示，长文本按终端宽度换行，显式 warning/error/警告等标记优先。外部扩展原文不翻译。状态 API 没有结构化严重级别，标记识别只是启发式。
- `/statusline default` 临时恢复默认状态栏，`/statusline custom` 切回；不带参数切换；`/reload` 或重启后默认启用自定义状态栏。

#### 验证

```sh
node --test pi/tests/statusline.test.mjs
```

测试自动寻找本机 Pi 安装，也可通过 `PI_PACKAGE_DIR` 指定 `@earendil-works/pi-coding-agent` 的安装目录；不需为 dotfiles 安装依赖，测试配置和校准写入临时目录，不修改真实用户设置。覆盖深浅主题、窄宽屏、ctx 剩余口径／阈值／未知值／自适应宽度、第二行模型布局、英文活动、全部扩展状态、并行工具、会话隔离、压缩失败、旧配置兼容和开关。

### 其他工具

默认编辑器为 Helix（`hx`）。普通模式下，`Space+w` 保存、`Space+q` 退出；`Tab` / `Shift-Tab` 跳到父语法节点末尾 / 开头，选择模式下扩展选区。使用 `:config-reload` 重新加载配置。

tmux 的前缀键为 `Ctrl-A`：随后按 `=` / `-` 分屏，`h/j/k/l` 选择窗格，`r` 进入调整大小模式，再按 `h/j/k/l` 调整，`q` 或 `Escape` 退出该模式。

全局 Node 和 pnpm 由 Homebrew 管理。Fish 通过 fnm 根据项目的 `.node-version` 或 `.nvmrc` 切换 Node；首次使用未安装的版本时运行 `fnm use --install-if-missing`。

## 更新与维护

`u` 更新 Homebrew、npm 全局包、Agent skill 与插件（见 [AGENT-TOOLS.md](AGENT-TOOLS.md)）、Mac App Store 应用，以及已安装的 Herdr、tmux 和 Yazi 插件，清理 Homebrew、pnpm、uv 缓存并运行 Mole 清理。它会把本机新装的软件追加到 `~/dotfiles/Brewfile`，因此仓库需放在 `~/dotfiles`。

更新统一使用 `u`，不需要参数。tmux 插件仅执行 Git 快进更新，Yazi 更新失败最多尝试三次；某项失败会继续执行其他独立步骤，最终返回失败状态。`u` 不会拉取本仓库，配置同步需自行执行 Git 操作。

配置按功能分组，标题沿用 `fish/config.fish` 的 `# ── 类别 ──…` 样式；Lua 使用 `--` 注释符。

Brewfile 是完整软件清单，本机只装其中一部分：`u` 只追加 `brew bundle dump` 中新出现的条目（放在同类条目末尾），从不删除本机没装的条目；npm 全局包不记录。卸载软件后需手动删除对应行。各工具下载的插件、Fish 运行状态及 herdr 会话、日志和 socket 已由 `.gitignore` 排除；herdr 插件的配置（`herdr/plugins/config/`）纳入版本管理。`pi/` 和 `cmux/` 采用 `.gitignore` 白名单，仅允许 Pi 快捷键、状态栏扩展与回归测试及两份 cmux 配置；新增配置时先检查是否含凭证，再显式放行。
