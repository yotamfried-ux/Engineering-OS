#!/usr/bin/env python3
"""Verify dispatcher guard commands are registered under applicable hook scopes."""
from __future__ import annotations

import json
import os
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
GUARD = ROOT / "scripts" / "monitoring" / "require-telemetry-session.sh"
DISPATCH = ROOT / "scripts" / "monitoring" / "eos-telemetry-dispatch.sh"


def command(action: str) -> str:
    return f'bash "{DISPATCH}" {action}'


def settings() -> dict:
    return {
        "hooks": {
            "SessionStart": [{"hooks": [{"type": "command", "command": command("session_start")}]}],
            "PreToolUse": [{
                "matcher": ".*",
                "hooks": [
                    {"type": "command", "command": command("guard")},
                    {"type": "command", "command": command("pre_tool_use")},
                ],
            }],
            "Stop": [{"hooks": [{"type": "command", "command": command("stop")}]}],
            "StopFailure": [{"hooks": [{"type": "command", "command": command("stop_failure")}]}],
            "SessionEnd": [{"hooks": [{"type": "command", "command": command("session_end")}]}],
        }
    }


def run_guard(repo: Path, settings_path: Path) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env.update({
        "EOS_TELEMETRY_HOOK_MODE": "dispatcher",
        "EOS_CLAUDE_SETTINGS_FILE": str(settings_path),
    })
    return subprocess.run(
        ["bash", str(GUARD)],
        cwd=repo,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        base = Path(tmp)
        repo = base / "managed"
        telemetry = repo / ".engineering-os" / "telemetry"
        telemetry.mkdir(parents=True)
        subprocess.run(["git", "init", "-q", str(repo)], check=True)

        (repo / ".engineering-os" / "telemetry-policy.json").write_text(
            json.dumps({
                "schema_version": "eos.telemetry.policy.v1",
                "remote_handoff": {"mode": "disabled"},
            }),
            encoding="utf-8",
        )
        run_id = "guard-event-test"
        (telemetry / "run_id").write_text(run_id + "\n", encoding="utf-8")
        (telemetry / "events.jsonl").write_text(
            json.dumps({
                "name": "eos.session_start",
                "trace_id": run_id,
                "attributes": {"eos.event.name": "session_start"},
            }) + "\n",
            encoding="utf-8",
        )

        settings_path = base / "settings.json"
        correct = settings()
        settings_path.write_text(json.dumps(correct), encoding="utf-8")
        result = run_guard(repo, settings_path)
        assert result.returncode == 0, (result.stdout, result.stderr)

        misplaced = settings()
        start_entry = misplaced["hooks"]["SessionStart"][0]["hooks"].pop()
        misplaced["hooks"].setdefault("PostToolUse", [{"matcher": ".*", "hooks": []}])
        misplaced["hooks"]["PostToolUse"][0]["hooks"].append(start_entry)
        settings_path.write_text(json.dumps(misplaced), encoding="utf-8")
        result = run_guard(repo, settings_path)
        assert result.returncode == 2, (result.stdout, result.stderr)
        assert "missing dispatcher SessionStart" in result.stderr

        narrow = settings()
        narrow["hooks"]["PreToolUse"][0]["matcher"] = "Read"
        settings_path.write_text(json.dumps(narrow), encoding="utf-8")
        result = run_guard(repo, settings_path)
        assert result.returncode == 2, (result.stdout, result.stderr)
        assert "catch-all PreToolUse guard" in result.stderr

        split_scope = settings()
        split_scope["hooks"]["PreToolUse"] = [
            {
                "matcher": "Read",
                "hooks": [{"type": "command", "command": command("guard")}],
            },
            {
                "matcher": ".*",
                "hooks": [{"type": "command", "command": command("pre_tool_use")}],
            },
        ]
        settings_path.write_text(json.dumps(split_scope), encoding="utf-8")
        result = run_guard(repo, settings_path)
        assert result.returncode == 2, (result.stdout, result.stderr)
        assert "catch-all PreToolUse guard" in result.stderr

    print("dispatcher guard event and catch-all matcher regressions passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
