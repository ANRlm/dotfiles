#!/usr/bin/env fish

set -l repo_root (path resolve (status dirname)/../..)
source $repo_root/fish/functions/u.fish

set -g __u_test_failures 0
set -g __u_test_commands
set -g __u_test_mole_stdin unknown
set -g __u_test_brew_status 7
set -g __u_test_nvim_failure_pattern ''

function __u_test_assert_equal --argument-names expected actual message
    if test "$expected" != "$actual"
        echo "FAIL: $message (expected '$expected', got '$actual')" >&2
        set -g __u_test_failures (math $__u_test_failures + 1)
    end
end

function __u_test_assert_command --argument-names expected message
    if not contains -- "$expected" $__u_test_commands
        echo "FAIL: $message (missing '$expected')" >&2
        set -g __u_test_failures (math $__u_test_failures + 1)
    end
end

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

# Keep every updater isolated from the machine. Only Homebrew fails so the
# final status can be asserted deterministically.
function bash
    set -a __u_test_commands (string join ' ' -- bash $argv)
    if string match --quiet -- '*brew update*' "$argv"
        return $__u_test_brew_status
    end
    return 0
end

function fish
    set -a __u_test_commands (string join ' ' -- fish $argv)
    return 0
end

function env
    set -a __u_test_commands (string join ' ' -- env $argv)
    return 0
end

function uv
    set -a __u_test_commands (string join ' ' -- uv $argv)
    return 0
end

function fisher
    set -a __u_test_commands (string join ' ' -- fisher $argv)
    return 0
end

function nvim
    set -l command (string join ' ' -- nvim $argv)
    set -a __u_test_commands $command
    if test -n "$__u_test_nvim_failure_pattern"; and string match --quiet -- "*$__u_test_nvim_failure_pattern*" "$command"
        return 9
    end
    return 0
end

function ya
    set -a __u_test_commands (string join ' ' -- ya $argv)
    return 0
end

function mas
    set -a __u_test_commands (string join ' ' -- mas $argv)
    return 0
end

function mo
    set -a __u_test_commands (string join ' ' -- mo $argv)
    if test -t 0
        set -g __u_test_mole_stdin tty
    else
        set -g __u_test_mole_stdin noninteractive
    end
    return 0
end

set -gx HOME $repo_root/fish/tests/fixtures/home

# These names belonged to the shell before u ran and must survive unchanged.
function _section
    echo preserved
end
set -g __u_failures preserved

u >/dev/null 2>/dev/null
set -l u_status $status

__u_test_assert_equal 1 $u_status 'u returns failure when an updater fails'
__u_test_assert_equal yes (functions -q _section; and echo yes; or echo no) 'pre-existing helper survives'
__u_test_assert_equal preserved "$__u_failures" 'pre-existing global survives'
__u_test_assert_command 'bash -lc pnpm update -g && pnpm store prune' 'pnpm prune still runs on every update'
__u_test_assert_command 'mas update' 'MAS uses its canonical update command'
__u_test_assert_command 'mo clean' 'Mole runs directly'
__u_test_assert_equal noninteractive $__u_test_mole_stdin 'Mole cleanup is explicitly non-interactive'
__u_test_assert_nvim_sequence

# A second, successful run proves pnpm cleanup remains part of every update.
set __u_test_brew_status 0
set __u_test_commands
u >/dev/null 2>/dev/null
set -l second_status $status

__u_test_assert_equal 0 $second_status 'u returns success when every updater succeeds'
__u_test_assert_command 'bash -lc pnpm update -g && pnpm store prune' 'pnpm prune runs on subsequent updates'
__u_test_assert_nvim_sequence

# A Neovim failure must affect u's status without stopping later updates.
set __u_test_nvim_failure_pattern nvim-treesitter
set __u_test_commands
u >/dev/null 2>/dev/null
set -l nvim_failure_status $status

__u_test_assert_equal 1 $nvim_failure_status 'u returns failure when a Neovim update step fails'
__u_test_assert_nvim_sequence
__u_test_assert_command 'ya pkg upgrade' 'updates after Neovim continue after a failure'

functions --erase __u_test_assert_equal __u_test_assert_command __u_test_assert_match __u_test_assert_nvim_sequence
functions --erase bash fish env uv fisher nvim ya mas mo _section
set -e __u_failures

if test $__u_test_failures -gt 0
    echo "$__u_test_failures test(s) failed" >&2
    exit 1
end

echo 'u tests passed'
