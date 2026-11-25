"""Offline tests for project-scoped npm library registration and readiness."""
from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import eos_capabilities as eos  # noqa: E402


class ProjectInstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.project = Path(self.temp.name)
        self.tool = {"installer": "project-npm",
                     "packages": ["@ui-sdk/core", "@ui-sdk/react"]}

    def test_missing_project_cannot_be_ready(self):
        result = eos.tool_status("ui-sdk-react", self.tool, self.project)
        self.assertFalse(result["ready"])

    def test_requires_dependencies_and_local_package_files(self):
        (self.project / "package.json").write_text(json.dumps({
            "dependencies": {"@ui-sdk/core": "1.0.0", "@ui-sdk/react": "1.0.0"}
        }))
        missing = eos.tool_status("ui-sdk-react", self.tool, self.project)
        self.assertFalse(missing["ready"], missing)
        for name in self.tool["packages"]:
            target = self.project / "node_modules" / name / "package.json"
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text('{"name":"' + name + '"}')
        installed = eos.tool_status("ui-sdk-react", self.tool, self.project)
        self.assertTrue(installed["ready"], installed)

    def test_bundled_cli_has_real_help_entrypoint(self):
        registry = eos.load_manifest()
        for name in ["openverse-audio", "react-bits"]:
            result = eos.tool_status(name, registry["tools"][name], self.project)
            self.assertTrue(result["ready"], result)


if __name__ == "__main__":
    unittest.main()
