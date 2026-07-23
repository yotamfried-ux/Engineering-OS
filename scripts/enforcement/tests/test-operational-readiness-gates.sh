#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
MERGE_CHECK="$ROOT/scripts/enforcement/check-merge-readiness.sh"
JSON_GUARD="$ROOT/scripts/enforcement/pre-tool-use-json-guard.sh"
chmod +x "$MERGE_CHECK" "$JSON_GUARD"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

HEAD_SHA="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
OTHER_SHA="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

expect_pass() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  ✅ $name"
  else
    echo "  ❌ expected $name to pass"
    "$@" || true
    exit 1
  fi
}

expect_fail() {
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "  ❌ expected $name to fail"
    exit 1
  else
    echo "  ✅ $name"
  fi
}

CAPTURE_STATUS=0
capture() {
  local output="$1"; shift
  set +e
  "$@" >"$output" 2>&1
  CAPTURE_STATUS=$?
  set -e
}

python3 - "$TMP" "$HEAD_SHA" "$OTHER_SHA" <<'PY'
import copy
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
head = sys.argv[2]
other = sys.argv[3]
required = [
    "enforcement-tests",
    "pr-policy",
    "connector-evidence-policy",
    "workflow-evidence-policy",
    "capability-evidence-policy",
    "plan-policy",
    "documentation-asset-policy",
    "semantic-cleanup-policy",
    "import-cleanup-policy",
]


def run(name, run_id, timestamp="2026-07-22T10:00:00Z", *, sha=head,
        attempt=1, status="completed", conclusion="success", timestamp_field="run_started_at"):
    item = {
        "id": run_id,
        "name": name,
        "head_sha": sha,
        "run_attempt": attempt,
        "status": status,
        "conclusion": conclusion,
    }
    if timestamp_field:
        item[timestamp_field] = timestamp
    return item


def write(name, runs):
    (root / name).write_text(json.dumps({"workflow_runs": runs}, indent=2) + "\n", encoding="utf-8")


baseline = []
for index, name in enumerate(required, start=1):
    field = "run_started_at"
    if name == "semantic-cleanup-policy":
        field = "updated_at"
    elif name == "import-cleanup-policy":
        field = "created_at"
    baseline.append(run(name, 1000 + index, f"2026-07-22T10:{index:02d}:00Z", timestamp_field=field))

write("runs-good.json", baseline)

pr107 = copy.deepcopy(baseline)
for item in pr107:
    if item["name"] in {"workflow-evidence-policy", "connector-evidence-policy"}:
        item["conclusion"] = "failure"
write("runs-pr107-bad.json", pr107)
write("runs-missing.json", baseline[:2])
write("runs-missing-cleanup.json", [item for item in baseline if item["name"] not in {"semantic-cleanup-policy", "import-cleanup-policy"}])

old_success = run("enforcement-tests", 101, "2026-07-22T10:00:00Z", conclusion="success")
new_failure = run("enforcement-tests", 102, "2026-07-22T11:00:00Z", conclusion="failure")
write("runs-stale-forward.json", [old_success, new_failure])
write("runs-stale-reverse.json", [new_failure, old_success])

old_failure = run("enforcement-tests", 103, "2026-07-22T10:00:00Z", conclusion="failure")
new_success = run("enforcement-tests", 104, "2026-07-22T11:00:00Z", conclusion="success")
write("runs-recovery-forward.json", [old_failure, new_success])
write("runs-recovery-reverse.json", [new_success, old_failure])

write("runs-wrong-head.json", [run("enforcement-tests", 105, sha=other)])
missing_head = run("enforcement-tests", 106)
missing_head.pop("head_sha")
write("runs-missing-head.json", [missing_head])

attempt_one = run("enforcement-tests", 107, attempt=1, conclusion="success")
attempt_two = run("enforcement-tests", 108, attempt=2, conclusion="failure")
write("runs-attempt-two-fails.json", [attempt_two, attempt_one])

pending_latest = run("enforcement-tests", 110, "2026-07-22T11:00:00Z", status="in_progress", conclusion=None)
write("runs-latest-pending.json", [pending_latest, old_success])

lower_id = run("enforcement-tests", 111, attempt=3, conclusion="success")
higher_id = run("enforcement-tests", 112, attempt=3, conclusion="failure")
write("runs-id-tiebreaker.json", [higher_id, lower_id])

missing_timestamp = run("enforcement-tests", 113, timestamp_field=None)
write("runs-missing-timestamp.json", [missing_timestamp])
invalid_timestamp = run("enforcement-tests", 114, timestamp="not-a-timestamp")
write("runs-invalid-timestamp.json", [invalid_timestamp])
missing_attempt = run("enforcement-tests", 115)
missing_attempt.pop("run_attempt")
write("runs-missing-attempt.json", [missing_attempt])
missing_id = run("enforcement-tests", 116)
missing_id.pop("id")
write("runs-missing-id.json", [missing_id])

(root / "runs-non-object.json").write_text('{"workflow_runs":["not-an-object"]}\n', encoding="utf-8")
(root / "runs-missing-name.json").write_text('{"workflow_runs":[{"id":1}]}\n', encoding="utf-8")
(root / "runs-malformed.json").write_text('{"workflow_runs":[', encoding="utf-8")
PY

common=(--expected-head-sha "$HEAD_SHA")

expect_pass "merge readiness accepts all-success exact-head required workflows" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-good.json" "${common[@]}"
expect_fail "merge readiness blocks PR107-style failed evidence workflows" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-pr107-bad.json" "${common[@]}"
expect_fail "merge readiness blocks missing required workflows" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-missing.json" "${common[@]}"
expect_fail "merge readiness blocks missing cleanup policy workflows" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-missing-cleanup.json" "${common[@]}"

expect_fail "old success plus newer failure fails" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-stale-forward.json" "${common[@]}" --required "enforcement-tests"
expect_pass "old failure plus newer success passes" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-recovery-forward.json" "${common[@]}" --required "enforcement-tests"
expect_fail "success on another head cannot satisfy expected head" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-wrong-head.json" "${common[@]}" --required "enforcement-tests"
expect_fail "required workflow entry missing head metadata fails closed" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-missing-head.json" "${common[@]}" --required "enforcement-tests"
expect_fail "attempt 2 failure supersedes attempt 1 success" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-attempt-two-fails.json" "${common[@]}" --required "enforcement-tests"
expect_fail "latest pending run blocks merge readiness" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-latest-pending.json" "${common[@]}" --required "enforcement-tests"
expect_fail "higher run id breaks timestamp and attempt ties" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-id-tiebreaker.json" "${common[@]}" --required "enforcement-tests"

expect_fail "missing timestamp metadata fails closed" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-missing-timestamp.json" "${common[@]}" --required "enforcement-tests"
expect_fail "invalid timestamp metadata fails closed" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-invalid-timestamp.json" "${common[@]}" --required "enforcement-tests"
expect_fail "missing run_attempt metadata fails closed" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-missing-attempt.json" "${common[@]}" --required "enforcement-tests"
expect_fail "missing run id metadata fails closed" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-missing-id.json" "${common[@]}" --required "enforcement-tests"
expect_fail "non-object workflow entries fail closed" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-non-object.json" "${common[@]}" --required "enforcement-tests"
expect_fail "missing workflow names fail closed" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-missing-name.json" "${common[@]}" --required "enforcement-tests"
expect_fail "malformed JSON fails closed" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-malformed.json" "${common[@]}" --required "enforcement-tests"
expect_fail "missing expected head argument fails closed" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-good.json"
expect_fail "uppercase expected head is rejected" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-good.json" --expected-head-sha "${HEAD_SHA^^}"
expect_fail "short expected head is rejected" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-good.json" --expected-head-sha "${HEAD_SHA:0:12}"

capture "$TMP/recovery-forward.out" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-recovery-forward.json" "${common[@]}" --required "enforcement-tests enforcement-tests"
[ "$CAPTURE_STATUS" -eq 0 ] || { echo "  ❌ expected forward recovery capture to pass"; exit 1; }
capture "$TMP/recovery-reverse.out" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-recovery-reverse.json" "${common[@]}" --required "enforcement-tests"
[ "$CAPTURE_STATUS" -eq 0 ] || { echo "  ❌ expected reverse recovery capture to pass"; exit 1; }
cmp -s "$TMP/recovery-forward.out" "$TMP/recovery-reverse.out" || {
  echo "  ❌ pass diagnostics changed with input order or duplicate required names"
  diff -u "$TMP/recovery-forward.out" "$TMP/recovery-reverse.out" || true
  exit 1
}
echo "  ✅ pass selection and output are deterministic"

capture "$TMP/stale-forward.out" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-stale-forward.json" "${common[@]}" --required "enforcement-tests"
[ "$CAPTURE_STATUS" -eq 1 ] || { echo "  ❌ expected forward stale capture to fail with policy status 1"; exit 1; }
capture "$TMP/stale-reverse.out" \
  "$MERGE_CHECK" --runs-json "$TMP/runs-stale-reverse.json" "${common[@]}" --required "enforcement-tests"
[ "$CAPTURE_STATUS" -eq 1 ] || { echo "  ❌ expected reverse stale capture to fail with policy status 1"; exit 1; }
cmp -s "$TMP/stale-forward.out" "$TMP/stale-reverse.out" || {
  echo "  ❌ failure diagnostics changed with input order"
  diff -u "$TMP/stale-forward.out" "$TMP/stale-reverse.out" || true
  exit 1
}
echo "  ✅ failure selection and output are deterministic"

run_guard_raw() { printf '%s' "$1" | "$JSON_GUARD"; }
expect_fail "JSON guard blocks malformed PreToolUse JSON" run_guard_raw '{"tool_name":"Write","tool_input":'
expect_fail "JSON guard blocks Write without file_path" run_guard_raw '{"tool_name":"Write","tool_input":{}}'
expect_fail "JSON guard blocks Bash without command" run_guard_raw '{"tool_name":"Bash","tool_input":{}}'
expect_pass "JSON guard allows Agent with valid event" run_guard_raw '{"tool_name":"Agent","tool_input":{}}'
expect_pass "JSON guard allows Write with file_path" run_guard_raw '{"tool_name":"Write","tool_input":{"file_path":"src/app.ts"}}'
expect_pass "JSON guard allows Bash with command" run_guard_raw '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}'

echo "operational readiness gate tests passed"
