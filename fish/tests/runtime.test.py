"""Offline regressions: temporary HOME, mocked integrations, no real updates."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
UPDATE_SCRIPT = r'''
source "$AUDIT_ROOT/fish/functions/u.fish"
for name in brew env pnpm npx thcli codex pi cua-driver treehouse uv mas git ya mo __u_brewfile_merge __u_sync_skills
    eval "function $name; return 0; end"
end
function claude
    if test "$argv[2]" = list
        printf '%s\n' "$CLAUDE_LIST"
        return $CLAUDE_EXIT
    end
    test "$argv[2]" != update; or echo "UPDATED claude $argv[3]"
    return 0
end
function herdr
    if test "$argv[2]" = list
        printf '%s\n' "$HERDR_LIST"
        return $HERDR_EXIT
    end
    echo "UPDATED herdr $argv[3]"
    return 0
end
u
'''


class RuntimeTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.home = Path(temp.name)
        self.env = dict(os.environ, HOME=temp.name, XDG_CONFIG_HOME=temp.name + '/config',
                        TERM='xterm-256color', AUDIT_ROOT=str(ROOT),
                        CLAUDE_LIST='[]', CLAUDE_EXIT='0',
                        HERDR_LIST='{"result":{"plugins":[]}}', HERDR_EXIT='0')

    def update(self, **overrides):
        return subprocess.run(['fish', '--no-config', '-c', UPDATE_SCRIPT],
                              env={**self.env, **overrides}, capture_output=True, text=True, timeout=20)

    def test_plugin_query_and_parse_failures_reach_final_status(self):
        for tool in ('CLAUDE', 'HERDR'):
            for overrides in ({tool + '_EXIT': '42'}, {tool + '_LIST': '{broken'},
                              {tool + '_LIST': ''}, {tool + '_LIST': '{}'},
                              {tool + '_LIST': 'null'}):
                with self.subTest(overrides=overrides):
                    result = self.update(**overrides)
                    self.assertNotEqual(result.returncode, 0, result.stdout)
                    self.assertIn('1 failure(s)', result.stdout)
                    self.assertNotIn('All updated', result.stdout)

    def test_empty_lists_succeed_and_plugins_are_deduplicated(self):
        self.assertEqual(self.update().returncode, 0)
        result = self.update(CLAUDE_LIST='[{"id":"a@market"},{"id":"a@market"},{"id":"local@skills-dir"}]',
                             HERDR_LIST='{"result":{"plugins":[{"source":{"kind":"github","owner":"a","repo":"b"}},{"source":{"kind":"local"}}]}}')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.count('UPDATED claude a@market'), 1)
        self.assertEqual(result.stdout.count('UPDATED herdr a/b'), 1)
        self.assertNotIn('UPDATED claude local', result.stdout)

    def test_fnm_node_remains_first_after_config_initialization(self):
        node = self.home / 'fnm/bin/node'
        node.parent.mkdir(parents=True)
        node.write_text('#!/bin/sh\necho selected-project-node\n')
        node.chmod(0o755)
        script = r'''
function fnm
    if test "$argv[1]" = env
        echo 'set -gx PATH "$HOME/fnm/bin" $PATH'
    end
    return 0
end
function starship; end
function zoxide; end
function fzf; end
source "$AUDIT_ROOT/fish/config.fish"
command -s node
'''
        result = subprocess.run(['fish', '--no-config', '-i', '-c', script], env=self.env,
                                capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(Path(result.stdout.strip()).resolve(), node.resolve())


if __name__ == '__main__':
    unittest.main()
