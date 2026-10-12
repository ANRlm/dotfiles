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


if __name__ == "__main__":
    unittest.main()
