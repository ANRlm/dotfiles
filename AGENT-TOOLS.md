# Agent 工具部署清单

本文件供新机器上的 Agent 读取后部署 Claude Code、Codex、Pi、Grok 的 skill、插件和配套命令行工具。按步骤顺序执行，每一步满足「完成标准」后再进入下一步。

需要登录、密钥或系统授权的操作由本人执行：Agent 给出完整命令，等待本人确认已完成，凭据不经过 Agent。

## 约定

所有 skill 实体只放在共享目录 `~/.agents/skills`，各 Agent 的读取方式不同：

| Agent | 读取方式 | 注意 |
| --- | --- | --- |
| Codex、Pi | 原生读取共享目录 | `~/.codex/skills`、`~/.pi/agent/skills` 保持原样，不建指向共享目录的链接，否则同一个 skill 会加载两次 |
| Grok | 原生读取共享目录 | `~/.grok/skills` 同样不建链接；ego lite 应用自己放在这里的 `ego-browser` 链接与共享目录同名，Grok 按名称去重，保留不动。它的 Claude 兼容层只扫描固定的 `~/.claude/skills`，看不到 Claude 的 skill 链接和插件 |
| Claude Code | 只读取 `$CLAUDE_CONFIG_DIR/skills` | 每个 skill 需要一个指向共享目录的符号链接。`CLAUDE_CONFIG_DIR` 由 `fish/config.fish` 设置，本机为 `~/.claude-profiles/default`；未设置时 Claude 使用 `~/.claude` |

- **安装方式**：skill 一律用 `npx skills add <来源> -g -a claude-code -a codex -a pi -y` 安装。它把内容放进共享目录，给 Claude 建链接，并写入 `~/.agents/.skill-lock.json`，之后由 `u` 统一更新。插件市场只用于带钩子的 ponytail 和 Claude 官方插件 context7。
- **例外**：cua-driver 只给 Claude Code 使用，skill 实体放在共享目录之外。

## 1. 前置条件

1. 已按 [README](README.md) 部署 dotfiles，并执行过 `brew bundle --file=~/dotfiles/Brewfile`。Brewfile 已包含 `claude-code@latest`、`codex`、`pi-coding-agent`、`grok-build`（命令为 `grok`）、`node`、`aliyun-cli`、`tccli` 和 Orca 应用。
2. 当前 Shell 是加载了 `fish/config.fish` 的 Fish。
3. `jq` 可用（macOS 自带 `/usr/bin/jq`）：`u` 用它解析 Claude 的插件列表。

**完成标准**：`command -v claude codex pi grok node aliyun tccli jq` 每项都有输出；`echo $CLAUDE_CONFIG_DIR` 输出上面约定的目录。

## 2. 命令行工具与应用

| 工具 | 安装 | 首次配置（本人执行） |
| --- | --- | --- |
| aliyun-cli | Brewfile | `aliyun configure` |
| tccli | Brewfile | `tccli auth login` |
| Orca | Brewfile | 在应用中安装自带的 `orca` 命令行和 skill，不需要另外部署 |
| lark-cli | `npm install -g @larksuite/cli` | 登录命令见 lark-shared skill |
| thcli（TokenHub） | `npm install -g tencent-tokenhub-cli` | `thcli auth login` |
| Cua Driver | `curl -fsSL https://cua.ai/driver/install.sh \| bash` | `cua-driver permissions grant`，授予辅助功能和屏幕录制权限 |
| ego lite | 从 [官网](https://lite.ego.app/) 下载安装 `ego lite.app` | 在应用中完成首次引导，它会把 `ego-browser` 命令注册到 `~/.local/bin` |

**完成标准**：`aliyun version`、`tccli --version`、`lark-cli --version`、`thcli --version`、`cua-driver --version` 都能运行，`command -v orca ego-browser` 每项都有输出（npm 安装成功不代表二进制已在 PATH 中）；需要本人执行的首次配置均已确认完成。

## 3. Skill

### 3.1 用 npx skills 安装

```fish
# mattpocock skills：Claude 和 Codex 的 mattpocock 插件提供同样的 skill，只用这一种安装方式
npx skills add mattpocock/skills --skill '*' -g -a claude-code -a codex -a pi -y
# show-me：只在手动调用时生效
npx skills add humanlayer/skills --skill show-me -g -a claude-code -a codex -a pi -y
npx skills add vercel-labs/skills --skill find-skills -g -a claude-code -a codex -a pi -y
# lark skills：飞书官方，依赖 lark-cli
npx skills add https://open.feishu.cn/lark-cli/skills/regular --skill '*' -g -a claude-code -a codex -a pi -y
# 阿里云 CLI / AgentLoop：依赖 aliyun-cli
npx skills add aliyun/alibabacloud-aiops-skills --skill alibabacloud-cli-guidance --skill alibabacloud-agentloop-management --full-depth -g -a claude-code -a codex -a pi -y
npx skills add herdrdev/herdr --skill herdr -g -a claude-code -a codex -a pi -y
# ego-browser：浏览器自动化，依赖 ego lite 应用
npx skills add citrolabs/ego-lite -g -a claude-code -a codex -a pi -y
```

### 3.2 其他来源

| 名称 | 安装 | 说明 |
| --- | --- | --- |
| TokenHub（`thcli-*`） | `thcli +connect --target ~/.agents/skills` | thcli 自带 |
| 腾讯云 API（tcapi） | 从 [ClawHub](https://clawhub.ai/user/tencent-adm) 安装 `@tencent-adm/tencentcloud-api-skill` 到 `~/.agents/skills/@tencent-adm/tencentcloud-api-skill` | 官方只在 ClawHub 发布，GitHub 上的同名仓库是非官方翻译版。依赖 tccli |
| cua-driver | Cua Driver 自带，实体位于 `~/.cua-driver/skills/cua-driver` | 只链接给 Claude Code，见 3.3 |

### 3.3 给 Claude 建链接

共享目录中的 skill（包括 thcli、tcapi、Orca、no-mistakes 等不经过 `npx skills` 的）靠这一步补齐 Claude 链接。在 Fish 中运行：

```fish
source ~/dotfiles/fish/functions/u.fish
__u_sync_skills
```

`__u_sync_skills` 递归查找 `SKILL.md`，支持 `@tencent-adm/...` 这类作用域目录，已有的指向同一实体的链接保持不变。遇到同名目录、指向其他位置的链接或坏链接时，它报告冲突并返回失败，不覆盖任何文件；把冲突列给本人确认后再处理。

cua-driver 单独链接。`cua-driver skills install/update` 会同时给其他 Agent 建链接，所以改用：

```fish
mkdir -p "$CLAUDE_CONFIG_DIR/skills"
test -e "$CLAUDE_CONFIG_DIR/skills/cua-driver"; or ln -s ~/.cua-driver/skills/cua-driver "$CLAUDE_CONFIG_DIR/skills/cua-driver"
```

**完成标准**：

- `npx skills ls -g` 列出 3.1 中安装的所有 skill。
- `~/.agents/skills/@tencent-adm/tencentcloud-api-skill/.clawhub/origin.json` 中 `ownerHandle` 为 `tencent-adm`。
- `__u_sync_skills` 返回 0；共享目录中的每个 skill 在 `$CLAUDE_CONFIG_DIR/skills` 都有同名链接，且没有坏链接。
- `$CLAUDE_CONFIG_DIR/skills/cua-driver` 指向 `~/.cua-driver/skills/cua-driver`；cua-driver 不出现在 Codex 和 Pi 的 skill 目录中。
- `~/.codex/skills`、`~/.pi/agent/skills` 和 `~/.grok/skills` 中没有指向 `~/.agents/skills` 的链接（Codex 自带的 `.system/` 和 ego lite 的 `ego-browser` 不算）。
- 在 Git 仓库之外运行 `grok inspect`，Skills 一节列出共享目录中的全部 skill，且没有 cua-driver。

## 4. 插件与 MCP

只给 Claude Code 和 Codex 装，Grok 不装插件和 MCP。

| 名称 | Claude Code | Codex | 说明 |
| --- | --- | --- | --- |
| ponytail | `claude plugin marketplace add DietrichGebert/ponytail`，再 `claude plugin install ponytail@ponytail` | `codex plugin marketplace add DietrichGebert/ponytail`，再 `codex plugin add ponytail@ponytail` | 常驻模式依赖会话启动钩子，因此装成插件 |
| context7 | `claude plugin install context7@claude-plugins-official` | — | 自带文档查询 MCP |
| Cua Driver MCP | `claude mcp add --scope user cua-computer-use -- ~/.local/bin/cua-driver mcp` | — | 只给 Claude Code |

Codex 装完 ponytail 后，由本人在 Codex 的 `/hooks` 中信任它的两个生命周期钩子，并新开会话。

**完成标准**：

- `claude plugin list` 只有 ponytail 和 context7。
- `~/.codex/config.toml` 中没有 `mattpocock` 市场或插件。
- `claude mcp list` 中 `cua-computer-use` 显示已连接。
- `grok inspect` 的 Plugins 和 MCP Servers 两节均为 None。

## 5. Firstmate

[Firstmate](https://github.com/kunchenguid/firstmate) 让一个 Agent 担任「大副」，统一派发和监督多个编码 Agent。仓库本身就是发行版，没有单独的安装程序。

1. **克隆**：本人完成 `gh auth login` 后，执行 `git clone https://github.com/kunchenguid/firstmate ~/firstmate`。
2. **启动**：在 Herdr 的终端中进入 `~/firstmate`，运行 `claude`、`pi` 或 `codex` 之一作为主会话；在 Herdr 内启动时，worker 会自动开在 Herdr 里。
   - 同一时间只运行一个主会话；要换一个 Agent 当主会话，先退出原来的。
   - 首次启动时，项目目录的信任提示由本人确认；用 Pi 时，还要信任仓库自带的扩展。
3. **依赖**：首次启动时，Firstmate 会列出缺少的工具和安装命令，经本人同意后安装：
   - `treehouse` 和 `no-mistakes`：官方 curl 安装器；
   - `gh-axi`、`tasks-axi`、`quota-axi`、`chrome-devtools-axi`、`lavish-axi`：`npm install -g`。

   上游建议的 `<工具> setup hooks` 会改动各 Agent 的全局设置，本机没有执行；需要时由本人决定。
4. **私有数据**：`~/firstmate` 下的 `data/`、`config/`、`projects/`、`state/` 被它自己的 Git 忽略，不随 dotfiles 迁移，其中包括项目登记、二副（工作区在 `~/.treehouse`）和本机配置。新机器上在 Firstmate 会话里重新登记项目、重新创建二副。

**完成标准**：Firstmate 主会话在 Herdr 中启动，依赖检查不再报告缺少的工具。

## 6. 收尾

1. 重启 Claude Code、Codex 和 Grok 会话。
2. 在 Pi 中执行 `/reload`，再用 `pi list` 确认 Pi 扩展包。

带 `disable-model-invocation: true` 的 skill 只能手动调用，不会出现在模型的自动选择清单中，这不代表未加载。

**完成标准**：四个 Agent 都能看到上面安装的 skill 和插件；钩子信任、登录和系统权限均已由本人确认。

## 更新

`u` 的「Agent skills & plugins」一节依次执行：

1. `npx skills update -g -y`
2. `thcli +connect --target ~/.agents/skills`
3. `__u_sync_skills`，给新增的 skill 补齐 Claude 链接
4. 更新 Claude 插件市场和已安装的插件
5. `codex plugin marketplace upgrade`
6. `pi update --extensions`
7. `cua-driver update --apply`

lark-cli、thcli 和 Firstmate 依赖的 `*-axi` 工具由 `u` 的 Node 一节随 npm 全局包更新，Brewfile 中的工具（包括 Orca）随 Homebrew 更新。

以下几项需要手动更新：

- **Firstmate**：在 Firstmate 会话中执行 `/updatefirstmate`，会同时更新所有二副。
- **no-mistakes 本体**：`no-mistakes update` 会重启检查服务，在空闲时执行。
- **tcapi**：重新从 ClawHub 官方来源安装；`npx skills update` 不更新它。
- **cua-driver skill 包**：`cua-driver update --apply` 只更新二进制，不刷新 skill 包；刷新后确认链接仍只在 Claude 中。
- **上游已删除的 skill**：`npx skills update -g -y` 会保留本机副本并告警，确认不再需要后再删除。

修改 `__u_sync_skills` 后运行 `python3 fish/tests/sync-skills.test.py`，它只操作临时目录；完整的离线测试列表见 [README](README.md#离线测试)。
