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


def attr(event: dict[str, Any], key: str, default: str = "unknown") -> str:
    attrs = event.get("attributes") if isinstance(event.get("attributes"), dict) else {}
    value = attrs.get(key) if isinstance(attrs, dict) else None
    return str(value or default)


def count_by(events: list[dict[str, Any]], getter) -> collections.Counter[str]:
    c: collections.Counter[str] = collections.Counter()
    for event in events:
        c[str(getter(event) or "unknown")] += 1
    return c


def nested_attr_count(events: list[dict[str, Any]], key: str, child: str) -> collections.Counter[str]:
    c: collections.Counter[str] = collections.Counter()
    for event in events:
        attrs = event.get("attributes") if isinstance(event.get("attributes"), dict) else {}
        obj = attrs.get(key) if isinstance(attrs, dict) and isinstance(attrs.get(key), dict) else {}
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

    starts = [int(e.get("start_time_unix_nano", 0) or 0) for e in events if e.get("start_time_unix_nano")]
    ends = [int(e.get("end_time_unix_nano", 0) or 0) for e in events if e.get("end_time_unix_nano")]
    duration_seconds = 0
    if starts and ends:
        duration_seconds = max(0, int((max(ends) - min(starts)) / 1_000_000_000))

    traces = count_by(events, lambda e: e.get("trace_id") or "unknown")
    spans = count_by(events, lambda e: e.get("name") or "unknown")
    tools = count_by(events, lambda e: attr(e, "eos.tool.name"))
    command_categories = count_by(events, lambda e: attr(e, "eos.tool.command.category"))
    branches = count_by(events, lambda e: attr(e, "eos.git.branch"))
    active_plans = count_by(events, lambda e: attr(e, "eos.plan.active.basename"))
    extensions = nested_attr_count(events, "eos.tool.target_path", "extension")
    top_dirs = nested_attr_count(events, "eos.tool.target_path", "top_dir")

    risk_signals = []
    if command_categories.get("dependency.install", 0):
        risk_signals.append("dependency install commands were observed; verify Context7/source-of-truth evidence exists.")
    if command_categories.get("cloud.deploy", 0):
        risk_signals.append("cloud/deploy commands were observed; verify deployment evidence and rollback notes exist.")
    if command_categories.get("database", 0):
        risk_signals.append("database commands were observed; verify migration, RLS, and tenant-isolation evidence exists.")
    if not active_plans or active_plans.get("unknown") == sum(active_plans.values()):
        risk_signals.append("no active plan was detected in telemetry; verify Route Plan evidence separately.")

    out = [
        "# Engineering OS telemetry summary",
        "",
        f"Source: `{source}`",
        f"Total span events: **{len(events)}**",
        f"Trace count: **{len(traces)}**",
        f"Observed duration: **{duration_seconds} seconds**",
        "",
        "## Span names",
        fmt_counter(spans),
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
    out.append("Telemetry records OpenTelemetry-style metadata only: trace/span IDs, span name, timestamps, resource attributes, tool name, command category, hashed command/payload, hashed target path, repo name, branch, short head, and active plan basename. It does not store prompts, file contents, raw commands, raw paths, connector payloads, environment values, or secrets.")
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
