#!/usr/bin/env bash
# check-merge-readiness.sh — deterministic pre-merge policy gate.
#
# This script evaluates GitHub workflow-run summaries for a PR/head SHA and fails
# closed unless every required Engineering OS policy workflow completed with
# conclusion=success. It is intentionally data-driven so it can be tested with
# fixtures and used by agents before calling a merge API.

set -euo pipefail

REQUIRED_WORKFLOWS_DEFAULT="enforcement-tests pr-policy connector-evidence-policy workflow-evidence-policy capability-evidence-policy plan-policy documentation-asset-policy"
REQUIRED_WORKFLOWS="${EOS_REQUIRED_WORKFLOWS:-$REQUIRED_WORKFLOWS_DEFAULT}"
RUNS_JSON=""

usage() {
  cat <<'USAGE'
Usage:
  check-merge-readiness.sh --runs-json <file> [--required "workflow-a workflow-b"]

Input JSON may be either:
  - an array of workflow run objects, or
  - an object with a workflow_runs array.

Each run object must include at least: name, status, conclusion.
The first occurrence for each workflow name is treated as the current/latest run.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --runs-json)
      shift
      RUNS_JSON="${1:-}"
      ;;
    --required)
      shift
      REQUIRED_WORKFLOWS="${1:-}"
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
  shift
done

if [ -z "$RUNS_JSON" ]; then
  echo "ERROR_FOR_AGENT: merge readiness requires --runs-json evidence." >&2
  echo "ACTION: fetch workflow runs for the PR head SHA and pass the JSON to this checker before merge." >&2
  exit 2
fi

if [ ! -f "$RUNS_JSON" ]; then
  echo "ERROR_FOR_AGENT: workflow-runs JSON file not found: $RUNS_JSON" >&2
  exit 2
fi

python3 - "$RUNS_JSON" "$REQUIRED_WORKFLOWS" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
required = [x for x in sys.argv[2].split() if x]

try:
    raw = json.loads(path.read_text(encoding="utf-8"))
except Exception as exc:
    print(f"ERROR_FOR_AGENT: invalid workflow-runs JSON: {exc}", file=sys.stderr)
    sys.exit(2)

if isinstance(raw, dict):
    runs = raw.get("workflow_runs", [])
elif isinstance(raw, list):
    runs = raw
else:
    print("ERROR_FOR_AGENT: workflow-runs JSON must be an array or object with workflow_runs.", file=sys.stderr)
    sys.exit(2)

if not isinstance(runs, list):
    print("ERROR_FOR_AGENT: workflow_runs must be a list.", file=sys.stderr)
    sys.exit(2)

latest_by_name = {}
for run in runs:
    if not isinstance(run, dict):
        continue
    name = str(run.get("name", "")).strip()
    if not name or name in latest_by_name:
        continue
    latest_by_name[name] = run

bad = []
for name in required:
    run = latest_by_name.get(name)
    if run is None:
        bad.append(f"{name}: missing")
        continue
    status = str(run.get("status", "")).strip().lower()
    conclusion = str(run.get("conclusion", "")).strip().lower()
    if status != "completed" or conclusion != "success":
        bad.append(f"{name}: status={status or 'missing'} conclusion={conclusion or 'missing'}")

if bad:
    print("ERROR_FOR_AGENT: merge readiness failed — required workflows are not all green.", file=sys.stderr)
    for item in bad:
        print(f"- {item}", file=sys.stderr)
    print("ACTION: do not merge. Fix failing/missing workflows, rerun, then check again.", file=sys.stderr)
    sys.exit(1)

print("✅ merge readiness passed: all required workflows completed successfully.")
PY
