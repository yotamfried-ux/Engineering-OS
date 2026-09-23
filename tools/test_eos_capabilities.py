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


def test_manifest_profiles_are_small_and_qualified() -> None:
    manifest = eos.load_manifest()
    assert manifest["profiles"]["core"]["tools"] == ["superpowers", "rtk", "graphify"]
    assert manifest["profiles"]["mobile"]["tools"] == ["superpowers", "rtk", "graphify", "maestro"]
    assert set(manifest["tools"]) == {"superpowers", "rtk", "graphify", "maestro"}
    for item in manifest["tools"].values():
        assert item["qualified_version"]
        assert item["activation"]


def test_resolve_tools_does_not_install_catalog() -> None:
    manifest = eos.load_manifest()
    assert len(eos.resolve_tools(manifest, "core")) == 3
    assert len(eos.resolve_tools(manifest, "mobile")) == 4


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


def test_state_is_local_to_git_checkout() -> None:
    with tempfile.TemporaryDirectory() as temp:
        project = Path(temp)
        (project / ".git").mkdir()
        assert eos.state_path(project) == project / ".git" / "engineering-os-tools.json"


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


def test_setup_skips_ready_host_tools() -> None:
    manifest = eos.load_manifest()
    with tempfile.TemporaryDirectory() as temp:
        project = Path(temp)
        with mock.patch.object(eos, "tool_status", return_value={"ready": True, "detail": "already"}), \
             mock.patch.object(eos, "version_matches", return_value=True), \
             mock.patch.object(eos, "command_exists", return_value=True), \
             mock.patch.object(eos, "ensure_graphify_project") as graph_project, \
             mock.patch.object(eos, "run"), \
             mock.patch.object(eos, "git_head", return_value="abc"), \
             mock.patch.object(eos, "print_status", return_value=0):
            rc = eos.setup(manifest, project, "core", False)
        assert rc == 0
        graph_project.assert_called_once()


def main() -> int:
    tests = [
        value for name, value in sorted(globals().items())
        if name.startswith("test_") and callable(value)
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    print(f"PASS Engineering-OS capability installer contract ({len(tests)} tests)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
