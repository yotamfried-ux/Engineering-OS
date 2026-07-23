#!/usr/bin/env bash
# check-merge-readiness.sh — deterministic pre-merge policy gate.
#
# Evaluates GitHub workflow-run summaries for one exact PR head and fails closed
# unless the deterministically latest attempt of every required workflow is a
# terminal success. Human approval remains a separate merge requirement.

set -euo pipefail

REQUIRED_WORKFLOWS_DEFAULT="enforcement-tests pr-policy connector-evidence-policy workflow-evidence-policy capability-evidence-policy plan-policy documentation-asset-policy semantic-cleanup-policy import-cleanup-policy"
REQUIRED_WORKFLOWS="${EOS_REQUIRED_WORKFLOWS:-$REQUIRED_WORKFLOWS_DEFAULT}"
RUNS_JSON=""
EXPECTED_HEAD_SHA=""

usage() {
  cat <<'USAGE'
Usage:
  check-merge-readiness.sh \
    --runs-json <file> \
    --expected-head-sha <40-char-lowercase-sha> \
    [--required "workflow-a workflow-b"]

Input JSON may be either:
  - an array of GitHub workflow-run objects, or
  - an object with a workflow_runs array.

Required-workflow objects must carry:
  name, head_sha, status, conclusion, run_attempt, id, and at least one of
  run_started_at / updated_at / created_at.

Selection is independent of input order. For each required workflow, the latest
exact-head run is selected by timestamp (run_started_at, else updated_at, else
created_at), then run_attempt, then run id.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --runs-json)
      [ "$#" -ge 2 ] || { echo "ERROR_FOR_AGENT: --runs-json requires a value." >&2; exit 2; }
      RUNS_JSON="$2"
      shift 2
      ;;
    --expected-head-sha)
      [ "$#" -ge 2 ] || { echo "ERROR_FOR_AGENT: --expected-head-sha requires a value." >&2; exit 2; }
      EXPECTED_HEAD_SHA="$2"
      shift 2
      ;;
    --required)
      [ "$#" -ge 2 ] || { echo "ERROR_FOR_AGENT: --required requires a value." >&2; exit 2; }
      REQUIRED_WORKFLOWS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR_FOR_AGENT: unknown argument '$1'" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ -z "$RUNS_JSON" ]; then
  echo "ERROR_FOR_AGENT: merge readiness requires --runs-json evidence." >&2
  echo "ACTION: fetch workflow runs for the PR head SHA and pass the JSON to this checker before merge." >&2
  exit 2
fi

if [ -z "$EXPECTED_HEAD_SHA" ]; then
  echo "ERROR_FOR_AGENT: merge readiness requires --expected-head-sha." >&2
  echo "ACTION: resolve the live PR head SHA and pass the full lowercase 40-character value." >&2
  exit 2
fi

if [[ ! "$EXPECTED_HEAD_SHA" =~ ^[0-9a-f]{40}$ ]]; then
  echo "ERROR_FOR_AGENT: --expected-head-sha must be a full lowercase 40-character commit SHA." >&2
  exit 2
fi

if [ ! -f "$RUNS_JSON" ]; then
  echo "ERROR_FOR_AGENT: workflow-runs JSON file not found: $RUNS_JSON" >&2
  exit 2
fi

python3 - "$RUNS_JSON" "$REQUIRED_WORKFLOWS" "$EXPECTED_HEAD_SHA" <<'PY'
from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

path = Path(sys.argv[1])
expected_head = sys.argv[3]

# Preserve the canonical configured order while preventing duplicate diagnostics.
required: list[str] = []
seen_required: set[str] = set()
for item in sys.argv[2].split():
    name = item.strip()
    if name and name not in seen_required:
        required.append(name)
        seen_required.add(name)

if not required:
    print("ERROR_FOR_AGENT: required workflow set is empty.", file=sys.stderr)
    sys.exit(2)

try:
    raw = json.loads(path.read_text(encoding="utf-8"))
except Exception as exc:
    print(f"ERROR_FOR_AGENT: invalid workflow-runs JSON: {exc}", file=sys.stderr)
    sys.exit(2)

if isinstance(raw, dict):
    runs = raw.get("workflow_runs")
elif isinstance(raw, list):
    runs = raw
else:
    runs = None

if not isinstance(runs, list):
    print("ERROR_FOR_AGENT: workflow-runs JSON must be an array or an object with a workflow_runs list.", file=sys.stderr)
    sys.exit(2)

sha_re = re.compile(r"^[0-9a-f]{40}$")
required_set = set(required)
candidates: dict[str, list[tuple[tuple[datetime, int, int], dict[str, Any], str, str]]] = {
    name: [] for name in required
}
record_errors: dict[str, set[str]] = {name: set() for name in required}
other_head_counts: dict[str, int] = {name: 0 for name in required}
non_object_count = 0
missing_name_count = 0


def display(value: Any) -> str:
    if value is None or value == "":
        return "missing"
    return str(value)


def positive_int(value: Any) -> int | None:
    if isinstance(value, bool) or not isinstance(value, int) or value < 1:
        return None
    return value


def select_timestamp(run: dict[str, Any]) -> tuple[str, str] | None:
    for field in ("run_started_at", "updated_at", "created_at"):
        value = run.get(field)
        if isinstance(value, str) and value.strip():
            return field, value.strip()
    return None


def parse_timestamp(value: str) -> datetime | None:
    normalized = value[:-1] + "+00:00" if value.endswith("Z") else value
    try:
        parsed = datetime.fromisoformat(normalized)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        return None
    return parsed.astimezone(timezone.utc)


for run in runs:
    if not isinstance(run, dict):
        non_object_count += 1
        continue

    raw_name = run.get("name")
    if not isinstance(raw_name, str) or not raw_name.strip():
        missing_name_count += 1
        continue
    name = raw_name.strip()
    if name not in required_set:
        continue

    head = run.get("head_sha")
    if not isinstance(head, str) or not sha_re.fullmatch(head):
        record_errors[name].add("required-workflow entry has invalid or missing head_sha")
        continue
    if head != expected_head:
        other_head_counts[name] += 1
        continue

    run_id = positive_int(run.get("id"))
    attempt = positive_int(run.get("run_attempt"))
    timestamp = select_timestamp(run)
    timestamp_field = timestamp[0] if timestamp else "missing"
    timestamp_raw = timestamp[1] if timestamp else "missing"
    parsed_timestamp = parse_timestamp(timestamp_raw) if timestamp else None

    invalid: list[str] = []
    if run_id is None:
        invalid.append("id must be a positive integer")
    if attempt is None:
        invalid.append("run_attempt must be a positive integer")
    if timestamp is None:
        invalid.append("run_started_at/updated_at/created_at is missing")
    elif parsed_timestamp is None:
        invalid.append(f"{timestamp_field} is not a timezone-aware ISO-8601 timestamp")

    if invalid:
        record_errors[name].add(
            f"exact-head run id={display(run.get('id'))}: " + "; ".join(invalid)
        )
        continue

    assert run_id is not None and attempt is not None and parsed_timestamp is not None
    key = (parsed_timestamp, attempt, run_id)
    candidates[name].append((key, run, timestamp_field, timestamp_raw))

input_errors: list[str] = []
if non_object_count:
    input_errors.append(f"workflow_runs contains {non_object_count} non-object entr{'y' if non_object_count == 1 else 'ies'}")
if missing_name_count:
    input_errors.append(f"workflow_runs contains {missing_name_count} object entr{'y' if missing_name_count == 1 else 'ies'} with invalid or missing name")

if input_errors:
    print("ERROR_FOR_AGENT: workflow-runs evidence is malformed.", file=sys.stderr)
    for item in sorted(input_errors):
        print(f"- {item}", file=sys.stderr)
    sys.exit(2)

bad: list[str] = []
selected: list[tuple[str, dict[str, Any], str, str]] = []
for name in required:
    if record_errors[name]:
        for error in sorted(record_errors[name]):
            bad.append(f"{name}: {error}")
        continue

    exact_head = candidates[name]
    if not exact_head:
        other = other_head_counts[name]
        suffix = f"; saw {other} run(s) on other heads" if other else ""
        bad.append(f"{name}: no valid run for expected head {expected_head}{suffix}")
        continue

    _, run, timestamp_field, timestamp_raw = max(exact_head, key=lambda item: item[0])
    selected.append((name, run, timestamp_field, timestamp_raw))
    status = str(run.get("status") or "").strip().lower()
    conclusion = str(run.get("conclusion") or "").strip().lower()
    if status != "completed" or conclusion != "success":
        bad.append(
            f"{name}: latest exact-head run id={run['id']} attempt={run['run_attempt']} "
            f"timestamp_source={timestamp_field} timestamp={timestamp_raw} "
            f"status={status or 'missing'} conclusion={conclusion or 'missing'}"
        )

if bad:
    print("ERROR_FOR_AGENT: merge readiness failed — latest exact-head required workflows are not all terminal successes.", file=sys.stderr)
    for item in bad:
        print(f"- {item}", file=sys.stderr)
    print("ACTION: do not merge. Fix or rerun the selected latest attempts, fetch fresh exact-head evidence, then check again.", file=sys.stderr)
    sys.exit(1)

print("✅ merge readiness passed: latest exact-head attempts are terminal successes for all required workflows.")
for name, run, timestamp_field, timestamp_raw in selected:
    print(
        f"- {name}: id={run['id']} attempt={run['run_attempt']} head={run['head_sha']} "
        f"timestamp_source={timestamp_field} timestamp={timestamp_raw} status=completed conclusion=success"
    )
PY
