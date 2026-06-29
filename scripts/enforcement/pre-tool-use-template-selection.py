#!/usr/bin/env python3
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
CHECK = SCRIPT_DIR / "check-required-templates.py"


def is_plan(path: str) -> bool:
    normalized = path.replace("\\", "/")
    return normalized.startswith(".claude/plans/") or "/.claude/plans/" in normalized


def newest_plan() -> str:
    plans_dir = Path(".claude/plans")
    if not plans_dir.is_dir():
        return ""
    plans = [p for p in plans_dir.glob("*.md") if p.name not in {"README.md", "_TEMPLATE.md"}]
    if not plans:
        return ""
    return str(max(plans, key=lambda p: p.stat().st_mtime))


def select_plan(target: str) -> str:
    if is_plan(target) and Path(target).is_file():
        return target
    active = os.environ.get("EOS_ACTIVE_PLAN")
    if active and Path(active).is_file():
        return active
    if Path(".claude/plans/active.md").is_file():
        return ".claude/plans/active.md"
    return newest_plan()


def proposed_content(tool: str, target: str, tool_input: dict) -> str | None:
    if tool == "Write":
        for key in ("content", "text", "new_content"):
            value = tool_input.get(key)
            if isinstance(value, str):
                return value
        return None

    try:
        current = Path(target).read_text(encoding="utf-8")
    except Exception:
        return None

    if tool == "Edit":
        old = tool_input.get("old_string")
        new = tool_input.get("new_string")
        if isinstance(old, str) and isinstance(new, str) and old in current:
            return current.replace(old, new, 1)
        return None

    if tool == "MultiEdit":
        edits = tool_input.get("edits")
        if not isinstance(edits, list):
            return None
        result = current
        for edit in edits:
            if not isinstance(edit, dict):
                continue
            old = edit.get("old_string")
            new = edit.get("new_string")
            replace_all = bool(edit.get("replace_all"))
            if isinstance(old, str) and isinstance(new, str) and old in result:
                result = result.replace(old, new) if replace_all else result.replace(old, new, 1)
        return result

    return None


def run_check(plan_path: str, target: str) -> int:
    proc = subprocess.run(
        [sys.executable, str(CHECK), "--plan", plan_path, "--target", target],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    if proc.returncode != 0:
        print("template selection gate failed: " + proc.stdout.strip(), file=sys.stderr)
    else:
        print("template selection checks passed")
    return proc.returncode


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    tool = payload.get("tool_name") or payload.get("tool") or ""
    if tool not in {"Write", "Edit", "MultiEdit", "NotebookEdit"}:
        return 0
    tool_input = payload.get("tool_input") if isinstance(payload.get("tool_input"), dict) else payload
    target = tool_input.get("file_path") or ""
    if not target:
        return 0

    plan = select_plan(target)
    if not plan:
        return 0

    if is_plan(target):
        content = proposed_content(tool, target, tool_input)
        if content is not None:
            with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False, suffix=".md") as tmp:
                tmp.write(content)
                tmp_path = tmp.name
            try:
                return run_check(tmp_path, target)
            finally:
                try:
                    os.unlink(tmp_path)
                except OSError:
                    pass

    if not Path(plan).is_file():
        return 0
    return run_check(plan, target)


if __name__ == "__main__":
    raise SystemExit(main())
