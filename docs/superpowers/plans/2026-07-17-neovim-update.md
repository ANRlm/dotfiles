# Neovim / AstroNvim Full Update Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the Fish `u` command so every run synchronously updates AstroNvim v6 plugins, Treesitter parsers, and Mason-managed tools without changing the existing every-run pnpm behavior.

**Architecture:** Add three independent headless Neovim invocations between TPM and Yazi. Each invocation blocks until its own update finishes and wraps Lua command errors so Neovim returns nonzero; the existing `__u_run` aggregator records failures and continues subsequent updates.

**Tech Stack:** Fish shell, Neovim 0.12, AstroNvim v6, lazy.nvim, nvim-treesitter, mason-tool-installer.nvim.

## Global Constraints

- AstroNvim remains constrained to `^6`; do not modify `nvim/lua/lazy_setup.lua` or plugin configuration.
- The Neovim executable itself remains managed by the existing Homebrew update stage.
- Every `u` run must still execute `pnpm update -g && pnpm store prune`.
- Tests must use a mocked `nvim` Fish function and must not access the network or modify Neovim's data directory.
- Preserve the user's unrelated changes in `fish/config.fish` and exclude that file from commits.

---

## File Structure

- `fish/functions/u.fish`: owns update ordering, labels, subprocess invocation, failure counting, and final exit status.
- `fish/tests/u_test.fish`: owns isolated command mocks and behavioral assertions for repeated execution, ordering, failure continuation, and final status.
- `README.md`: documents the user-visible scope and ownership of the `u` command.

### Task 1: Add the synchronous AstroNvim update pipeline

**Files:**
- Modify: `fish/tests/u_test.fish:6-112`
- Modify: `fish/functions/u.fish:57-64`

**Interfaces:**
- Consumes: `__u_run LABEL COMMAND ARGS...`, which records a nonzero child status in function-scoped `__u_failures` and then returns that child status.
- Produces: three `nvim --headless` calls labeled `Plugins synced`, `Treesitter parsers updated`, and `Mason tools updated`, in that order; the Mason call skips an empty managed-tool list.

- [ ] **Step 1: Add the failing behavioral tests**

Add this global immediately after `set -g __u_test_brew_status 7`:

```fish
set -g __u_test_nvim_failure_pattern ''
```

Add these helpers immediately after `__u_test_assert_command`:

```fish
function __u_test_assert_match --argument-names pattern actual message
    if not string match --quiet -- "$pattern" "$actual"
        echo "FAIL: $message ('$actual' does not match '$pattern')" >&2
        set -g __u_test_failures (math $__u_test_failures + 1)
    end
end

function __u_test_assert_nvim_sequence
    set -l nvim_commands (string match -- 'nvim *' $__u_test_commands)
    __u_test_assert_equal 3 (count $nvim_commands) 'u runs all three Neovim update steps'

    if test (count $nvim_commands) -eq 3
        __u_test_assert_match '*require("lazy").sync({ wait = true })*' "$nvim_commands[1]" 'Lazy sync runs first and waits'
        __u_test_assert_match '*require("nvim-treesitter").update():wait()*' "$nvim_commands[2]" 'Treesitter update runs second and waits'
        __u_test_assert_match '*MasonToolsUpdateSync*' "$nvim_commands[3]" 'Mason tools update runs third and waits'
        __u_test_assert_match '*next(tools)*' "$nvim_commands[3]" 'Mason sync skips an empty managed-tool list'
    end
end
```

Add this command mock after the `fisher` mock:

```fish
function nvim
    set -l command (string join ' ' -- nvim $argv)
    set -a __u_test_commands $command
    if test -n "$__u_test_nvim_failure_pattern"; and string match --quiet -- "*$__u_test_nvim_failure_pattern*" "$command"
        return 9
    end
    return 0
end
```

After the first-run Mole assertions, add:

```fish
__u_test_assert_nvim_sequence
```

After the second-run pnpm assertion, add:

```fish
__u_test_assert_nvim_sequence

# A Neovim failure must affect u's status without stopping later updates.
set __u_test_nvim_failure_pattern nvim-treesitter
set __u_test_commands
u >/dev/null 2>/dev/null
set -l nvim_failure_status $status

__u_test_assert_equal 1 $nvim_failure_status 'u returns failure when a Neovim update step fails'
__u_test_assert_nvim_sequence
__u_test_assert_command 'ya pkg upgrade' 'updates after Neovim continue after a failure'
```

Replace the helper and mock cleanup with:

```fish
functions --erase __u_test_assert_equal __u_test_assert_command __u_test_assert_match __u_test_assert_nvim_sequence
functions --erase bash fish env uv fisher nvim ya mas mo _section
set -e __u_failures
```

- [ ] **Step 2: Run the test to verify the new assertions fail**

Run:

```bash
fish fish/tests/u_test.fish
```

Expected: exit 1 with assertions reporting zero Neovim update calls and a successful status for the simulated Neovim-failure run.

- [ ] **Step 3: Add the minimal three-process implementation**

Insert this block in `fish/functions/u.fish` after the TPM block and before Yazi:

```fish
    # ── Neovim / AstroNvim
    __u_section "Neovim / AstroNvim"
    __u_run "Plugins synced" nvim --headless -c 'lua local ok, err = pcall(function() require("lazy").sync({ wait = true }) end); if not ok then vim.api.nvim_err_writeln(tostring(err)); vim.cmd("cquit") end' -c qa
    __u_run "Treesitter parsers updated" nvim --headless -c 'lua local ok, err = pcall(function() require("nvim-treesitter").update():wait() end); if not ok then vim.api.nvim_err_writeln(tostring(err)); vim.cmd("cquit") end' -c qa
    __u_run "Mason tools updated" nvim --headless -c 'lua local ok, err = pcall(function() local plugin = require("lazy.core.config").plugins["mason-tool-installer.nvim"]; local tools = plugin and type(plugin.opts) == "table" and plugin.opts.ensure_installed or {}; if type(tools) == "table" and next(tools) then vim.cmd.MasonToolsUpdateSync() end end); if not ok then vim.api.nvim_err_writeln(tostring(err)); vim.cmd("cquit") end' -c qa

```

The `pcall` wrappers are required: Neovim can print a command-line Lua error and still exit with status 0. `cquit` converts a caught command exception into a nonzero child status that `__u_run` can aggregate.

- [ ] **Step 4: Run focused tests and syntax checks**

Run:

```bash
fish fish/tests/u_test.fish
fish -n fish/functions/u.fish fish/tests/u_test.fish
fish_indent --check fish/functions/u.fish fish/tests/u_test.fish
```

Expected: all commands exit 0; the test prints `u tests passed`.

- [ ] **Step 5: Review and commit the update pipeline**

Run:

```bash
git diff --check -- fish/functions/u.fish fish/tests/u_test.fish
git diff -- fish/functions/u.fish fish/tests/u_test.fish
git add -- fish/functions/u.fish fish/tests/u_test.fish fish/tests/fixtures/home/.config/tmux/plugins/tpm/bin/update_plugins
git diff --cached --name-status
git commit -m "feat: add AstroNvim to full update command"
```

Expected: the staged file list contains only `fish/functions/u.fish`, `fish/tests/u_test.fish`, and the TPM test fixture; `fish/config.fish` remains unstaged.

### Task 2: Document and verify the complete update behavior

**Files:**
- Modify: `README.md:126-130`

**Interfaces:**
- Consumes: the completed `u` behavior from Task 1.
- Produces: user-facing documentation that names all three Neovim update categories and states that Homebrew owns the Neovim executable update.

- [ ] **Step 1: Replace the outdated README description**

Replace lines 126-130 with:

```markdown
`u` 会更新 Homebrew、Conda、npm/pnpm 全局包、uv 工具、Fisher、TPM、
Neovim/AstroNvim（Lazy 插件、Treesitter parser 和 Mason 工具）、Yazi 和 MAS，
并执行 Mole 清理。它还会强制重写 `~/dotfiles/Brewfile`，因此仓库应保持在该路径。

`u` 不会拉取 dotfiles 仓库。Neovim 可执行文件由 Homebrew 更新阶段负责；
AstroNvim 生态则由后续三个同步步骤完整更新。
```

- [ ] **Step 2: Verify documentation matches executable behavior**

Run:

```bash
rg -n 'Neovim/AstroNvim|Lazy 插件|Treesitter parser|Mason 工具|pnpm update -g|MasonToolsUpdateSync' README.md fish/functions/u.fish
```

Expected: README names the three categories, `u.fish` contains the pnpm every-run command, and `u.fish` contains the synchronous Mason command.

- [ ] **Step 3: Run the full verification suite**

Run:

```bash
fish fish/tests/u_test.fish
fish -n fish/functions/u.fish fish/tests/u_test.fish
fish_indent --check fish/functions/u.fish fish/tests/u_test.fish
sh -n fish/tests/fixtures/home/.config/tmux/plugins/tpm/bin/update_plugins
git diff --check
```

Expected: every command exits 0; the Fish test prints `u tests passed`.

- [ ] **Step 4: Review scope and commit the documentation**

Run:

```bash
git diff -- README.md
git status --short
git add -- README.md
git diff --cached --name-status
git commit -m "docs: describe complete Neovim updates"
```

Expected: only `README.md` is staged for this commit; the user's `fish/config.fish` change remains uncommitted.

- [ ] **Step 5: Confirm final repository state**

Run:

```bash
git status --short
git log -4 --oneline
```

Expected: `fish/config.fish` is the only unrelated modified file; the latest commits include the implementation, README update, implementation plan, and the previously committed design document.
