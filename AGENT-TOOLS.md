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

- **安装方式**：skill 一律用 `npx skills add <来源> -g -a claude-code -a codex -a pi -y` 安装。它把内容放进共享目录，给 Claude 建链接，并写入 `~/.agents/.skill-lock.json`，之后由 `u` 统一更新。只有需要钩子或 MCP 的才装成插件，见第 4 节。
- **四个 Agent 必装**：[ponytail](https://github.com/DietrichGebert/ponytail)（第 4 节）和 [mattpocock/skills](https://github.com/mattpocock/skills) 的全部 skill（3.1 节）。上游新增 skill 时，`u` 会自动补装。
- **Grok 配置目录**：`grok` 命令必须走 `~/.local/bin/grok` 包装脚本，它把 `GROK_HOME` 指向 `~/.grok-profiles/default`，插件和启用状态写在那里。

## 1. 前置条件

1. 已按 [AGENTS.md](AGENTS.md#部署新机器) 部署 dotfiles，并执行过 `brew bundle --file=~/dotfiles/Brewfile`。
2. 当前 Shell 是加载了 `fish/config.fish` 的 Fish。
3. `jq` 可用（macOS 自带 `/usr/bin/jq`）：`u` 用它解析 Claude 的插件列表。

**完成标准**：`command -v claude codex pi grok node aliyun tccli jq` 每项都有输出，其中 `grok` 为 `~/.local/bin/grok`；`echo $CLAUDE_CONFIG_DIR` 输出上面约定的目录。

## 2. Skill 依赖的工具

| 工具 | 安装 | 首次配置（本人执行） |
| --- | --- | --- |
| aliyun-cli | Brewfile（阿里云 skill 依赖） | `aliyun configure` |
| tccli | Brewfile（tcapi 依赖） | `tccli auth login` |
| lark-cli | `npm install -g @larksuite/cli` | 登录命令见 lark-shared skill |
| thcli（TokenHub） | `npm install -g tencent-tokenhub-cli` | `thcli auth login` |
| ego lite | 从 [官网](https://lite.ego.app/) 下载安装 `ego lite.app` | 在应用中完成首次引导，它会把 `ego-browser` 命令注册到 `~/.local/bin` |

**完成标准**：`aliyun version`、`tccli --version`、`lark-cli --version`、`thcli --version` 都能运行，`command -v ego-browser` 有输出（npm 安装成功不代表二进制已在 PATH 中）；需要本人执行的首次配置均已确认完成。

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

### 3.3 给 Claude 建链接

共享目录中的 skill（包括 thcli、tcapi 等不经过 `npx skills` 的）靠这一步补齐 Claude 链接。在 Fish 中运行：

```fish
source ~/dotfiles/fish/functions/u.fish
__u_sync_skills
```

`__u_sync_skills` 递归查找 `SKILL.md`，支持 `@tencent-adm/...` 这类作用域目录，已有的指向同一实体的链接保持不变。遇到同名目录、指向其他位置的链接或坏链接时，它报告冲突并返回失败，不覆盖任何文件；把冲突列给本人确认后再处理。

**完成标准**：

- `npx skills ls -g` 列出 3.1 中安装的所有 skill。
- `~/.agents/skills/@tencent-adm/tencentcloud-api-skill/.clawhub/origin.json` 中 `ownerHandle` 为 `tencent-adm`。
- `__u_sync_skills` 返回 0；共享目录中的每个 skill 在 `$CLAUDE_CONFIG_DIR/skills` 都有同名链接，且没有坏链接。
- `~/.codex/skills`、`~/.pi/agent/skills` 和 `~/.grok/skills` 中没有指向 `~/.agents/skills` 的链接（Codex 自带的 `.system/` 和 ego lite 的 `ego-browser` 不算）。
- 在 Git 仓库之外运行 `grok inspect`，Skills 一节列出共享目录中的全部 skill。

## 4. 插件与 MCP

ponytail 四个 Agent 都装，context7 只给 Claude Code 装，Grok 不装 MCP。

| 名称 | Claude Code | Codex | Pi | Grok | 说明 |
| --- | --- | --- | --- | --- | --- |
| ponytail | `claude plugin marketplace add DietrichGebert/ponytail`，再 `claude plugin install ponytail@ponytail` | `codex plugin marketplace add DietrichGebert/ponytail`，再 `codex plugin add ponytail@ponytail` | `pi install npm:@dietrichgebert/ponytail` | `grok plugin install DietrichGebert/ponytail --trust`，再 `grok plugin enable ponytail` | 常驻模式依赖会话启动钩子或 Pi 扩展，因此装成插件而不用 `npx skills add`（后者只装 skill）；Pi 包自带 skill 和扩展 |
| context7 | `claude plugin install context7@claude-plugins-official` | — | — | — | 自带文档查询 MCP |

Codex 装完 ponytail 后，由本人在 Codex 的 `/hooks` 中信任它的两个生命周期钩子，并新开会话。

Grok 的 ponytail 只有 skill，不常驻：Grok 的会话启动钩子无法注入指令，靠模型按描述自动调用或手动 `/ponytail`。

Pi 的状态栏不显示 ponytail 状态条（规则照常生效）：`fish/config.fish` 设 `PONYTAIL_HIDE_STATUS=1`，级别用 `/ponytail status` 查。扩展在进程启动时读环境变量，改后重开 Pi 生效。

Pi 专用的扩展（状态栏、btw、stamp、问答、todo）不在本表，见 [AGENTS.md](AGENTS.md#pi)。

**完成标准**：

- `claude plugin list` 只有 ponytail 和 context7。
- `pi list` 包含 `npm:@dietrichgebert/ponytail`。
- `~/.codex/config.toml` 中没有 `mattpocock` 市场或插件。
- `grok inspect` 的 Plugins 一节只有 `ponytail (user, enabled)`，MCP Servers 一节为 None。

## 5. 收尾

1. 重启 Claude Code、Codex 和 Grok 会话。
2. 在 Pi 中执行 `/reload`，再用 `pi list` 确认 Pi 扩展包。

带 `disable-model-invocation: true` 的 skill 只能手动调用，不会出现在模型的自动选择清单中，这不代表未加载。

**完成标准**：四个 Agent 都能看到上面安装的 skill 和插件；钩子信任、登录和系统权限均已由本人确认。

## 更新

`u` 的「Agent skills & plugins」一节依次执行：

1. `__u_update_skills`：`npx skills update -g -y`，再按它的告警删掉上游已删除的本地副本（`npx skills remove … -g -y`），本机与上游保持一致
2. 重新执行 3.1 节的 mattpocock 安装命令：`update` 只更新已装的 skill，上游新增的要靠重新 `add` 补上，保证四个 Agent 都有全套
3. `thcli +connect --target ~/.agents/skills`
4. `__u_sync_skills`，给新增的 skill 补齐 Claude 链接
5. 更新 Claude 插件市场和已安装的插件
6. `codex plugin marketplace upgrade`
7. `pi update --extensions`，更新 `~/.pi/agent/settings.json` 里的 Pi 包（含状态栏 `@narumitw/pi-starship`）
8. `grok plugin update`

lark-cli 和 thcli 由 `u` 的 Node 一节随 npm 全局包更新。

以下需要手动更新：

- **tcapi**：重新从 ClawHub 官方来源安装；`npx skills update` 不更新它。

修改 `__u_sync_skills` 后运行 `python3 fish/tests/sync-skills.test.py`，它只操作临时目录；完整的离线测试列表见 [AGENTS.md](AGENTS.md#测试)。
