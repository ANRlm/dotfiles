"""Offline regressions: temporary HOME, mocked integrations, no real updates."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
UPDATE_SCRIPT = r'''
source "$AUDIT_ROOT/fish/functions/u.fish"
for name in brew npm pnpm mise npx thcli bl aliyun tccli rex codex pi grok uv mas ya mo bash __u_brewfile_merge __u_sync_skills __u_add_skill_families
    eval "function $name; return 0; end"
end
# Pretend the CLIs in $MISSING are not installed, even if the machine has them.
function type
    contains -- $argv[-1] (string split ' ' -- "$MISSING"); and return 1
    builtin type $argv
end
function claude
    if test "$argv[2]" = list
        printf '%s\n' "$CLAUDE_LIST"
        return $CLAUDE_EXIT
    end
    test "$argv[2]" != update; or echo "UPDATED claude $argv[3] $argv[5] in $PWD"
    return 0
end
u
'''


class RuntimeTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.home = Path(temp.name)
        (self.home / '.agents/skills').mkdir(parents=True)
        self.env = dict(os.environ, HOME=temp.name, XDG_CONFIG_HOME=temp.name + '/config',
                        TERM='xterm-256color', AUDIT_ROOT=str(ROOT),
                        CLAUDE_LIST='[]', CLAUDE_EXIT='0')

    def update(self, **overrides):
        return subprocess.run(['fish', '--no-config', '-c', UPDATE_SCRIPT],
                              env={**self.env, **overrides}, capture_output=True, text=True, timeout=20)

    def test_plugin_query_and_parse_failures_reach_final_status(self):
        for overrides in ({'CLAUDE_EXIT': '42'}, {'CLAUDE_LIST': '{broken'},
                          {'CLAUDE_LIST': ''}, {'CLAUDE_LIST': '{}'},
                          {'CLAUDE_LIST': 'null'}):
            with self.subTest(overrides=overrides):
                result = self.update(**overrides)
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertIn('1 failure(s)', result.stdout)
                self.assertNotIn('All updated', result.stdout)

    def test_empty_lists_succeed_and_plugins_are_deduplicated(self):
        self.assertEqual(self.update().returncode, 0)
        result = self.update(CLAUDE_LIST='[{"id":"a@market"},{"id":"a@market"},{"id":"local@skills-dir"}]')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.count('UPDATED claude a@market'), 1)
        self.assertNotIn('UPDATED claude local', result.stdout)

    def test_project_scope_plugins_update_inside_their_project(self):
        project = self.home / 'project'
        project.mkdir()
        listing = ('[{"id":"a@m","scope":"user"},{"id":"a@m","scope":"project","projectPath":"%s"},'
                   '{"id":"a@m","scope":"project","projectPath":"%s/gone"},{"id":"b@m","scope":"managed"}]'
                   % (project, self.home))
        result = subprocess.run(['fish', '--no-config', '-c', 'cd $HOME; ' + UPDATE_SCRIPT + '; pwd'],
                                env={**self.env, 'CLAUDE_LIST': listing}, capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn(f'UPDATED claude a@m user in {self.home}', result.stdout)
        self.assertIn(f'UPDATED claude a@m project in {project}', result.stdout)
        self.assertIn('is gone', result.stdout)
        self.assertNotIn('b@m', result.stdout)
        self.assertTrue(result.stdout.rstrip().endswith(str(self.home)), result.stdout)

    def test_listed_skill_names_are_parsed(self):
        listing = ('\x1b[2m│\x1b[0m\n│    lark-im\n│\n│      Files: 30\n│      Description text\n'
                   '│    alibabacloud-agentloop-dataset\n└  Run without --list to install\n')
        result = subprocess.run(['fish', '--no-config', '-c',
                                 'source "$AUDIT_ROOT/fish/functions/u.fish"; printf "$LISTING" | __u_listed_skills'],
                                env={**self.env, 'LISTING': listing}, capture_output=True, text=True, timeout=20)
        self.assertEqual(result.stdout.split(), ['lark-im', 'alibabacloud-agentloop-dataset'])

    def test_missing_cloud_skill_clis_are_skipped(self):
        result = self.update(MISSING='thcli bl aliyun tccli rex')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('tccli not installed, skipped', result.stdout)
        self.assertNotIn('ClawHub skills updated', result.stdout)
        self.assertIn('thcli not installed, skipped', result.stdout)
        self.assertIn('bl not installed, skipped', result.stdout)
        self.assertIn('aliyun not installed, skipped', result.stdout)
        self.assertIn('rex not installed, skipped', result.stdout)
        self.assertNotIn('TokenHub skills updated', result.stdout)

    def test_agentloop_skills_need_aliyun(self):
        script = r'''
source "$AUDIT_ROOT/fish/functions/u.fish"
function npx
    echo "NPX $argv" >>$HOME/npx.calls
    contains -- --list $argv; or return 0
    if string match -q -- '*lark-cli*' $argv
        printf '│    %s\n' lark-im lark-vc-agent
    else
        printf '│    %s\n' alibabacloud-agentloop-dataset
    end
end
function type
    contains -- $argv[-1] (string split ' ' -- "$MISSING"); and return 1
    builtin type $argv
end
function aliyun; end
__u_add_skill_families
'''
        calls_file = self.home / 'npx.calls'
        for missing, expected in (('aliyun', False), ('', True)):
            with self.subTest(missing=missing):
                calls_file.unlink(missing_ok=True)
                result = subprocess.run(['fish', '--no-config', '-c', script],
                                        env={**self.env, 'MISSING': missing}, capture_output=True, text=True, timeout=20)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertEqual(result.stdout + result.stderr, '')
                calls = calls_file.read_text()
                lark = [line for line in calls.splitlines() if 'lark-cli' in line and '--list' not in line]
                self.assertEqual(len(lark), 1, calls)
                self.assertIn('--skill lark-im -g', lark[0])
                self.assertNotIn('remove', calls)
                self.assertEqual('alibabacloud-aiops-skills' in calls, expected, calls)

    def test_empty_lark_listing_fails_without_installing(self):
        script = 'source "$AUDIT_ROOT/fish/functions/u.fish"; function npx; echo "NPX $argv" >>$HOME/npx.calls; end; __u_add_skill_families'
        result = subprocess.run(['fish', '--no-config', '-c', script], env=self.env,
                                capture_output=True, text=True, timeout=20)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('No Lark skills listed', result.stderr)
        self.assertNotIn('--skill', (self.home / 'npx.calls').read_text())

    def test_quiet_output_shows_only_on_failure(self):
        for code, expected in ((0, ''), (3, 'noisy\n')):
            with self.subTest(code=code):
                result = subprocess.run(['fish', '--no-config', '-c',
                                         f'source "$AUDIT_ROOT/fish/functions/u.fish"; __u_quiet sh -c "echo noisy; exit {code}"'],
                                        env=self.env, capture_output=True, text=True, timeout=20)
                self.assertEqual(result.returncode, code)
                self.assertEqual(result.stdout, expected)

    def test_npm_update_leaves_npm_to_homebrew(self):
        script = r'''
source "$AUDIT_ROOT/fish/functions/u.fish"
function npm
    switch $argv[1]
        case root
            echo /prefix/lib/node_modules
        case ls
            printf '%s\n' /prefix/lib (string split ' ' -- $GLOBALS)
        case update
            echo "NPM $argv"
    end
end
__u_npm_update
'''
        for globals, expected in (
                ('/prefix/lib/node_modules/@larksuite/cli /prefix/lib/node_modules/npm /linked/pkg',
                 'NPM update -g --allow-scripts=@larksuite/cli,bailian-cli @larksuite/cli'),
                ('/prefix/lib/node_modules/npm', '')):
            with self.subTest(globals=globals):
                result = subprocess.run(['fish', '--no-config', '-c', script], env={**self.env, 'GLOBALS': globals},
                                        capture_output=True, text=True, timeout=20)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout.strip(), expected)

    def test_machine_without_agent_tools_succeeds(self):
        (self.home / '.agents/skills').rmdir()
        result = self.update(MISSING='claude codex pi grok aliyun uv mas ya mo')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('shared skills skipped', result.stdout)
        for name in ('claude', 'codex', 'pi', 'grok', 'mo'):
            self.assertIn(f'{name} not installed, skipped', result.stdout)
        self.assertNotIn('UPDATED claude', result.stdout)

    def test_mise_node_remains_first_after_config_initialization(self):
        node = self.home / 'mise/bin/node'
        node.parent.mkdir(parents=True)
        node.write_text('#!/bin/sh\necho selected-project-node\n')
        node.chmod(0o755)
        script = r'''
function mise
    if test "$argv[1]" = activate
        echo 'set -gx PATH "$HOME/mise/bin" $PATH'
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
