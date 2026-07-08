#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
COLLECTOR="$ROOT/scripts/monitoring/collect-pr-work-history.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() { local n="$1"; shift; "$@" >/dev/null 2>&1 || { echo "fail: $n"; "$@"; exit 1; }; echo "ok: $n"; }
reject() { local n="$1"; shift; if "$@" >/dev/null 2>&1; then echo "unexpected pass: $n"; exit 1; fi; echo "ok: $n"; }

pass compiles python3 -m py_compile "$COLLECTOR"

# Build a small real git repo so changed_files/commit_list have real base/head SHAs
# and pr_head_sha/checked_out_sha/base_sha are genuinely distinct fields.
REPO="$TMP/repo"
mkdir -p "$REPO"
(
  cd "$REPO"
  git init -q
  git config user.email work-history@example.invalid
  git config user.name work-history-test
  echo "one" > a.txt
  git add a.txt
  git commit -qm "base commit"
)
BASE_SHA="$(cd "$REPO" && git rev-parse HEAD)"
(
  cd "$REPO"
  echo "two" > b.txt
  git add b.txt
  git commit -qm "add feature"
  echo "three" > c.txt
  git add c.txt
  git commit -qm "fix flaky retry in feature"
)
HEAD_SHA="$(cd "$REPO" && git rev-parse HEAD)"

# 1. Basic generation: distinct pr_head_sha/checked_out_sha/base_sha, real counts,
# but no raw changed-file paths or raw commit subjects in the artifact.
OUT1="$TMP/out1"
python3 "$COLLECTOR" --root "$REPO" --pr-head-sha "$HEAD_SHA" --base-sha "$BASE_SHA" --pr-number 42 --out "$OUT1" >/dev/null
pass artifact_written test -f "$OUT1/latest.json"
pass summary_written test -f "$OUT1/latest-summary.md"
python3 -c "
import json
r = json.load(open('$OUT1/latest.json'))
assert r['pr_head_sha'] == '$HEAD_SHA'
assert r['checked_out_sha'] == '$HEAD_SHA'
assert r['base_sha'] == '$BASE_SHA'
assert r['changed_files_count'] == 2, r['changed_files_count']
assert 'changed_files' not in r, r.keys()
assert sorted(r['changed_file_extension_counts']) == ['.txt']
assert len(r['changed_file_path_hashes']) == 2
assert set(r['changed_file_path_hashes']) != {'b.txt', 'c.txt'}
assert r['commits_count'] == 2, r['commits_count']
assert all('subject' not in c for c in r['commits']), r['commits']
assert all('subject_hash' in c for c in r['commits']), r['commits']
assert r['telemetry_available'] is False
assert r['ci_metadata_unavailable'] is True
assert r['review_metadata_unavailable'] is True
assert r['friction_signals']['repeated_cycle_commits'] == 1, r['friction_signals']
assert r['privacy_contract'] == 'metadata-only'
print('basic artifact fields ok')
"
pass basic_artifact_fields true

# 2. Telemetry correlation when a same-workspace events.jsonl exists.
TELEMETRY_DIR="$REPO/.engineering-os/telemetry"
mkdir -p "$TELEMETRY_DIR"
cat > "$TELEMETRY_DIR/events.jsonl" <<'JSONL'
{"schema_version":"eos.telemetry.v1","attributes":{"eos.tool.name":"Read","eos.tool.command.category":"none"}}
{"schema_version":"eos.telemetry.v1","attributes":{"eos.tool.name":"Bash","eos.tool.command.category":"test"}}
{"schema_version":"eos.telemetry.v1","attributes":{"eos.tool.name":"mcp__github__get_me","eos.tool.command.category":"none"}}
JSONL
OUT2="$TMP/out2"
python3 "$COLLECTOR" --root "$REPO" --pr-head-sha "$HEAD_SHA" --base-sha "$BASE_SHA" --out "$OUT2" >/dev/null
python3 -c "
import json
r = json.load(open('$OUT2/latest.json'))
assert r['telemetry_available'] is True
assert r['telemetry_events_count'] == 3
assert r['telemetry_tool_counts']['Read'] == 1
assert r['telemetry_mcp_tool_counts']['mcp__github__get_me'] == 1
print('telemetry extraction ok')
"
pass telemetry_extraction true

# 3. CI/review metadata extraction from sample fixtures, including a pending check.
CI_JSON="$TMP/ci.json"
cat > "$CI_JSON" <<'JSON'
[{"name": "enforcement-tests", "conclusion": "success"}, {"name": "pr-policy", "conclusion": "pending"}, {"name": "security-review", "conclusion": "failure"}]
JSON
REVIEWS_JSON="$TMP/reviews.json"
cat > "$REVIEWS_JSON" <<'JSON'
{"reviewDecision": "APPROVED", "reviews": [{"state": "APPROVED"}]}
JSON
OUT3="$TMP/out3"
python3 "$COLLECTOR" --root "$REPO" --pr-head-sha "$HEAD_SHA" --base-sha "$BASE_SHA" \
  --ci-json "$CI_JSON" --reviews-json "$REVIEWS_JSON" --out "$OUT3" >/dev/null
python3 -c "
import json
r = json.load(open('$OUT3/latest.json'))
assert r['ci_metadata_unavailable'] is False
assert r['ci_checks_count'] == 3, r['ci_checks_count']
assert r['ci_failure_count'] == 1, r['ci_failure_count']
names = {c['name'] for c in r['ci_checks']}
assert names == {'enforcement-tests', 'pr-policy', 'security-review'}
conclusions = {c['name']: c['conclusion'] for c in r['ci_checks']}
assert conclusions['pr-policy'] == 'pending'
assert r['review_metadata_unavailable'] is False
assert r['friction_signals']['any'] is True
print('ci/review metadata extraction ok, pending not treated as failure')
"
pass ci_review_metadata_extraction true

# 4. Missing/invalid ci-json or reviews-json produces explicit unavailability markers, not a crash.
OUT4="$TMP/out4"
python3 "$COLLECTOR" --root "$REPO" --pr-head-sha "$HEAD_SHA" --base-sha "$BASE_SHA" \
  --ci-json "$TMP/does-not-exist.json" --reviews-json "$TMP/also-missing.json" --out "$OUT4" >/dev/null
python3 -c "
import json
r = json.load(open('$OUT4/latest.json'))
assert r['ci_metadata_unavailable'] is True
assert r['review_metadata_unavailable'] is True
assert r['friction_signals']['ci_metadata_unavailable'] is True
assert r['friction_signals']['review_metadata_unavailable'] is True
print('unavailability markers ok')
"
pass unavailability_markers true

# 5. --empty-run marks an explicit empty run instead of a bare zero.
OUT5="$TMP/out5"
python3 "$COLLECTOR" --root "$REPO" --pr-head-sha "$HEAD_SHA" --base-sha "$BASE_SHA" --out "$OUT5" --empty-run >/dev/null
python3 -c "
import json
r = json.load(open('$OUT5/latest.json'))
assert r['empty_run'] is True
assert r['changed_files_count'] == 0
assert r['commits_count'] == 0
print('empty-run marker ok')
"
pass empty_run_marker true

# 6. gap_id extraction from branch name and from PR body token.
BRANCH_REPO="$TMP/branch-repo"
mkdir -p "$BRANCH_REPO"
(
  cd "$BRANCH_REPO"
  git init -q
  git config user.email work-history@example.invalid
  git config user.name work-history-test
  git checkout -q -b "claude/gap-42"
  echo "x" > x.txt
  git add x.txt
  git commit -qm "start"
)
B_BASE="$(cd "$BRANCH_REPO" && git rev-parse HEAD)"
(
  cd "$BRANCH_REPO"
  echo "y" > y.txt
  git add y.txt
  git commit -qm "work"
)
B_HEAD="$(cd "$BRANCH_REPO" && git rev-parse HEAD)"
OUT6="$TMP/out6"
python3 "$COLLECTOR" --root "$BRANCH_REPO" --pr-head-sha "$B_HEAD" --base-sha "$B_BASE" --out "$OUT6" >/dev/null
python3 -c "
import json
r = json.load(open('$OUT6/latest.json'))
assert r['gap_id'] == '42', r['gap_id']
print('gap_id from branch ok')
"
pass gap_id_from_branch true

# 7. Invalid base/head git refs fail closed instead of producing an empty artifact.
reject invalid_base_sha_fails_closed python3 "$COLLECTOR" --root "$REPO" --pr-head-sha "$HEAD_SHA" --base-sha "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef" --out "$TMP/out-invalid"

echo "collect-pr-work-history simulations passed"