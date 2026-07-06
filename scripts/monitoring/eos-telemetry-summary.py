#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path
from typing import Any


def load_events(path: Path) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    if not path.exists():
        return events
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            record = json.loads(line)
        except Exception:
            continue
        if isinstance(record, dict):
            events.append(record)
    return events


def attr(record: dict[str, Any], key: str, default: str = "") -> str:
    attrs = record.get("attributes") if isinstance(record.get("attributes"), dict) else {}
    value = attrs.get(key, default)
    return str(value or default)


def build_summary(events: list[dict[str, Any]]) -> str:
    names = Counter(str(e.get("name", "unknown")) for e in events)
    tools = Counter(attr(e, "eos.tool.name", "unknown") for e in events)
    categories = Counter(attr(e, "eos.tool.command.category", "none") for e in events)
    sessions = Counter(attr(e, "eos.claude.session.hash", "") or "missing" for e in events)
    lines = ["# Engineering OS Telemetry Summary", "", f"Total span events: {len(events)}", "", "## Risk signals", ""]
    if categories.get("dependency.install"):
        lines.append("- dependency installation observed")
    if categories.get("cloud.deploy"):
        lines.append("- deployment command category observed")
    if categories.get("database"):
        lines.append("- database command category observed")
    if len(lines) == 6:
        lines.append("- no high-risk command categories observed")
    lines.extend(["", "### Span/event names", ""])
    lines.extend(f"- `{k}`: {v}" for k, v in names.most_common(12))
    lines.extend(["", "### Tools", ""])
    lines.extend(f"- `{k}`: {v}" for k, v in tools.most_common(12))
    lines.extend(["", "### Command categories", ""])
    lines.extend(f"- `{k}`: {v}" for k, v in categories.most_common(12))
    lines.extend(["", "### Session correlation", ""])
    lines.extend(f"- `{k}`: {v}" for k, v in sessions.most_common(12))
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("events", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    summary = build_summary(load_events(args.events))
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(summary, encoding="utf-8")
    else:
        print(summary, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
