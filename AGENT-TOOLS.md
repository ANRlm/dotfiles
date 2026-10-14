# Agent 工具部署清单

本文件供新机器上的 Agent 读取后部署 Claude Code、Codex、Pi 的 skill、插件和配套命令行工具。按步骤顺序执行，每一步满足「完成标准」后再进入下一步。

需要登录、密钥或系统授权的操作由本人执行：Agent 给出完整命令，等待本人确认已完成，凭据不经过 Agent。

## 约定

- **共享目录**：所有 skill 实体只放在 `~/.agents/skills`。
- **Codex 和 Pi** 原生读取共享目录。`~/.codex/skills` 和 `~/.pi/agent/skills` 保持原样，不建指向共享目录的链接，否则同一个 skill 会加载两次。
- **Claude Code** 只读取 `$CLAUDE_CONFIG_DIR/skills`，需要给每个 skill 建一个符号链接。`CLAUDE_CONFIG_DIR` 由 `fish/config.fish` 设置，本机为 `~/.claude-profiles/default`；未设置时 Claude 使用 `~/.claude`。
- **安装方式**：skill 一律用 `npx skills add <来源> -g -a claude-code -a codex -a pi -y` 安装。它把内容放进共享目录，给 Claude 建链接，并写入 `~/.agents/.skill-lock.json`，之后由 `u` 统一更新。插件市场只用于带钩子的 ponytail 和 Claude 官方插件 context7。
- **cua-driver** 只给 Claude Code 使用，skill 实体放在共享目录之外。

## 1. 前置条件

1. 已按 [README](README.md) 部署 dotfiles，并执行过 `brew bundle --file=~/dotfiles/Brewfile`。Brewfile 已包含 `claude-code@latest`、`codex`、`pi-coding-agent`、`node`、`rtk`、`aliyun-cli` 和 `tccli`。
2. 当前 Shell 是加载了 `fish/config.fish` 的 Fish。
3. `jq` 可用（macOS 自带 `/usr/bin/jq`）：`u` 用它解析 Claude 和 Herdr 的插件列表。

**完成标准**：`command -v claude codex pi node rtk aliyun tccli jq` 每项都有输出；`echo $CLAUDE_CONFIG_DIR` 输出上面约定的目录。

## 2. 命令行工具

| 工具 | 安装 | 首次配置（本人执行） |
| --- | --- | --- |
| rtk | Brewfile | 每个 Agent 装一次钩子：`rtk init -g`（Claude Code）、`rtk init -g --codex`（Codex）、`rtk init -g --agent pi`（Pi）；用 `rtk init --show` 检查 |
| aliyun-cli | Brewfile | `aliyun configure` |
| tccli | Brewfile | `tccli auth login` |
| lark-cli | `npm install -g @larksuite/cli` | 登录命令见 lark-shared skill |
| thcli（TokenHub） | `npm install -g tencent-tokenhub-cli` | `thcli auth login` |
| Cua Driver | `curl -fsSL https://cua.ai/driver/install.sh \| bash` | `cua-driver permissions grant`，授予辅助功能和屏幕录制权限 |

**完成标准**：`rtk --version`、`aliyun version`、`tccli --version`、`lark-cli --version`、`thcli --version`、`cua-driver --version` 都能运行（npm 安装成功不代表二进制已在 PATH 中）；需要本人执行的首次配置均已确认完成。

## 3. Skill

| 名称 | 安装命令 | 说明 |
| --- | --- | --- |
| mattpocock skills | `npx skills add mattpocock/skills --skill '*' -g -a claude-code -a codex -a pi -y` | Claude 和 Codex 的 mattpocock 插件提供同样的 skill，只用这一种安装方式 |
| show-me | `npx skills add humanlayer/skills --skill show-me -g -a claude-code -a codex -a pi -y` | 只在手动调用时生效 |
| find-skills | `npx skills add vercel-labs/skills --skill find-skills -g -a claude-code -a codex -a pi -y` | |
| lark skills | `npx skills add https://open.feishu.cn/lark-cli/skills/regular --skill '*' -g -a claude-code -a codex -a pi -y` | 飞书官方，依赖 lark-cli |
| 阿里云 CLI / AgentLoop | `npx skills add aliyun/alibabacloud-aiops-skills --skill alibabacloud-cli-guidance --skill alibabacloud-agentloop-management --full-depth -g -a claude-code -a codex -a pi -y` | 依赖 aliyun-cli |
| herdr | `npx skills add herdrdev/herdr --skill herdr -g -a claude-code -a codex -a pi -y` | |
| TokenHub（`thcli-*`） | `thcli +connect --target ~/.agents/skills` | thcli 自带，不经过 `npx skills` |
| 腾讯云 API（tcapi） | 从 [ClawHub](https://clawhub.ai/user/tencent-adm) 安装 `@tencent-adm/tencentcloud-api-skill` 到 `~/.agents/skills/@tencent-adm/tencentcloud-api-skill` | 官方只在 ClawHub 发布，GitHub 上的同名仓库是非官方翻译版。依赖 tccli |
| cua-driver | Cua Driver 的独立 skill 包，实体位于 `~/.cua-driver/skills/cua-driver` | 只给 Claude Code，链接方式见下文 |

装完后给 Claude 补齐共享目录的链接（thcli、tcapi、no-mistakes 等不经过 `npx skills` 的 skill 也靠这一步）。在 Fish 中运行：

```fish
source ~/dotfiles/fish/functions/u.fish
__u_sync_skills
```

`__u_sync_skills` 递归查找 `SKILL.md`，支持 `@tencent-adm/...` 这类作用域目录，已有的指向同一实体的链接保持不变。遇到同名目录、指向其他位置的链接或坏链接时，它报告冲突并返回失败，不覆盖任何文件；把冲突列给本人确认后再处理。

cua-driver 单独链接到 Claude。`cua-driver skills install/update` 会同时给其他 Agent 建链接，所以改用：

```fish
mkdir -p "$CLAUDE_CONFIG_DIR/skills"
test -e "$CLAUDE_CONFIG_DIR/skills/cua-driver"; or ln -s ~/.cua-driver/skills/cua-driver "$CLAUDE_CONFIG_DIR/skills/cua-driver"
```

**完成标准**：

- `npx skills ls -g` 列出上表中所有用 `npx skills` 安装的 skill。
- `~/.agents/skills/@tencent-adm/tencentcloud-api-skill/.clawhub/origin.json` 中 `ownerHandle` 为 `tencent-adm`。
- `__u_sync_skills` 返回 0；共享目录中的每个 skill 在 `$CLAUDE_CONFIG_DIR/skills` 都有同名链接，且没有坏链接。
- `$CLAUDE_CONFIG_DIR/skills/cua-driver` 指向 `~/.cua-driver/skills/cua-driver`；cua-driver 不出现在 Codex 和 Pi 的 skill 目录中。
- `~/.codex/skills` 和 `~/.pi/agent/skills` 中没有指向 `~/.agents/skills` 的链接（Codex 自带的 `.system/` 不算）。

## 4. 插件与 MCP

| 名称 | Claude Code | Codex | 说明 |
| --- | --- | --- | --- |
| ponytail | `claude plugin marketplace add DietrichGebert/ponytail`，再 `claude plugin install ponytail@ponytail` | `codex plugin marketplace add DietrichGebert/ponytail`，再 `codex plugin add ponytail@ponytail`；然后由本人在 Codex 的 `/hooks` 中信任它的两个生命周期钩子，并新开会话 | 常驻模式依赖会话启动钩子，因此装成插件 |
| context7 | `claude plugin install context7@claude-plugins-official` | — | 自带文档查询 MCP |
| Cua Driver MCP | `claude mcp add --scope user cua-computer-use -- ~/.local/bin/cua-driver mcp` | — | 只给 Claude Code |

**完成标准**：

- `claude plugin list` 只有 ponytail 和 context7。
- `~/.codex/config.toml` 中没有 `mattpocock` 市场或插件。
- `claude mcp list` 中 `cua-computer-use` 显示已连接。

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

重启 Claude Code 和 Codex 会话，确认新 skill 和插件已生效。在 Pi 中执行 `/reload` 后检查 skill 命令，并用 `pi list` 确认 Pi 扩展包。带 `disable-model-invocation: true` 的 skill 只能手动调用，不会出现在模型的自动选择清单中，这不代表未加载。

**完成标准**：三个 Agent 都能看到上面安装的 skill；钩子信任、登录和系统权限均已由本人确认。

## 更新

`u` 的「Agent skills & plugins」一节依次执行：

- `npx skills update -g -y`
- `thcli +connect --target ~/.agents/skills`
- `__u_sync_skills`，给新增的 skill 补齐 Claude 链接
- 更新 Claude 插件市场和已安装的插件
- `codex plugin marketplace upgrade`
- `pi update --extensions`
- `cua-driver update --apply`
- `treehouse update`

lark-cli、thcli 和 Firstmate 依赖的 `*-axi` 工具由 `u` 的 Node 一节随 npm 全局包更新，其余命令行工具随 Homebrew 更新。

以下几项需要手动更新：

- **Firstmate**：在 Firstmate 会话中执行 `/updatefirstmate`，会同时更新所有二副。
- **no-mistakes 本体**：`no-mistakes update` 会重启检查服务，在空闲时执行。
- **tcapi**：重新从 ClawHub 官方来源安装；`npx skills update` 不更新它。
- **cua-driver skill 包**：`cua-driver update --apply` 只更新二进制，不刷新 skill 包；刷新后确认链接仍只在 Claude 中。
- **上游已删除的 skill**：`npx skills update -g -y` 会保留本机副本并告警，确认不再需要后再删除。

修改 `__u_sync_skills` 后运行 `python3 fish/tests/sync-skills.test.py`，它只操作临时目录；完整的离线测试列表见 [README](README.md#离线测试)。
