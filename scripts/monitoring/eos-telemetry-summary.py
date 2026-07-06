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


def nested_attr(record: dict[str, Any], key: str, nested: str, default: str = "") -> str:
    attrs = record.get("attributes") if isinstance(record.get("attributes"), dict) else {}
    root = attrs.get(key) if isinstance(attrs.get(key), dict) else {}
    value = root.get(nested, default)
    return str(value or default)


def render_counter(title: str, counter: Counter[str], limit: int = 12) -> list[str]:
    lines = [f"### {title}", ""]
    if not counter:
        lines.append("- none observed")
        lines.append("")
        return lines
    for key, count in counter.most_common(limit):
        lines.append(f"- `{key}`: {count}")
    lines.append("")
    return lines


def build_summary(events: list[dict[str, Any]]) -> str:
    names = Counter(str(e.get("name", "unknown")) for e in events)
    tools = Counter(attr(e, "eos.tool.name", "unknown") for e in events)
    categories = Counter(attr(e, "eos.tool.command.category", "none") for e in events)
    sessions = Counter(attr(e, "eos.claude.session.hash", "") or "missing" for e in events)
    plans = Counter(attr(e, "eos.plan.active.basename", "") or "none" for e in events)
    branches = Counter(attr(e, "eos.git.branch", "unknown") for e in events)
    extensions = Counter(nested_attr(e, "eos.tool.target_path", "extension", "none") or "none" for e in events)
    top_dirs = Counter(nested_attr(e, "eos.tool.target_path", "top_dir", "none") or "none" for e in events)
    traces = {str(e.get("trace_id", "")) for e in events if e.get("trace_id")}
    start_values = [int(e.get("start_time_unix_nano", 0) or 0) for e in events]
    start_values = [v for v in start_values if v > 0]
    duration = 0
    if start_values:
        duration = max(start_values) - min(start_values)
    risk_signals = []
    if categories.get("dependency.install"):
        risk_signals.append("dependency installation observed")
    if categories.get("cloud.deploy"):
        risk_signals.append("deployment command category observed")
    if categories.get("database"):
        risk_signals.append("database command category observed")
    if not risk_signals:
        risk_signals.append("no high-risk command categories observed")

    lines = [
        "# Engineering OS Telemetry Summary",
        "",
        f"Total span events: {len(events)}",
        f"Trace count: {len(traces)}",
        f"Observed duration ns: {duration}",
        "",
        "Privacy note: telemetry does not store prompts, model responses, file contents, raw commands, raw paths, connector payloads, environment values, or sensitive values.",
        "",
        "## Risk signals",
        "",
    ]
    lines.extend(f"- {signal}" for signal in risk_signals)
    lines.append("")
    lines.extend(render_counter("Span/event names", names))
    lines.extend(render_counter("Tools", tools))
    lines.extend(render_counter("Command categories", categories))
    lines.extend(render_counter("Session correlation", sessions))
    lines.extend(render_counter("Active plans", plans))
    lines.extend(render_counter("Branches", branches))
    lines.extend(render_counter("Target path extensions", extensions))
    lines.extend(render_counter("Target top directories", top_dirs))
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("events", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    events = load_events(args.events)
    summary = build_summary(events)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(summary, encoding="utf-8")
    else:
        print(summary, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
