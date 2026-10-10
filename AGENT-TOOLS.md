# Agent 工具与 Skill 部署清单

本文件记录本机常用的 AI Agent（Claude Code、Codex、Pi）skill、插件和配套命令行工具，供新机器上的 Agent 读取后部署。按顺序执行，每一步完成后用对应的检查方式确认。需要登录、密钥或系统授权的步骤由本人完成，Agent 只给出命令，不接收、不记录凭据。

## 目标状态

- **共享 skill 目录**：所有 skill 实体只放在 `~/.agents/skills`。
  - Codex 和 Pi 原生读取这个目录，**不要**在 `~/.codex/skills` 或 `~/.pi/agent/skills` 再建指向它的链接，否则同一个 skill 会加载两次。
  - Claude Code 只读自己配置目录下的 `skills/`，需要逐个符号链接。本机 Claude 配置目录不是 `~/.claude`，而是 `$CLAUDE_CONFIG_DIR`（`~/.claude-profiles/default`，由 `fish/config.fish` 设置）。
- **安装工具**：skill 优先用 `npx skills add <来源> -g -a claude-code -a codex -a pi -y` 安装。它把内容放进 `~/.agents/skills`，按 `CLAUDE_CONFIG_DIR` 给 Claude 建链接，并写入 `~/.agents/.skill-lock.json`，以后由 `u` 统一更新。
- **只用插件的情况**：只有带钩子的东西（ponytail）和 Claude 官方插件（context7）走插件市场；纯 skill 一律不要再装成插件。
- **命令行工具**：由 [Brewfile](Brewfile) 和 npm 全局包管理，`u` 统一更新。

## 前置条件

1. 已按 [README](README.md) 部署 dotfiles，并执行过 `brew bundle --file=~/dotfiles/Brewfile`。Brewfile 已包含 `claude-code@latest`、`codex`、`pi-coding-agent`、`node`、`rtk`、`aliyun-cli`。若缺 `tccli`，补装 `brew install tccli`。
2. `jq` 可用（`u` 更新 Claude 插件时需要）。

## Skill

| 名称 | 来源 | 安装命令 | 说明 |
| --- | --- | --- | --- |
| mattpocock skills | GitHub `mattpocock/skills` | `npx skills add mattpocock/skills --skill '*' -g -a claude-code -a codex -a pi -y` | 约 38 个。**不要**再装 Claude 或 Codex 的 mattpocock 插件，否则会重复 |
| show-me | GitHub `humanlayer/skills` | `npx skills add humanlayer/skills --skill show-me -g -a claude-code -a codex -a pi -y` | 只在手动调用时生效 |
| find-skills | GitHub `vercel-labs/skills` | `npx skills add vercel-labs/skills --skill find-skills -g -a claude-code -a codex -a pi -y` | |
| lark skills | 飞书官方 | `npx skills add https://open.feishu.cn/lark-cli/skills/regular --skill '*' -g -a claude-code -a codex -a pi -y` | 依赖 lark-cli，见下文 |
| 阿里云 CLI / AgentLoop | GitHub `aliyun/alibabacloud-aiops-skills` | `npx skills add aliyun/alibabacloud-aiops-skills --skill alibabacloud-cli-guidance --skill alibabacloud-agentloop-management --full-depth -g -a claude-code -a codex -a pi -y` | 依赖 aliyun-cli |
| herdr | GitHub `herdrdev/herdr` | `npx skills add herdrdev/herdr --skill herdr -g -a claude-code -a codex -a pi -y` | |
| TokenHub（thcli-*，12 个） | thcli 自带 | `thcli +connect --target ~/.agents/skills` | 不经过 `npx skills`；不会给 Claude 建链接，需手动补，见下文 |
| 腾讯云 API（tcapi） | ClawHub `@tencent-adm/tencentcloud-api-skill` | 从 [ClawHub](https://clawhub.ai/user/tencent-adm) 安装到 `~/.agents/skills/@tencent-adm/tencentcloud-api-skill` | 官方只在 ClawHub 发布；GitHub 上的同名仓库是非官方翻译版，不要用。依赖 tccli |
| cua-driver | Cua Driver 自带 | 安装 Cua Driver 后自动生成于 `~/.cua-driver/skills/cua-driver` | **只给 Claude Code**，见下文 |

不经过 `npx skills` 的 skill，需要手动给 Claude 建链接。路径相对 `$CLAUDE_CONFIG_DIR/skills`：

```text
thcli-<名称>          -> ../../../.agents/skills/thcli-<名称>               （12 个 thcli skill 各一个）
tencentcloud-api-skill -> ~/.agents/skills/@tencent-adm/tencentcloud-api-skill
cua-driver            -> ~/.cua-driver/skills/cua-driver
no-mistakes           -> ../../../.agents/skills/no-mistakes                 （仅在装了 no-mistakes 时）
```

## 插件与 MCP

| 名称 | Claude Code | Codex | 说明 |
| --- | --- | --- | --- |
| ponytail | `claude plugin marketplace add DietrichGebert/ponytail`，再 `claude plugin install ponytail@ponytail` | `codex plugin marketplace add DietrichGebert/ponytail`，再 `codex plugin add ponytail@ponytail`；之后在 Codex 中打开 `/hooks`，信任它的两个生命周期钩子，并新开一个会话 | 常驻模式依赖会话启动钩子，所以必须装成插件，不能只装 skill |
| context7 | `claude plugin install context7@claude-plugins-official` | — | 自带文档查询 MCP |
| Cua Driver MCP | `claude mcp add --scope user cua-computer-use -- ~/.local/bin/cua-driver mcp` | — | **只给 Claude Code** |

## 命令行工具

| 工具 | 安装 | 首次配置（本人执行） |
| --- | --- | --- |
| rtk | Brewfile 中的 `rtk` | 给每个 Agent 装一次钩子：`rtk init -g`（Claude Code），`rtk init -g --codex`（Codex），`rtk init -g --agent pi`（Pi）。可用 `rtk init --show` 检查 |
| lark-cli | `npm install -g @larksuite/cli` | `lark-cli` 的登录命令，见 lark-shared skill |
| aliyun-cli | Brewfile 中的 `aliyun-cli` | `aliyun configure` |
| tccli | `brew install tccli` | `tccli auth login` |
| thcli（TokenHub） | `npm install -g tencent-tokenhub-cli` | `thcli auth login`；然后按上文安装 skill |
| Cua Driver | `curl -fsSL https://cua.ai/driver/install.sh \| bash` | `cua-driver permissions grant`，授予辅助功能和屏幕录制权限 |

## Firstmate

[Firstmate](https://github.com/kunchenguid/firstmate) 是一个由 Agent 担任"大副"、统一派发和监督多个编码 Agent 的工作流。仓库本身就是发行版，没有单独的安装程序。

1. **克隆**：`gh auth login` 之后，执行 `git clone https://github.com/kunchenguid/firstmate ~/firstmate`。
2. **启动**：在 Herdr 的终端里进入 `~/firstmate`，运行 `claude`、`pi` 或 `codex` 中的一个作为主会话。在 Herdr 内启动时，worker 会自动开在 Herdr 里。
   - 同一时间只运行一个主会话；切换主会话用的 Agent 前，先退出前一个。
   - 第一次启动时，由本人确认项目目录的信任提示；用 Pi 时，还要信任仓库自带的扩展。
3. **依赖**：第一次启动时，Firstmate 会检查缺少的工具，列出安装命令，经本人同意后再安装：
   - `treehouse` 和 `no-mistakes`：官方 curl 安装器；
   - `gh-axi`、`tasks-axi`、`quota-axi`、`chrome-devtools-axi`、`lavish-axi`：`npm install -g`。

   上游建议的 `<工具> setup hooks` 会改动各 Agent 的全局设置，本机没有执行，按需决定。
4. **私有数据不随 dotfiles 迁移**：`~/firstmate` 下的 `data/`、`config/`、`projects/`、`state/` 都被它自己的 Git 忽略，包括项目登记、二副（工作区在 `~/.treehouse`）和本机配置。新机器上需要在 Firstmate 会话里重新登记项目、重新创建二副。

## 更新

运行 `u`。它的 "Agent skills & plugins" 一节依次执行：
- `npx skills update -g -y`
- `thcli +connect`
- Claude 插件市场更新和各插件更新
- `codex plugin marketplace upgrade`
- `pi update --extensions`（Pi 扩展包）
- `cua-driver update --apply`
- `treehouse update`

命令行工具由 Homebrew 和 npm 两节更新，包括 Firstmate 依赖的几个 `*-axi` 工具。

不在 `u` 里的几项：
- **Firstmate**：在 Firstmate 会话里执行 `/updatefirstmate`，它会同时更新所有二副。
- **no-mistakes 本体**：用 `no-mistakes update`，它会重启检查服务，需在空闲时手动执行。
- **tcapi skill**：没有 ClawHub 命令行，需要更新时重新从 ClawHub 安装。

## 部署后检查

- `npx skills ls -g` 列出上表中所有用 `npx skills` 安装的 skill。
- `~/.agents/skills` 下每个 skill 在 `$CLAUDE_CONFIG_DIR/skills` 中都有同名链接，且没有坏链接；`cua-driver` 只在 Claude 中出现。
- `~/.codex/skills` 和 `~/.pi/agent/skills` 中没有指向 `~/.agents/skills` 的链接（Codex 自带的 `.system/` 除外）。
- `claude plugin list` 只有 ponytail 和 context7，没有 mattpocock；`~/.codex/config.toml` 中没有 `mattpocock` 市场或插件。
- `claude mcp list` 中 `cua-computer-use` 显示已连接。
- 重启各 Agent 会话后，确认能看到新 skill。
