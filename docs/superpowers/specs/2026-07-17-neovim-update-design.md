# `u` 指令的 Neovim / AstroNvim 完整更新设计

## 背景

当前配置通过 `lazy_setup.lua` 将 AstroNvim 固定在 `^6`，本机实际加载版本为
AstroNvim v6.0.5。现有 Fish `u` 指令会更新 Homebrew、pnpm、Rust、Ruby、
MAS、Mole、TPM 和 Yazi，但不会更新 Neovim 生态。

AstroNvim v6 的完整更新包含三类状态：Lazy 插件、Treesitter parser，以及
Mason 管理的工具。`AstroUpdate` 内部会触发这三类更新，但 Mason 部分是异步的；
直接在无头模式中紧接 `qa` 可能提前退出，因此不适合自动化脚本。

## 目标

- 每次执行 `u` 都完整更新 Neovim 的插件、Treesitter parser 和 Mason 工具。
- 三步均在结束后才继续下一步，避免后台更新尚未完成时退出 Neovim。
- 单步失败时继续运行 `u` 的其余更新，并让 `u` 最终返回非零状态。
- 保持 pnpm 每次执行 `u` 都更新的现有行为。

## 非目标

- 不更新 Neovim 可执行文件本身；它继续由 Homebrew 更新阶段负责。
- 不改变 AstroNvim 的 `^6` 版本约束或现有插件配置。
- 不在测试中真正访问网络或修改本机 Neovim 数据目录。

## 设计

在 TPM 与 Yazi 更新之间新增 `Neovim / AstroNvim` 区段，依次运行三个独立的
无头 Neovim 进程：

1. Lazy 插件同步：调用 `require("lazy").sync({ wait = true })`，等待插件清理、
   安装和更新全部完成。
2. Treesitter parser 更新：调用 `require("nvim-treesitter").update():wait()`，
   使用 AstroNvim v6 当前 Treesitter API 阻塞至结束。
3. Mason 工具更新：配置中存在 `ensure_installed` 工具时执行
   `MasonToolsUpdateSync` 并阻塞至完成；列表为空时成功跳过，避免该命令永久等待。

三步分别通过 `__u_run` 执行，而不是合并在同一 Neovim 进程中。这样插件同步
完成后，后续进程会重新加载已更新的插件代码；同时，错误会准确归属到
`Plugins synced`、`Treesitter parsers updated` 或 `Mason tools updated`。

Neovim 在命令报错时可能仍以状态 0 退出，因此每个无头调用都会用 Lua 包装器
捕获命令级异常，并以非零状态退出。更新器自身报告的失败信息仍会保留在标准
输出中。任何一步失败都会增加 `__u_failures`，但不会阻止后续 Neovim 步骤或
Yazi 等其他更新继续执行。

## 文档变更

更新 README 中 `u` 的说明：列出 Neovim / AstroNvim 完整更新，并删除“不会更新
Neovim 插件”的旧描述。说明 Neovim 可执行文件仍由 Homebrew 更新。

## 测试

扩展 `fish/tests/u_test.fish` 的命令替身：

- 新增 `nvim` 替身并记录参数，不运行真实 Neovim。
- 断言每次 `u` 都按顺序调用 Lazy、Treesitter 和 Mason 三个更新步骤。
- 断言 Mason 步骤会保护空的 `ensure_installed` 列表。
- 断言 Neovim 某一步失败会使 `u` 返回非零，但之后的步骤仍会执行。
- 保留现有 pnpm 连续两次执行的断言，防止本次变更破坏“每次都更新 pnpm”。

完成后运行 Fish 测试、Fish 语法检查、格式检查和 `git diff --check`。

## 备选方案

- 直接执行 `AstroUpdate`：最贴近交互用法，但 Mason 更新异步，无法保证无头进程
  退出前完成。
- 在一个 Neovim 进程中串行调用全部 API：命令更短，但插件自更新后不会重启并
  加载新代码，隔离性和错误定位也较差。
- 只执行 Lazy 同步：遗漏 Treesitter parser 与 Mason 工具，不符合“完整更新”。
