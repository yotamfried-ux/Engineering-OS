#!/usr/bin/env python3
"""Add branch-level CI history counts to an Operational Work History artifact.

Only aggregate metadata is stored. Workflow run ids, URLs, logs, branch names, and
raw payloads are not copied into the artifact.
"""

from __future__ import annotations

import argparse
import json
from collections import Counter
from datetime import datetime
from pathlib import Path
from typing import Any

FAILING = {"failure", "timed_out", "cancelled", "action_required", "startup_failure"}
START = "<!-- EOS_CI_HISTORY_START -->"
END = "<!-- EOS_CI_HISTORY_END -->"


def parse_time(value: str) -> datetime | None:
    value = str(value or "").strip()
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def load_runs(path: Path | None) -> tuple[list[dict[str, Any]], bool]:
    if path is None or not path.is_file():
        return [], True
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return [], True
    if isinstance(data, dict):
        data = data.get("workflow_runs") or data.get("runs") or []
    if not isinstance(data, list):
        return [], True
    return [item for item in data if isinstance(item, dict)], False


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--artifact", required=True, type=Path)
    parser.add_argument("--summary", type=Path)
    parser.add_argument("--ci-history-json", type=Path)
    parser.add_argument("--since", default="")
    args = parser.parse_args()

    record = json.loads(args.artifact.read_text(encoding="utf-8"))
    runs, unavailable = load_runs(args.ci_history_json)
    since = parse_time(args.since)

    filtered: list[dict[str, Any]] = []
    for run in runs:
        created = parse_time(run.get("createdAt") or run.get("created_at") or "")
        if since is not None and created is not None and created < since:
            continue
        filtered.append(run)

    failed_workflows: Counter[str] = Counter()
    completed_count = 0
    failure_count = 0
    head_shas: set[str] = set()

    for run in filtered:
        name = str(run.get("workflowName") or run.get("name") or run.get("workflow") or "unknown")
        status = str(run.get("status") or "").lower()
        conclusion = str(run.get("conclusion") or "").lower()
        head_sha = str(run.get("headSha") or run.get("head_sha") or "")
        if head_sha:
            head_shas.add(head_sha)
        if status == "completed" or conclusion:
            completed_count += 1
        if conclusion in FAILING:
            failure_count += 1
            failed_workflows[name] += 1

    record.update(
        {
            "ci_history_metadata_unavailable": unavailable,
            "ci_history_runs_count": len(filtered),
            "ci_history_completed_runs_count": completed_count,
            "ci_history_failure_count": failure_count,
            "ci_history_failed_workflow_counts": dict(sorted(failed_workflows.items())),
            "ci_history_distinct_head_sha_count": len(head_shas),
            "ci_history_scope": "pull_request branch runs since PR creation",
        }
    )

    friction = record.setdefault("friction_signals", {})
    friction["ci_historical_failures"] = failure_count
    friction["ci_history_metadata_unavailable"] = unavailable
    friction["any"] = bool(friction.get("any")) or failure_count > 0 or unavailable

    args.artifact.write_text(json.dumps(record, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    if args.summary:
        current = args.summary.read_text(encoding="utf-8", errors="replace") if args.summary.exists() else "# Operational Work History Summary\n"
        if START in current and END in current:
            current = current.split(START, 1)[0].rstrip() + "\n"
        section = (
            f"\n{START}\n"
            "## CI history\n\n"
            f"- metadata unavailable: {unavailable}\n"
            f"- branch runs observed: {len(filtered)}\n"
            f"- completed runs: {completed_count}\n"
            f"- historical failing runs: {failure_count}\n"
            f"- distinct head SHAs: {len(head_shas)}\n"
            f"{END}\n"
        )
        args.summary.write_text(current.rstrip() + "\n" + section, encoding="utf-8")

    print(f"enriched work history with {len(filtered)} CI runs and {failure_count} historical failures")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
