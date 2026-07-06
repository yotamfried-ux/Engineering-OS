#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    rows: list[dict[str, Any]] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception as exc:
            raise ValueError(f"invalid JSONL at {path}:{line_number}: {exc}") from exc
        if isinstance(row, dict):
            rows.append(row)
    return rows


def event_attrs(event: dict[str, Any]) -> dict[str, Any]:
    attrs = event.get("attributes")
    return attrs if isinstance(attrs, dict) else {}


def load_events_for_run(index_row: dict[str, Any]) -> list[dict[str, Any]]:
    archive_path = Path(str(index_row.get("archive_path") or ""))
    events_path = archive_path / "events.jsonl"
    return load_jsonl(events_path)


def coverage_counts(events: list[dict[str, Any]]) -> dict[str, int]:
    return {
        "missing_session": sum(1 for e in events if not event_attrs(e).get("eos.claude.session.present")),
        "missing_turn": sum(
            1
            for e in events
            if not (
                event_attrs(e).get("eos.claude.turn.present")
                or event_attrs(e).get("eos.claude.prompt.present")
            )
        ),
        "missing_transcript": sum(1 for e in events if not event_attrs(e).get("eos.claude.transcript.present")),
        "missing_cwd": sum(1 for e in events if not event_attrs(e).get("eos.claude.cwd.present")),
    }


def command_categories(events: list[dict[str, Any]]) -> Counter[str]:
    counter: Counter[str] = Counter()
    for event in events:
        category = str(event_attrs(event).get("eos.tool.command.category") or "none")
        counter[category] += 1
    return counter


def render_counter(counter: Counter[str]) -> str:
    if not counter:
        return "none observed"
    return ", ".join(f"`{key}`={value}" for key, value in counter.most_common())


def build_report(index_rows: list[dict[str, Any]], project: str | None = None) -> str:
    if project:
        index_rows = [r for r in index_rows if str(r.get("project_slug")) == project or str(r.get("project")) == project]

    lines = [
        "# Telemetry Archive Analysis",
        "",
        f"Runs analyzed: {len(index_rows)}",
    ]
    if project:
        lines.append(f"Project filter: `{project}`")
    lines.append("")

    if not index_rows:
        lines.extend(["No imported runs found.", ""])
        return "\n".join(lines).rstrip() + "\n"

    rows_with_events: list[tuple[dict[str, Any], list[dict[str, Any]], dict[str, int], Counter[str]]] = []
    for row in index_rows:
        events = load_events_for_run(row)
        rows_with_events.append((row, events, coverage_counts(events), command_categories(events)))

    lines.extend(["## Run comparison", "", "| Run date | Project | Run id | Events | Missing session | Missing turn | Missing transcript | Missing cwd | Command categories |", "|---|---|---|---:|---:|---:|---:|---:|---|"])
    for row, events, coverage, categories in rows_with_events:
        lines.append(
            "| {date} | {project} | `{run_id}` | {events} | {session} | {turn} | {transcript} | {cwd} | {categories} |".format(
                date=row.get("run_date", "unknown"),
                project=row.get("project_slug") or row.get("project") or "unknown",
                run_id=row.get("run_id", "unknown"),
                events=len(events),
                session=coverage["missing_session"],
                turn=coverage["missing_turn"],
                transcript=coverage["missing_transcript"],
                cwd=coverage["missing_cwd"],
                categories=render_counter(categories),
            )
        )
    lines.append("")

    by_project: dict[str, list[tuple[dict[str, Any], list[dict[str, Any]], dict[str, int], Counter[str]]]] = defaultdict(list)
    for item in rows_with_events:
        by_project[str(item[0].get("project_slug") or item[0].get("project") or "unknown")].append(item)

    lines.extend(["## Project-level summary", ""])
    for project_slug, items in sorted(by_project.items()):
        event_counts = [len(events) for _row, events, _coverage, _categories in items]
        aggregate_categories: Counter[str] = Counter()
        aggregate_missing: Counter[str] = Counter()
        for _row, _events, coverage, categories in items:
            aggregate_categories.update(categories)
            aggregate_missing.update(coverage)
        lines.append(f"### {project_slug}")
        lines.append("")
        lines.append(f"- runs: {len(items)}")
        lines.append(f"- min events: {min(event_counts)}")
        lines.append(f"- max events: {max(event_counts)}")
        lines.append(f"- total events: {sum(event_counts)}")
        lines.append(f"- aggregate command categories: {render_counter(aggregate_categories)}")
        lines.append(f"- aggregate missing coverage: {dict(aggregate_missing)}")
        if len(items) < 2:
            lines.append("- longitudinal comparison: pending at least one later run")
        else:
            first_count, last_count = event_counts[0], event_counts[-1]
            delta = last_count - first_count
            lines.append(f"- event count delta first-to-last: {delta:+d}")
        lines.append("")

    recurring: Counter[str] = Counter()
    for _row, _events, coverage, _categories in rows_with_events:
        for key, value in coverage.items():
            if value > 0:
                recurring[key] += 1

    lines.extend(["## Recurring missing coverage", ""])
    recurring_found = False
    for key, run_count in recurring.most_common():
        if run_count >= 2:
            recurring_found = True
            lines.append(f"- `{key}` appeared in {run_count} runs")
    if not recurring_found:
        lines.append("- none yet; at least two affected runs are required before calling a pattern recurring")
    lines.append("")

    lines.extend(["## Readiness note", "", "This report supports investigation only. Monitoring sufficiency requires Project 8 evidence plus at least one later target-project comparison run.", ""])
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Analyze imported Engineering OS telemetry archive runs.")
    parser.add_argument("archive", type=Path, nargs="?", default=Path("telemetry-archive"))
    parser.add_argument("--project", help="Project name or slug to analyze")
    parser.add_argument("--output", type=Path, help="Write report to this markdown file")
    args = parser.parse_args()

    index_path = args.archive / "indexes" / "runs.jsonl"
    try:
        rows = load_jsonl(index_path)
        report = build_report(rows, args.project)
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(report, encoding="utf-8")
    else:
        print(report, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
