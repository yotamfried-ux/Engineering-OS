#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import json
import tempfile
from pathlib import Path
from unittest import mock

ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "tools" / "eos_capabilities.py"

spec = importlib.util.spec_from_file_location("eos_capabilities", MODULE_PATH)
assert spec and spec.loader
eos = importlib.util.module_from_spec(spec)
spec.loader.exec_module(eos)


EXPECTED_TOOLS = {
    "superpowers", "rtk", "graphify", "maestro", "claude-mem", "gstack",
    "ui-ux-pro-max", "cli-anything", "playwright-mcp", "chrome-devtools-mcp",
    "mobile-next-mcp", "appium-mcp", "claude-code-workflows", "laya-coreml",
    "frontend-design",
}


def test_catalog_covers_integrated_and_testing_tools() -> None:
    manifest = eos.load_manifest()
    assert set(manifest["tools"]) == EXPECTED_TOOLS
    for name, item in manifest["tools"].items():
        assert item["scope"]
        assert item["automation"]
        assert item["installer"]
        assert item["activation"], name


def test_profiles_remain_small_not_blanket_install() -> None:
    manifest = eos.load_manifest()
    assert manifest["profiles"]["core"]["tools"] == ["superpowers", "rtk", "graphify"]
    assert manifest["profiles"]["mobile"]["tools"] == ["superpowers", "rtk", "graphify", "maestro"]
    assert len(manifest["profiles"]["mobile-deep"]["tools"]) < len(manifest["tools"])


def test_project_manifest_drives_every_declared_tool() -> None:
    manifest = eos.load_manifest()
    with tempfile.TemporaryDirectory() as temp:
        project = Path(temp)
        path = eos.project_manifest_path(manifest, project)
        path.write_text(json.dumps({"tools": ["rtk", "maestro", "playwright-mcp"]}), encoding="utf-8")
        assert eos.resolve_tools(manifest, "auto", project) == ["rtk", "maestro", "playwright-mcp"]


def test_auto_falls_back_to_core_without_project_manifest() -> None:
    manifest = eos.load_manifest()
    with tempfile.TemporaryDirectory() as temp:
        project = Path(temp)
        assert eos.resolve_tools(manifest, "auto", project) == ["superpowers", "rtk", "graphify"]


def test_graph_ready_is_exact_head_scoped() -> None:
    with tempfile.TemporaryDirectory() as temp:
        project = Path(temp)
        (project / "graphify-out").mkdir()
        (project / "graphify-out" / "graph.json").write_text("{}", encoding="utf-8")
        (project / "graphify-out" / ".engineering-os-head").write_text("abc\n", encoding="utf-8")
        with mock.patch.object(eos, "git_head", return_value="abc"):
            assert eos.graph_ready(project)
        with mock.patch.object(eos, "git_head", return_value="def"):
            assert not eos.graph_ready(project)


def test_project_mcp_install_is_one_time() -> None:
    tool = {"mcp_name": "playwright", "package": "@playwright/mcp@latest"}
    with tempfile.TemporaryDirectory() as temp:
        project = Path(temp)
        with mock.patch.object(eos, "mcp_ready", side_effect=[False]), \
             mock.patch.object(eos, "command_exists", return_value=True), \
             mock.patch.object(eos, "run") as run:
            eos.ensure_project_mcp("playwright-mcp", tool, project, False)
        run.assert_called_once()
        assert "@playwright/mcp@latest" in run.call_args[0][0]


def test_project_mcp_skips_when_registered() -> None:
    tool = {"mcp_name": "playwright", "package": "@playwright/mcp@latest"}
    with tempfile.TemporaryDirectory() as temp:
        project = Path(temp)
        with mock.patch.object(eos, "mcp_ready", return_value=True), \
             mock.patch.object(eos, "run") as run:
            eos.ensure_project_mcp("playwright-mcp", tool, project, False)
        run.assert_not_called()


def test_manual_capability_fails_closed_to_one_activation_doc() -> None:
    manifest = eos.load_manifest()
    with tempfile.TemporaryDirectory() as temp:
        project = Path(temp)
        assert eos.ensure_tool(
            "claude-code-workflows",
            manifest["tools"]["claude-code-workflows"],
            project,
            True,
        ) is False


def test_init_project_persists_profile_tools() -> None:
    manifest = eos.load_manifest()
    with tempfile.TemporaryDirectory() as temp:
        project = Path(temp)
        assert eos.init_project(manifest, project, "mobile", False) == 0
        payload = json.loads(eos.project_manifest_path(manifest, project).read_text(encoding="utf-8"))
        assert payload["tools"] == ["superpowers", "rtk", "graphify", "maestro"]


def test_status_json_is_machine_readable() -> None:
    manifest = eos.load_manifest()
    with tempfile.TemporaryDirectory() as temp:
        project = Path(temp)
        with mock.patch.object(eos, "tool_status", return_value={"ready": True, "detail": "ok"}):
            with mock.patch("builtins.print") as printed:
                rc = eos.print_status(manifest, project, "core", True)
        assert rc == 0
        payload = json.loads(printed.call_args[0][0])
        assert payload["ready"] is True
        assert set(payload["tools"]) == {"superpowers", "rtk", "graphify"}


def main() -> int:
    tests = [
        value for name, value in sorted(globals().items())
        if name.startswith("test_") and callable(value)
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    print(f"PASS Engineering-OS capability manager contract ({len(tests)} tests)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
