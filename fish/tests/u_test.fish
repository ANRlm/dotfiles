#!/usr/bin/env fish

set -l repo_root (path resolve (status dirname)/../..)
set -g __u_test_updater $repo_root/fish/functions/u.fish
source $__u_test_updater

set -g __u_test_failures 0

function __u_test_assert_equal --argument-names expected actual message
    if test "$expected" != "$actual"
        echo "FAIL: $message (expected '$expected', got '$actual')" >&2
        set -g __u_test_failures (math $__u_test_failures + 1)
    end
end

function __u_test_assert_source --argument-names pattern message
    if not string match --quiet -- $pattern (string collect <$__u_test_updater)
        echo "FAIL: $message" >&2
        set -g __u_test_failures (math $__u_test_failures + 1)
    end
end

if not functions -q __u_retry
    echo 'FAIL: retry helper is defined' >&2
    set -g __u_test_failures (math $__u_test_failures + 1)
else
    set -g __u_test_attempts 0

    function __u_test_flaky
        set -g __u_test_attempts (math $__u_test_attempts + 1)
        test $__u_test_attempts -ge 2
    end

    function sleep
    end

    __u_retry 3 __u_test_flaky >/dev/null
    set -l retry_status $status

    __u_test_assert_equal 0 $retry_status 'retry returns success after a transient failure'
    __u_test_assert_equal 2 $__u_test_attempts 'retry reruns a transiently failing command'

    functions --erase __u_test_flaky sleep
    set -e __u_test_attempts
end

__u_test_assert_source '*__u_run "Yazi plugins updated" __u_retry 3 ya pkg upgrade*' 'Yazi package updates retry transient failures'
__u_test_assert_source '*__u_run "Plugins synced" __u_retry 3 nvim --headless*' 'Lazy sync retries transient failures'
__u_test_assert_source '*Plugin.has_errors(plugin)*vim.cmd("cquit")*' 'Lazy task errors produce a non-zero Neovim exit'

functions --erase __u_test_assert_equal __u_test_assert_source
set -e __u_test_updater

if test $__u_test_failures -gt 0
    echo "$__u_test_failures test(s) failed" >&2
    exit 1
end

echo 'u tests passed'
