"""Offline tests; only temporary HOME/profile directories are modified."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


UPDATE = Path(__file__).resolve().parents[1] / "functions/u.fish"


class SkillLinkTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name).resolve()
        self.shared = self.home / ".agents/skills"
        self.shared.mkdir(parents=True)
        self.profile = self.home / ".claude-profiles/default profile"
        self.env = {**os.environ, "HOME": str(self.home),
                    "CLAUDE_CONFIG_DIR": str(self.profile), "UPDATE": str(UPDATE)}

    def skill(self, name):
        directory = self.shared / name
        directory.mkdir(parents=True)
        (directory / "SKILL.md").write_text("---\nname: example\ndescription: Test fixture\n---\n")
        return directory

    def sync(self, success=True):
        result = subprocess.run(
            ["fish", "--no-config", "-c", 'source "$UPDATE"; __u_sync_skills'],
            env=self.env, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def test_scoped_skills_and_idempotence(self):
        ordinary = self.skill("ordinary")
        scoped = self.skill("@tencent-adm/tencentcloud-api-skill")
        self.sync()
        self.sync()
        for source in [ordinary, scoped]:
            link = self.profile / "skills" / source.name
            self.assertTrue(link.is_symlink())
            self.assertEqual(link.resolve(), source)
        self.assertFalse((self.home / ".codex/skills").exists())
        self.assertFalse((self.home / ".pi/agent/skills").exists())

    def test_follow_local_skill_symlinks(self):
        source = self.home / "local-skill"
        source.mkdir()
        (source / "SKILL.md").write_text("Local fixture")
        (self.shared / "custom").symlink_to(source)
        self.sync()
        self.assertEqual((self.profile / "skills/custom").resolve(), source)

    def test_existing_equivalent_link_is_preserved(self):
        source = self.skill("existing")
        target = self.profile / "skills"
        target.mkdir(parents=True)
        link = target / source.name
        link.symlink_to(os.path.relpath(source, target))
        before = os.readlink(link)
        self.sync()
        self.assertEqual(os.readlink(link), before)

    def test_conflicting_directory_is_preserved(self):
        self.skill("conflict")
        conflict = self.profile / "skills/conflict"
        conflict.mkdir(parents=True)
        sentinel = conflict / "user-data"
        sentinel.write_text("keep")
        self.assertIn("Skill link conflict:", self.sync(success=False).stderr)
        self.assertEqual(sentinel.read_text(), "keep")

    def test_broken_link_is_preserved_and_reported(self):
        self.skill("broken")
        target = self.profile / "skills"
        target.mkdir(parents=True)
        link = target / "broken"
        link.symlink_to("/nonexistent/test-skill")
        self.assertIn("Skill link conflict:", self.sync(success=False).stderr)
        self.assertEqual(os.readlink(link), "/nonexistent/test-skill")

    def test_default_profile(self):
        self.env.pop("CLAUDE_CONFIG_DIR")
        self.skill("default")
        self.sync()
        self.assertTrue((self.home / ".claude/skills/default").is_symlink())

    def test_duplicate_basename_is_reported(self):
        self.skill("@one/duplicate")
        self.skill("@two/duplicate")
        self.assertIn("Skill link conflict:", self.sync(success=False).stderr)


DELETED_UPDATE = (
    "Warning: The following skills from mattpocock/skills appear to have been deleted upstream:\n"
    "  \x1b[2m\u2022\x1b[0m ghost-skill\n"
    "  \x1b[2m\u2022\x1b[0m another-gone\n"
    "\n"
    "New skills available:\n"
    "  \u2022 fresh-skill\n"
)


class SkillPruneTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name).resolve()
        self.bin = self.home / "bin"
        self.bin.mkdir()
        self.env = {**os.environ, "HOME": str(self.home), "UPDATE": str(UPDATE)}

    def stub_npx(self, output, code=0):
        # Records removals so the test never needs the network.
        script = self.bin / "npx"
        script.write_text(
            "#!/bin/sh\n"
            f'case "$*" in\n'
            f'  *"skills remove"*) echo "$@" >> "$HOME/removed.txt" ;;\n'
            f'  *"skills update"*) printf %s "$STUB_UPDATE_OUTPUT" ; exit "$STUB_UPDATE_EXIT" ;;\n'
            "esac\n"
            "exit 0\n"
        )
        script.chmod(0o755)
        self.env.update({"STUB_UPDATE_OUTPUT": output, "STUB_UPDATE_EXIT": str(code),
                         "PATH": f"{self.bin}:{os.environ['PATH']}"})

    def update(self, success=True):
        result = subprocess.run(
            ["fish", "--no-config", "-c", 'source "$UPDATE"; __u_update_skills'],
            env=self.env, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def test_parser_reads_only_the_warning_block(self):
        result = subprocess.run(
            ["fish", "--no-config", "-c", 'source "$UPDATE"; __u_deleted_skills'],
            input=DELETED_UPDATE, env=self.env, capture_output=True, text=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.split(), ["ghost-skill", "another-gone"])

    def test_deleted_skills_are_removed_after_update(self):
        self.stub_npx(DELETED_UPDATE)
        self.update()
        self.assertIn("skills remove ghost-skill another-gone", (self.home / "removed.txt").read_text())

    def test_nothing_removed_without_the_warning(self):
        self.stub_npx("\u2713 All global skills are up to date\n")
        self.update()
        self.assertFalse((self.home / "removed.txt").exists())

    def test_failed_update_still_fails(self):
        self.stub_npx(DELETED_UPDATE, code=7)
        self.update(success=False)
        self.assertFalse((self.home / "removed.txt").exists())


if __name__ == "__main__":
    unittest.main()
