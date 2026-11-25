"""Offline regression tests for opt-in third-party skill installation."""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import eos_reel_install as installer  # noqa: E402


class ReelSkillsInstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.upstream = self.base / "upstream"
        (self.upstream / "skills" / "hallmark").mkdir(parents=True)
        (self.upstream / "skills" / "hallmark" / "SKILL.md").write_text(
            "---\nname: hallmark\n---\n# Test skill\n", encoding="utf-8"
        )
        subprocess.run(["git", "init", "-q", str(self.upstream)], check=True)
        subprocess.run(["git", "-C", str(self.upstream), "add", "."], check=True)
        subprocess.run(
            ["git", "-C", str(self.upstream), "-c", "user.name=Test",
             "-c", "user.email=test@example.com", "commit", "-q", "-m", "init"],
            check=True
        )
        self.tool = {"repository": "example/hallmark",
                     "skill_globs": ["skills/**/SKILL.md"]}
        original_which = shutil.which

        def which(command):
            if command == "claude":
                return "/bin/true"
            return original_which(command)

        self.real_repo_url = installer._repo_url
        self.patches = [
            patch.object(installer, "CHECKOUTS", self.base / "checkouts"),
            patch.object(installer, "CLAUDE_SKILLS", self.base / "claude-skills"),
            patch.object(installer, "_repo_url", return_value=str(self.upstream)),
            patch.object(installer.shutil, "which", side_effect=which),
        ]
        for item in self.patches:
            item.start()
            self.addCleanup(item.stop)

    def test_install_is_real_idempotent_and_verifiable(self):
        self.assertFalse(installer.status("hallmark", self.tool)["ready"])
        installer.ensure("hallmark", self.tool)
        result = installer.status("hallmark", self.tool)
        self.assertTrue(result["ready"], result)
        self.assertTrue((installer.CLAUDE_SKILLS / "hallmark").is_symlink())
        self.assertTrue((installer.CLAUDE_SKILLS / "hallmark" / "SKILL.md").is_file())
        head = subprocess.check_output(
            ["git", "-C", str(installer.CHECKOUTS / "hallmark"), "rev-parse", "HEAD"],
            text=True
        ).strip()
        installer.ensure("hallmark", self.tool)
        head_after = subprocess.check_output(
            ["git", "-C", str(installer.CHECKOUTS / "hallmark"), "rev-parse", "HEAD"],
            text=True
        ).strip()
        self.assertEqual(head, head_after)

    def test_refuses_overwriting_other_skill(self):
        installer.CLAUDE_SKILLS.mkdir(parents=True)
        existing = installer.CLAUDE_SKILLS / "hallmark"
        existing.mkdir()
        with self.assertRaisesRegex(RuntimeError, "Refusing to overwrite"):
            installer.ensure("hallmark", self.tool)
        self.assertTrue(existing.is_dir())
        self.assertFalse(existing.is_symlink())

    def test_dry_run_does_not_mutate_home(self):
        installer.ensure("hallmark", self.tool, dry_run=True)
        self.assertFalse(installer.CHECKOUTS.exists())
        self.assertFalse(installer.CLAUDE_SKILLS.exists())

    def test_rejects_unsafe_paths(self):
        with self.assertRaisesRegex(RuntimeError, "Invalid canonical"):
            self.real_repo_url({"repository": "../../unsafe"})
        with self.assertRaisesRegex(RuntimeError, "Unsafe skill glob"):
            installer._sources(self.upstream, {"skill_globs": ["../foo/SKILL.md"]})

    def test_manifest_registered_activation_documents_exist(self):
        manifest = json.loads(
            (ROOT / "capability-registry" / "INSTALL-PROFILES.json").read_text()
        )
        self.assertIn("reels-all", manifest["profiles"])
        for name in manifest["profiles"]["reels-all"]["tools"]:
            tool = manifest["tools"][name]
            self.assertIn(tool["installer"], {"git-skills", "claude-plugin", "bundled-cli"})
            self.assertTrue((ROOT / tool["activation"]).is_file(), name)


if __name__ == "__main__":
    unittest.main()
