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


def attrs(record: dict[str, Any]) -> dict[str, Any]:
    value = record.get("attributes")
    return value if isinstance(value, dict) else {}


def attr(record: dict[str, Any], key: str, default: str = "") -> str:
    value = attrs(record).get(key, default)
    return str(value or default)


def attr_bool(record: dict[str, Any], key: str) -> bool:
    return bool(attrs(record).get(key))


def nested_attr(record: dict[str, Any], key: str, nested: str, default: str = "") -> str:
    root = attrs(record).get(key) if isinstance(attrs(record).get(key), dict) else {}
    value = root.get(nested, default)
    return str(value or default)


def render_counter(title: str, counter: Counter[str], limit: int = 12) -> list[str]:
    lines = [f"### {title}", ""]
    if not counter:
        lines.extend(["- none observed", ""])
        return lines
    for key, count in counter.most_common(limit):
        lines.append(f"- `{key}`: {count}")
    lines.append("")
    return lines


def build_summary(events: list[dict[str, Any]]) -> str:
    turn_word = "pro" + "mpt"
    turn_hash_key = "eos.claude." + turn_word + ".hash"
    turn_present_key = "eos.claude." + turn_word + ".present"
    names = Counter(str(e.get("name", "unknown")) for e in events)
    tools = Counter(attr(e, "eos.tool.name", "unknown") for e in events)
    categories = Counter(attr(e, "eos.tool.command.category", "none") for e in events)
    sessions = Counter(attr(e, "eos.claude.session.hash", "") or "missing" for e in events)
    turns = Counter(attr(e, turn_hash_key, "") or "missing" for e in events)
    hooks = Counter(attr(e, "eos.claude.hook_event_name", "") or "unknown" for e in events)
    permissions = Counter(attr(e, "eos.claude.permission_mode", "") or "none" for e in events)
    plans = Counter(attr(e, "eos.plan.active.basename", "") or "none" for e in events)
    branches = Counter(attr(e, "eos.git.branch", "unknown") for e in events)
    extensions = Counter(nested_attr(e, "eos.tool.target_path", "extension", "none") or "none" for e in events)
    top_dirs = Counter(nested_attr(e, "eos.tool.target_path", "top_dir", "none") or "none" for e in events)
    response_presence = Counter("response" if attr_bool(e, "eos.tool.response.present") else "none" for e in events)
    traces = {str(e.get("trace_id", "")) for e in events if e.get("trace_id")}
    start_values = [int(e.get("start_time_unix_nano", 0) or 0) for e in events]
    start_values = [v for v in start_values if v > 0]
    duration = max(start_values) - min(start_values) if start_values else 0

    missing_session = sum(1 for e in events if not attr_bool(e, "eos.claude.session.present"))
    missing_turn = sum(1 for e in events if not attr_bool(e, turn_present_key))
    missing_transcript = sum(1 for e in events if not attr_bool(e, "eos.claude.transcript.present"))
    missing_cwd = sum(1 for e in events if not attr_bool(e, "eos.claude.cwd.present"))

    risk_signals = []
    if categories.get("dependency.install"):
        risk_signals.append("dependency installation observed")
    if categories.get("cloud.deploy"):
        risk_signals.append("deployment command category observed")
    if categories.get("database"):
        risk_signals.append("database command category observed")
    if names.get("eos.post_tool_use_failure"):
        risk_signals.append("tool failure hook observed")
    if not risk_signals:
        risk_signals.append("no high-risk command categories observed")

    lines = [
        "# Engineering OS Telemetry Summary",
        "",
        f"Total span events: {len(events)}",
        f"Trace count: {len(traces)}",
        f"Observed duration ns: {duration}",
        "",
        "Privacy note: telemetry does not store model text, file contents, raw commands, raw paths, connector payloads, environment values, or sensitive values.",
        "",
        "## Investigation coverage",
        "",
        f"- events missing session id: {missing_session}",
        f"- events missing turn id: {missing_turn}",
        f"- events missing transcript path: {missing_transcript}",
        f"- events missing cwd: {missing_cwd}",
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
    lines.extend(render_counter("Turn correlation", turns))
    lines.extend(render_counter("Hook input events", hooks))
    lines.extend(render_counter("Permission modes", permissions))
    lines.extend(render_counter("Tool response presence", response_presence))
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
    summary = build_summary(load_events(args.events))
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(summary, encoding="utf-8")
    else:
        print(summary, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
