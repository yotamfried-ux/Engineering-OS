#!/usr/bin/env python3
"""Summarize privacy-safe Engineering OS telemetry JSONL.

Input defaults to .engineering-os/telemetry/events.jsonl in the current repo.
Output is Markdown by default so it can be pasted into a run report or PR.
"""

from __future__ import annotations

import argparse
import collections
import json
from pathlib import Path
from typing import Any


def load_events(path: Path) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    if not path.exists():
        return events
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            item = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(item, dict):
            events.append(item)
    return events


def count_by(events: list[dict[str, Any]], key: str) -> collections.Counter[str]:
    c: collections.Counter[str] = collections.Counter()
    for event in events:
        value = event.get(key) or "unknown"
        c[str(value)] += 1
    return c


def nested_count(events: list[dict[str, Any]], parent: str, child: str) -> collections.Counter[str]:
    c: collections.Counter[str] = collections.Counter()
    for event in events:
        obj = event.get(parent) if isinstance(event.get(parent), dict) else {}
        value = obj.get(child) if isinstance(obj, dict) else None
        c[str(value or "unknown")] += 1
    return c


def fmt_counter(counter: collections.Counter[str], limit: int = 12) -> str:
    if not counter:
        return "- none\n"
    return "".join(f"- {name}: {count}\n" for name, count in counter.most_common(limit))


def summarize(events: list[dict[str, Any]], source: Path) -> str:
    if not events:
        return f"# Engineering OS telemetry summary\n\nNo events found in `{source}`.\n"

    timestamps = [int(e.get("timestamp_unix", 0) or 0) for e in events if e.get("timestamp_unix")]
    duration = max(timestamps) - min(timestamps) if len(timestamps) >= 2 else 0
    command_categories = count_by(events, "command_category")
    tools = count_by(events, "tool_name")
    hooks = count_by(events, "event_name")
    branches = count_by(events, "git_branch")
    extensions = nested_count(events, "target_path", "extension")
    top_dirs = nested_count(events, "target_path", "top_dir")
    active_plans = count_by(events, "active_plan")

    risk_signals = []
    if command_categories.get("dependency-install", 0):
        risk_signals.append("dependency-install commands were observed; verify Context7/source-of-truth evidence exists.")
    if command_categories.get("cloud-deploy", 0):
        risk_signals.append("cloud/deploy commands were observed; verify deployment evidence and rollback notes exist.")
    if command_categories.get("database", 0):
        risk_signals.append("database commands were observed; verify migration, RLS, and tenant-isolation evidence exists.")
    if not active_plans or (len(active_plans) == 1 and active_plans.get("unknown")):
        risk_signals.append("no active plan was detected in telemetry; verify Route Plan evidence separately.")

    out = [
        "# Engineering OS telemetry summary",
        "",
        f"Source: `{source}`",
        f"Total events: **{len(events)}**",
        f"Observed duration: **{duration} seconds**",
        "",
        "## Hook events",
        fmt_counter(hooks),
        "## Tools",
        fmt_counter(tools),
        "## Command categories",
        fmt_counter(command_categories),
        "## Active plans",
        fmt_counter(active_plans),
        "## Branches",
        fmt_counter(branches),
        "## Target path extensions",
        fmt_counter(extensions),
        "## Target top-level directories",
        fmt_counter(top_dirs),
        "## Risk signals to review",
    ]
    if risk_signals:
        out.extend(f"- {x}" for x in risk_signals)
    else:
        out.append("- none detected")
    out.append("")
    out.append("## Privacy note")
    out.append("Telemetry records metadata only: hook event name, tool name, command category, hashed command/payload, hashed target path, repo name, branch, short head, and active plan basename. It does not store prompts, file contents, raw commands, raw paths, connector payloads, environment values, or secrets.")
    out.append("")
    return "\n".join(out)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("path", nargs="?", default=".engineering-os/telemetry/events.jsonl")
    parser.add_argument("--output", default="")
    args = parser.parse_args()

    source = Path(args.path)
    events = load_events(source)
    report = summarize(events, source)
    if args.output:
        Path(args.output).write_text(report, encoding="utf-8")
    else:
        print(report)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
