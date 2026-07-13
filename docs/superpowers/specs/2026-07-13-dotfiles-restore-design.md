# Dotfiles 完整恢复设计

## 目标

让 `scripts/restore.sh` 在 macOS 上提供可重复执行的一键恢复：创建仓库配置软链接、安装 Brewfile 依赖、生成 Karabiner 配置、恢复 Fish/tmux/Yazi 插件，并将账户登录 Shell 设置为 Homebrew Fish。

## 当前状态与缺口

- Homebrew Fish 位于 `/opt/homebrew/bin/fish`，但尚未列入 `/etc/shells`，账户登录 Shell 仍是 `/bin/zsh`。
- 所有计划中的 `~/.config` 软链接目标当前均不存在，不需要迁移或覆盖用户文件。
- `restore.sh` 已处理 Brew bundle、Goku、TPM 和 Cargo 包，但没有执行 Fisher/Fish 插件同步，也没有执行 Yazi 插件安装。
- 默认 Shell 判断使用当前进程的 `$SHELL`，修改登录 Shell 后旧终端仍会保留旧值，导致重复执行时再次调用 `chsh`。
- `Brewfile` 存在用户未提交修改，本任务不修改、暂存或提交它。

## 方案比较

### 方案一：保持单脚本、补全幂等恢复（采用）

在现有 `restore.sh` 中补充 Fish 和 Yazi 插件恢复，并使用账户目录服务记录判断实际登录 Shell。优点是与 README 描述一致，新机只需执行一个脚本，且重复运行安全；缺点是脚本仍承担多个工具的编排职责。

### 方案二：只完成本机一次性恢复

直接在当前机器创建软链接、安装插件并切换 Shell，不修改脚本。优点是改动最少；缺点是下一台机器仍会遇到同样缺口，不符合 dotfiles 仓库的可复用目标。

### 方案三：拆分为多个恢复子命令

把链接、软件、插件与 Shell 设置拆成多个脚本或命令参数。优点是控制更细；缺点是增加接口、文档和维护成本，当前规模下没有必要。

## 设计

### 恢复顺序

1. 解析仓库路径并创建 `~/.config` 与 `~/.hushlogin`。
2. 使用现有安全链接函数创建配置目录和文件软链接；如果目标是普通文件或目录则中止，不做破坏性替换。
3. 初始化 Homebrew 环境并执行 `brew bundle`，确保后续工具存在。
4. 运行 Goku 生成 Karabiner 配置。
5. 使用 Fish 启动 Fisher：缺少 Fisher 时从其官方脚本引导安装，然后执行 `fisher update`，以仓库中的 `fish/fish_plugins` 为声明源。
6. 安装或复用 TPM，再同步 tmux 插件。
7. 执行 `ya pkg install`，以仓库中的 `yazi/package.toml` 为声明源恢复 Yazi 插件。
8. 确保 Fish 路径存在于 `/etc/shells`；读取 macOS Directory Service 的 `UserShell`，仅在实际值不同时调用 `chsh`。
9. 保留现有 Cargo 包恢复逻辑；系统没有 Cargo 时继续给出警告并跳过。

### 幂等性与安全性

- 已指向仓库的软链接可以删除后重建；普通目标不会被覆盖或移动。
- Fisher、TPM、Yazi 和 Brew 均使用各自的声明文件或安装状态进行同步，可重复执行。
- `/etc/shells` 只在缺少精确 Fish 路径时追加。
- 登录 Shell 使用 `dscl` 的账户记录判断，并在无法读取时回退到 `$SHELL`。
- 插件同步或必需命令失败时，由现有 `set -Eeuo pipefail` 终止恢复并报告行号，避免显示虚假的成功消息。

## 本机执行

先将 `/opt/homebrew/bin/fish` 加入 `/etc/shells` 并设置为用户 `sakura` 的登录 Shell，再执行补全后的 `restore.sh`。提前设置 Shell 可以让脚本的幂等分支在真实环境中得到验证。

## 验证

- `bash -n scripts/restore.sh` 返回成功。
- `brew bundle check --verbose --file=Brewfile` 返回成功。
- `dscl . -read /Users/sakura UserShell` 返回 `/opt/homebrew/bin/fish`，且 `/etc/shells` 包含同一路径。
- 每个预期目标都是指向 `/Users/sakura/dotfiles` 对应源的软链接；不存在悬空链接。
- Fish 中 `fisher` 与 `fzf_configure_bindings` 可用。
- Yazi 清单中的插件目录已安装，TPM 及其声明插件存在。
- Karabiner 的生成配置存在，`goku` 执行成功。
- 最终 Git 状态不包含插件缓存等意外文件，并保留任务开始前已有的 Brewfile 修改。
