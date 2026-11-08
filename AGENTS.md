# AGENTS.md

ANRlm 的 macOS（Apple Silicon）个人配置仓库。各目录通过符号链接部署到应用的配置位置，改仓库文件即改本机配置。

## 规则

- 仓库固定在 `~/dotfiles`，符号链接和 `u` 依赖这个路径。
- 仓库只放配置；凭证、会话、缓存、插件下载留在本机，由 `.gitignore` 排除。
- 配置文件按功能分组，分组标题用 `fish/config.fish` 的 `# ── 类别 ──…` 样式；Lua 文件用 `--` 注释。`fish/config.fish` 只保留分组标题，不写其他注释。
- 登录、密钥、系统授权、覆盖已有配置由本人执行：给出完整命令，等本人确认；凭据不经过 Agent。
- 改了行为就更新本文件对应小节。README 写给人看，只在目录、安装方式或常用命令变化时修改。
- 文档面向首次阅读的 Agent，只写当前配置、用途、操作与验收标准，不写沿革（「以前…现在…」「去掉了…」）。
- 「部署 Agent 工具」只在本人要求时执行，不是每台机器都装。
- 每一步满足完成标准再进入下一步。

## 部署新机器

### 1. 安装软件

前提（本人完成）：Homebrew、Git、GitHub SSH 访问、Brewfile 中 Mac App Store 应用的账户登录。

```sh
git clone git@github.com:ANRlm/dotfiles.git ~/dotfiles
brew bundle --file=~/dotfiles/Brewfile
```

完成标准：`brew bundle check --file=~/dotfiles/Brewfile` 通过，或未通过的条目已交本人确认。

### 2. 创建链接

在 Fish 中运行。目标位置已有配置时，先交本人确认再备份或移走。

```fish
mkdir -p ~/.config "$HOME/Library/Application Support/lazygit"
for dir in fish git helix mise starship yazi
    ln -s ~/dotfiles/$dir ~/.config/$dir
end
# zsh 只从 $HOME 读 .zshenv 和 .zshrc
ln -s ~/dotfiles/zsh/zshenv ~/.zshenv
ln -s ~/dotfiles/zsh/zshrc ~/.zshrc
# lazygit 只链接配置文件，其余状态留在默认位置
ln -s ~/dotfiles/lazygit/config.yml "$HOME/Library/Application Support/lazygit/config.yml"
```

完成标准：每个链接存在，`readlink` 指向 `~/dotfiles` 中的对应路径。

### 3. 安装插件

```fish
ya pkg install
pi install npm:billion-context
pi install npm:pi-web-access
pi install npm:pi-subagents
pi install npm:@narumitw/pi-starship
pi install npm:pi-btw
pi install npm:@narumitw/pi-stamp
pi install npm:@juicesharp/rpiv-ask-user-question
pi install npm:@juicesharp/rpiv-todo
```

完成标准：以上命令都返回 0。

### 4. 交给本人

- [git/config](git/config) 写有个人姓名和邮箱，换人使用前修改。
- 设 Fish 为登录 Shell：确认 `command -v fish` 的输出在 `/etc/shells` 中，再 `chsh -s (command -v fish)`。
- Pi 的模型、设置、凭证、会话不在仓库：在 Pi 中 `/login`，再设默认模型等偏好。

完成标准：本人确认以上事项已处理或不需要。

## 部署 Agent 工具

给 Claude Code、Codex、Pi、Grok 部署 skill、插件和配套命令行工具。前提：已完成「部署新机器」，当前 Shell 是加载了 `fish/config.fish` 的 Fish。

云平台工具按机器选装：阿里云（aliyun-cli、AgentLoop）、腾讯云（tccli、tcapi）、TokenHub（thcli）、百炼（bl）和 ego lite 只在开发机部署，部署前问我本机是否需要。不装的机器跳过下文中它们的安装命令、skill、Grok `[skills].disabled` 配置和完成标准；`u` 按对应 CLI 是否存在跳过它们，不会自动补装。

### 约定

skill 统一放在共享目录 `~/.agents/skills`：

| Agent | 读取方式 | 注意 |
| --- | --- | --- |
| Codex、Pi、Grok | 直接读共享目录 | 不在 `~/.codex/skills`、`~/.pi/agent/skills`、`~/.grok/skills` 建指向共享目录的链接，否则重复加载。Grok 还通过 Claude 兼容层读取 `~/.claude` 中的 skill、插件、Hook 和 MCP 配置 |
| Claude Code | 读取 `~/.claude/skills` | 每个 skill 需要指向共享目录的链接，由 `__u_sync_skills` 补齐；同步函数固定使用默认目录 |

- 按上游推荐的方式安装，且必须能由 `u` 更新。上游有插件就装插件；只发布 skill 的用 `npx skills add <来源> -g -a claude-code -a codex -a pi -y`（放进共享目录、给 Claude 建链接、记入 `~/.agents/.skill-lock.json`）。
- 同一个 skill 只装一份：插件已提供的 skill 不放进共享目录；Pi、Grok 用 Pi 包、Grok 插件装同一份。`__u_sync_skills` 不给 Claude 插件自带的 skill 建链接。Codex 和 Pi 按真实路径去重。
- `claude`、`grok` 必须分别解析到 `~/.local/bin/claude`、`~/.local/bin/grok`。cchost 管理默认目录 `~/.claude`、`~/.grok`，Claude 全局状态在 `~/.claude.json`。
- `fish/config.fish` 清除 `CLAUDE_CONFIG_DIR`、`GROK_HOME`。包装脚本也清除对应的目录覆盖变量；Codex 使用独立的 cchost Profile。
- `jq` 用 macOS 自带的 `/usr/bin/jq`，`u` 用它解析 Claude 插件列表。

完成标准：`command -v claude codex pi grok node jq` 每项有输出（装了云平台工具的机器还有 `aliyun tccli`），`claude`、`grok` 分别为 `~/.local/bin/claude`、`~/.local/bin/grok`；`set -q CLAUDE_CONFIG_DIR`、`set -q GROK_HOME` 均返回 1（未设置）。

### A1. 命令行工具与应用

| 工具 | 安装 | 首次配置（本人执行） |
| --- | --- | --- |
| aliyun-cli | Brewfile；再 `aliyun plugin install --names agentloop` | `aliyun configure` |
| tccli | Brewfile | `tccli auth login` |
| lark-cli | `npm install -g @larksuite/cli` | 登录命令见 lark-shared skill |
| thcli（TokenHub） | `npm install -g tencent-tokenhub-cli` | `thcli auth login` |
| bl（百炼） | `npm install -g bailian-cli`（不用 pnpm） | `bl auth login --console`，再 `bl auth status --output json` 确认 |
| ego lite | 从[官网](https://lite.ego.app/)下载 `ego lite.app` | 在应用中完成首次引导，它把 `ego-browser` 放进 `~/.local/bin` |
| Rex | 安装 `Rex Beta.app` | 打开一次应用，`rex` 命令随应用提供 |

完成标准：`aliyun version`、`tccli --version`、`lark-cli --version`、`thcli --version`、`bl --version` 都能运行；`aliyun plugin list` 含 `aliyun-cli-agentloop`；`command -v ego-browser rex` 有输出；本人已确认首次配置。

### A2. Skill

```fish
npx skills add humanlayer/skills --skill show-me -g -a claude-code -a codex -a pi -y
# Claude 用 answer-me-with-html 插件（A3），这份 skill 给其他三个 Agent
npx skills add QingYunA/answer-me-with-html -g -a codex -a pi -y
source ~/dotfiles/fish/functions/u.fish
__u_add_skill_families
thcli +connect --target ~/.agents/skills
bl skill init
npx clawhub --workdir ~/.agents --dir skills install @tencent-adm/tencentcloud-api-skill
rex skill setup
ln -s "$HOME/Library/Mobile Documents/com~apple~CloudDocs/Agent Skills/cchost-env" ~/.agents/skills/cchost-env
__u_sync_skills
```

| skill | 说明 |
| --- | --- |
| show-me | 只能手动调用（`/show-me`） |
| answer-me-with-html | 把回答渲染成 HTML 页面，需要 Node 20+；设置用 `/answer-me-with-html config` |
| `__u_add_skill_families` | 飞书全部 skill，删掉只转交 `lark-meeting` 的 `lark-minutes`、`lark-note`、`lark-vc`、`lark-vc-agent`；装了 `aliyun` 时再装 `aliyun/alibabacloud-aiops-skills` 的 `alibabacloud-cli-guidance` 和全部 `alibabacloud-agentloop-*` |
| `thcli-*` | TokenHub skill，thcli 自带 |
| `bailian-*` | 百炼仓库的全部 `bailian-*`。实体在 `~/.bailian/skills`，bl 在共享目录、`~/.claude/skills`、`~/.codex/skills`、`~/.grok/skills`、`~/.pi/agent/skills` 各建一个链接 |
| `tcapi` | 腾讯云 API，依赖 tccli。官方只在 ClawHub 发布，GitHub 同名仓库是非官方翻译版 |
| ego-browser | ego lite 首次引导时创建：`~/.agents/skills/ego-browser` 链接到应用自带的 skill |
| cchost-env | 本人维护，源码在 iCloud Drive 的 `Agent Skills/cchost-env`，不在本仓库，也不由 `u` 更新；共享目录中是指向它的链接，链接前须等 iCloud 同步完该目录 |
| rex | 存根，内容每次从 `rex` 命令读取。`rex skill setup` 还给 Claude Code、Codex 装会话启动钩子，Codex 的钩子由本人在 `/hooks` 中信任 |

`__u_sync_skills` 递归查找共享目录的 `SKILL.md`（含 `@tencent-adm/...` 作用域目录），在 `~/.claude/skills` 建同名链接，已有正确链接不动；继承的 `CLAUDE_CONFIG_DIR` 不改变同步目标。user 作用域 Claude 插件自带的 skill 不建链接，已有的删除。遇到同名目录、指向别处的链接或坏链接时报告冲突并返回失败，不覆盖文件；冲突交本人确认。

百炼 skill 里有名为 `skill.md` 的文档页；macOS 路径不区分大小写，Grok 把其中两页当成 skill（Codex、Pi 只认 `SKILL.md`）。在 `~/.grok/config.toml` 末尾加：

```toml
[skills]
# Bailian doc pages named skill.md, not real skills (macOS paths ignore case).
disabled = ["reference", "agent-store"]
```

完成标准：

- 以上命令返回 0。
- `npx skills ls -g` 不含 mattpocock 的 skill 和 `bailian-*`；`bl skill list` 中 `bailian-*` 都为 installed。
- `~/.agents/skills/@tencent-adm/tencentcloud-api-skill/.clawhub/origin.json` 的 `ownerHandle` 为 `tencent-adm`。
- `rex skill status` 中 Claude Code、Codex 的 skill 和 hook 都为 current。
- 共享目录中除 Claude 插件已提供的以外，每个 skill 在 `~/.claude/skills` 有同名链接，无坏链接。
- `~/.codex/skills`、`~/.pi/agent/skills`、`~/.grok/skills` 无指向 `~/.agents/skills` 的链接（Codex 的 `.system/` 和 bl 指向 `~/.bailian/skills` 的链接除外）。
- 在 Git 仓库外运行 `grok inspect`，Skills 列出共享目录全部 skill，`reference`、`agent-store` 为 `[disabled]`。

### A3. 插件

ponytail、mattpocock 四个 Agent 都装；context7（文档查询 MCP）和 answer-me-with-html 只在 Claude Code 中安装。Grok 通过兼容层加载这两者及 context7 MCP，无需独立安装；同名插件优先使用 Grok 自身的 user 作用域版本。`~/.grok/config.toml` 的 `[skills].ignore` 含 `~/.agents/skills/answer-me-with-html`，只加载插件提供的同名 skill；`[compat.claude].hooks = false` 不运行 Claude 专用的额度 Hook（Grok 不支持其中的 `async`），Grok 额度由自己的状态栏显示。

| 名称 | Claude Code | Codex | Pi | Grok |
| --- | --- | --- | --- | --- |
| ponytail | `claude plugin marketplace add DietrichGebert/ponytail`，`claude plugin install ponytail@ponytail` | `codex plugin marketplace add DietrichGebert/ponytail`，`codex plugin add ponytail@ponytail` | `pi install npm:@dietrichgebert/ponytail` | `grok plugin install DietrichGebert/ponytail --trust`，`grok plugin enable ponytail` |
| mattpocock | `claude plugin marketplace add mattpocock/skills`，`claude plugin install mattpocock-skills@mattpocock` | `codex plugin marketplace add mattpocock/skills`，`codex plugin add mattpocock-skills@mattpocock` | `pi install git:github.com/mattpocock/skills`，再加过滤（见下） | `grok plugin install mattpocock/skills --trust`，`grok plugin enable mattpocock-skills` |
| context7 | `claude plugin install context7@claude-plugins-official` | — | — | — |
| answer-me-with-html | `claude plugin marketplace add QingYunA/answer-me-with-html`，`claude plugin install answer-me-with-html@answer-me-with-html` | — | — | — |

- ponytail 的常驻模式靠会话启动钩子或 Pi 扩展，所以装插件而不是 `npx skills add`。Codex 装完由本人在 `/hooks` 中信任钩子并新开会话。Grok 的钩子不能注入指令，ponytail 在 Grok 中不常驻，靠模型调用或手动 `/ponytail`。`fish/config.fish` 设 `PONYTAIL_HIDE_STATUS=1`，Pi 状态栏不显示 ponytail 状态条（规则照常生效，`/ponytail status` 查级别，改后重开 Pi）。
- mattpocock 只装稳定版（`skills/engineering/`、`skills/productivity/`），插件清单本身只含稳定版。四个 Agent 都从作者仓库装；`claude-plugins-official` 中的同名插件固定在较早的提交，不用。Pi 包会递归发现仓库全部 skill，所以把 `~/.pi/agent/settings.json` 的 `packages` 中它的条目改成：

  ```json
  {
    "source": "git:github.com/mattpocock/skills",
    "skills": ["skills/engineering/*", "skills/productivity/*"]
  }
  ```

完成标准：

- `claude plugin list` 的 user 作用域只有 ponytail、mattpocock-skills、context7、answer-me-with-html；`~/.claude/skills` 无这些插件自带 skill 的链接。
- `codex plugin list` 中 `ponytail@ponytail`、`mattpocock-skills@mattpocock` 为 installed, enabled。
- `pi list` 含 `npm:@dietrichgebert/ponytail` 和 `git:github.com/mattpocock/skills (filtered)`。
- 在 Git 仓库外运行 `grok inspect`，Plugins 含 ponytail、mattpocock-skills（来自 `~/.grok/installed-plugins`）以及 context7、answer-me-with-html（来自 `~/.claude/plugins`），均为 user、enabled；MCP Servers 含 context7。

### A4. 收尾

重启 Claude Code、Codex、Grok 会话；在 Pi 中 `/reload`。带 `disable-model-invocation: true` 的 skill（如 show-me）不在模型自动选择清单中，不代表未加载。

完成标准：四个 Agent 都能看到上述 skill 和插件；钩子信任、登录、系统权限已由本人确认。

## 修改配置前要知道的

### Shell 与 Node

- 缩写和函数在 [fish/config.fish](fish/config.fish) 和 [fish/functions/](fish/functions/)。`claude` 展开为 `claude --allow-dangerously-skip-permissions`。
- PATH 在 `fish/config.fish` 开头设定，对所有 Fish Shell 生效：`~/.local/bin` 在最前，其中的 cchost 包装脚本（`claude`、`grok` 等）优先于 Homebrew 的同名命令。
- Agent 相关环境变量在 `fish/config.fish` 的 Agents 一节。Claude Code、Codex 的 Shell（带 `CLAUDECODE` 或 `CODEX_THREAD_ID`）从钥匙串读取 1Password 服务账号令牌，导出为 `OP_SERVICE_ACCOUNT_TOKEN`；本人的 Shell 不导出，`op` 走 App 集成。这两个 Agent 在 zsh 中执行命令，[zsh/zshenv](zsh/zshenv) 有同样的判断。
- 全局 Node 和 pnpm 来自 Homebrew。交互式 Shell 中 mise 按项目的 `.node-version` / `.nvmrc` 切换 Node，缺版本时在项目目录 `mise install`。pnpm 版本跟随 `package.json` 的 `packageManager`。

### 终端工具

- **Helix** 的复制写入系统剪贴板。普通模式 `h`/`l` 停在行首/行尾，不跨行；Helix 没有这个选项，两个键绑定为命令组合，多光标时只剩一个光标（`h` 留最下面的，`l` 留最上面的），此时用 `←`/`→`。
- **Starship** 配置是官方 `nerd-font-symbols` 预设，用 `starship preset nerd-font-symbols` 重新生成；终端要用 Nerd Font（Brewfile 有 JetBrains Mono、Meslo 的 Nerd Font）。
- **Git** 全局忽略 `.env`、`.env.*`、`*.key`、`*.pem` 等凭证文件，放行 `.env.example`、`.env.template`。
- **lazygit** 不读 `core.pager`，Delta 在 [lazygit/config.yml](lazygit/config.yml) 中单独配置。Diff 视图关闭自动换行：lazygit 的续行从第 0 列开始，会盖住 Delta 的行号栏。

### Pi

扩展装在 `~/.pi/agent/npm/`（Git 包在 `~/.pi/agent/git/`），条目在 `~/.pi/agent/settings.json` 的 `packages` 中，不带版本号。ponytail、mattpocock 见 A3。

| 包 | 作用 |
| --- | --- |
| `@narumitw/pi-starship` | 状态栏，见下文 |
| `pi-btw` | `/btw <问题>`（别名 `/side`）开带工具的并行子会话，不打断主线程。`/btw:tangent` 不继承上下文，`/btw:ask` 只读；`/btw:inject` 或 `/btw:summarize` 注回主对话，否则不进主上下文 |
| `billion-context` | 上下文压缩：`compress`、`decompress`、`search_context`、`acp_status`、`acp_cache`，把已消耗的对话换成摘要。配置 `~/.pi/agent/billion-context.json`，缺省用默认值 |
| `pi-web-access` | 联网：`web_search`、`fetch_content`、`get_search_content`、`source_check`。provider 和代理读 `~/.pi/agent/web-search.json`，缺省用环境变量或默认 provider；缓存在 `~/.pi/agent/web-search-cache/` |
| `pi-subagents` | `subagent` 委派子会话，配 `bg_wait`、`contact_supervisor`、`subagent_supervisor`；附 `council-mode`、`pi-subagents` 两个 skill，用法见包内 `docs/` 和 `/subagents-guide` |
| `@narumitw/pi-stamp` | 消息右侧时间戳，可选响应耗时、模型、用量、工具耗时；只写会话记录，不进模型上下文 |
| `@juicesharp/rpiv-ask-user-question` | `ask_user_question`：结构化选项弹窗，最多四题，每题可自定义答案 |
| `@juicesharp/rpiv-todo` | `todo` 工具和 `/todos`：输入框上方常驻任务面板，列表从对话重建 |

- 两个 rpiv 包带入 `@juicesharp/rpiv-config` 和 `rpiv-i18n`（`/languages`），不是独立条目。
- 不用 `@narumitw/pi-plan-mode`：它默认拦截其他扩展的工具，进入 `/plan` 后 `todo`、`ask_user_question` 失效，除非在 `/plan tools` 中逐个启用。
- `pi-starship` 的配置在 `~/.pi/agent/pi-starship.toml`，不在本仓库。没有配置文件时保留 Pi 原生 footer，在 `/starship` 中选定预设或保存后才接管。`/starship` 预览预设、管理 profile、开配置会话；`/starship settings` 编辑 TOML；`/starship status` 看生效来源和诊断；`/starship help` 看字段说明；改写字段用包内 skill `/skill:configure-pi-starship`。它和 `@narumitw/pi-statusline`、`pi-powerline-footer` 占同一个 footer，同时装只有最后加载的生效。

## 更新

`u`（[fish/functions/u.fish](fish/functions/u.fish)）按顺序执行；本机没有的工具对应的步骤跳过，单步失败不中断，结束时返回失败；不拉取本仓库。

1. **Homebrew**：更新、`brew upgrade --greedy`（含自更新的 cask，以及 aliyun-cli、tccli）、清理，把本机新装的软件追加进 Brewfile。
2. **Node**：更新 npm 全局包（含 lark-cli、thcli、bl），清理 pnpm store，在 `$HOME` 中按全局 mise 配置升级工具（不改项目的 `mise.toml` 和 `.node-version` 等精确版本）。
3. **Agent skill 与插件**：
   1. `__u_update_skills`：`npx skills update -g -y`，再删掉它报告为上游已删除的 skill。
   2. `__u_add_skill_families`：`npx skills update` 只更新已装的 skill，所以重装飞书整组（装了 `aliyun` 时连同 AgentLoop 整组），补上新增的。
   3. `npx clawhub … update --all --force`：装了 `tccli` 时更新 tcapi，覆盖本地改动。
   4. `thcli +connect --target ~/.agents/skills`
   5. `bl skill init`：重装全部 `bailian-*`，含新增的；`bl skill update` 不修复本地改过的文件，不用。
   6. `rex skill setup`：刷新 Rex 的 skill 存根和钩子。
   7. `aliyun plugin update`：更新 aliyun-cli 全部插件，含 AgentLoop。
   8. `__u_sync_skills`，再更新 Claude 插件市场和插件：user 作用域直接更新；project / local 作用域进入对应项目目录更新，目录不存在时跳过。
   9. `codex plugin marketplace upgrade`
   10. `pi update --extensions`：更新 `~/.pi/agent/settings.json` 中全部 Pi 包。
   11. `grok plugin update`

   `~/.agents/skills` 不存在时跳过 1–6 和 `__u_sync_skills`。

4. **uv** 缓存清理、**Mac App Store** 应用。
5. **Yazi** 插件（最多重试三次），最后 **Mole** 清理。

ego lite 和 Rex 是应用，`u` 不更新，它们的 skill 随应用版本变化。ego lite 用 `ego-browser upgrade` 更新；它可能弹窗确认并重启浏览器，所以不放进 `u`。

Brewfile 是全量清单，按 tap、brew、cask、mas 分类，本机只装一部分。`u` 只把新条目追加到同类末尾，从不删除，不记录 npm 全局包。卸载软件后手动删除对应行。

## 测试

改了 `u.fish` 就运行。全部离线，只用临时目录和 mock：

```sh
fish --no-config --no-execute fish/functions/u.fish
python3 fish/tests/runtime.test.py
python3 fish/tests/sync-skills.test.py
```
