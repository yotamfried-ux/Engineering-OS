#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-known-gaps-live-state.py"
FETCH="$ROOT/scripts/enforcement/fetch-known-gaps-live-state.py"
CANONICAL="$ROOT/scripts/enforcement/check-known-gaps.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

ok() {
  local name="$1"; shift
  "$@" >"$TMP/$name.out" 2>&1 || {
    echo "fail: $name"
    cat "$TMP/$name.out"
    exit 1
  }
  echo "ok: $name"
}

no() {
  local name="$1"; shift
  if "$@" >"$TMP/$name.out" 2>&1; then
    echo "unexpected pass: $name"
    cat "$TMP/$name.out"
    exit 1
  fi
  echo "ok: $name"
}

HEAD_SHA="1111111111111111111111111111111111111111"
MERGE_SHA="2222222222222222222222222222222222222222"

cat >"$TMP/test-artifact.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TMP/test-artifact.sh"

cat >"$TMP/gaps.tsv" <<EOF
fixture-closed	owner	closed	P0	Risk description is sufficiently concrete.	Mitigation description is sufficiently concrete.	$TMP/test-artifact.sh	Closed and verified by fixture evidence.	$TMP/test-artifact.sh	Fixture notes.
EOF

cat >"$TMP/claims.json" <<EOF
{
  "schema_version": "eos.known-gaps-live-claims.v1",
  "claims": [
    {
      "claim_id": "fixture-pr-7",
      "gap_id": "fixture-closed",
      "repository": "octo-org/octo-repo",
      "pull_number": 7,
      "base_branch": "main",
      "expected_head_sha": "$HEAD_SHA",
      "expected_merge_commit_sha": "$MERGE_SHA",
      "required_pull_request_workflows": ["pr-policy", "enforcement-tests"],
      "required_push_workflows": ["post-merge-validation"],
      "required_check_runs": ["enforcement-tests"]
    }
  ]
}
EOF

write_snapshot() {
  local out="$1"
  cat >"$out" <<EOF
{
  "schema_version": "eos.known-gaps-live-snapshot.v1",
  "generated_at": "2026-07-22T04:00:00Z",
  "claims": [
    {
      "claim_id": "fixture-pr-7",
      "repository": "octo-org/octo-repo",
      "pull_number": 7,
      "pull": {
        "state": "closed",
        "merged": true,
        "head_sha": "$HEAD_SHA",
        "merge_commit_sha": "$MERGE_SHA",
        "base_ref": "main",
        "merged_at": "2026-07-22T03:59:16Z",
        "html_url": "https://github.com/octo-org/octo-repo/pull/7"
      },
      "base_containment": {
        "base_branch": "main",
        "status": "ahead",
        "ahead_by": 2,
        "behind_by": 0,
        "total_commits": 2,
        "merge_base_sha": "$MERGE_SHA",
        "html_url": "https://github.com/octo-org/octo-repo/compare/$MERGE_SHA...main"
      },
      "pull_request_workflow_runs": [
        {
          "id": 10,
          "name": "pr-policy",
          "event": "pull_request",
          "head_sha": "$HEAD_SHA",
          "status": "completed",
          "conclusion": "success",
          "run_number": 20,
          "run_attempt": 1,
          "run_started_at": "2026-07-22T03:30:00Z",
          "updated_at": "2026-07-22T03:31:00Z"
        },
        {
          "id": 11,
          "name": "enforcement-tests",
          "event": "pull_request",
          "head_sha": "$HEAD_SHA",
          "status": "completed",
          "conclusion": "failure",
          "run_number": 30,
          "run_attempt": 1,
          "run_started_at": "2026-07-22T03:35:00Z",
          "updated_at": "2026-07-22T03:36:00Z"
        },
        {
          "id": 12,
          "name": "enforcement-tests",
          "event": "pull_request",
          "head_sha": "$HEAD_SHA",
          "status": "completed",
          "conclusion": "success",
          "run_number": 31,
          "run_attempt": 1,
          "run_started_at": "2026-07-22T03:40:00Z",
          "updated_at": "2026-07-22T03:41:00Z"
        }
      ],
      "push_workflow_runs": [
        {
          "id": 13,
          "name": "post-merge-validation",
          "event": "push",
          "head_sha": "$MERGE_SHA",
          "status": "completed",
          "conclusion": "success",
          "run_number": 8,
          "run_attempt": 1,
          "run_started_at": "2026-07-22T03:45:00Z",
          "updated_at": "2026-07-22T03:46:00Z"
        }
      ],
      "check_runs": [
        {
          "id": 14,
          "name": "enforcement-tests",
          "head_sha": "$HEAD_SHA",
          "status": "completed",
          "conclusion": "success",
          "completed_at": "2026-07-22T03:50:00Z"
        }
      ]
    }
  ]
}
EOF
}

write_snapshot "$TMP/good-snapshot.json"

run_check() {
  python3 "$CHECK" \
    --claims "$TMP/claims.json" \
    --snapshot "$1" \
    --known-gaps "$TMP/gaps.tsv"
}

ok positive_snapshot_passes run_check "$TMP/good-snapshot.json"

python3 - "$TMP/good-snapshot.json" "$TMP/unmerged.json" <<'PY'
import json, sys
data=json.load(open(sys.argv[1]))
data["claims"][0]["pull"]["merged"]=False
json.dump(data, open(sys.argv[2],"w"))
PY
no unmerged_pull_fails run_check "$TMP/unmerged.json"

python3 - "$TMP/good-snapshot.json" "$TMP/stale-head.json" <<'PY'
import json, sys
data=json.load(open(sys.argv[1]))
data["claims"][0]["pull"]["head_sha"]="3"*40
json.dump(data, open(sys.argv[2],"w"))
PY
no stale_head_fails run_check "$TMP/stale-head.json"

python3 - "$TMP/good-snapshot.json" "$TMP/stale-merge.json" <<'PY'
import json, sys
data=json.load(open(sys.argv[1]))
data["claims"][0]["pull"]["merge_commit_sha"]="4"*40
json.dump(data, open(sys.argv[2],"w"))
PY
no stale_merge_sha_fails run_check "$TMP/stale-merge.json"

python3 - "$TMP/good-snapshot.json" "$TMP/diverged.json" <<'PY'
import json, sys
data=json.load(open(sys.argv[1]))
data["claims"][0]["base_containment"]["status"]="diverged"
data["claims"][0]["base_containment"]["behind_by"]=1
json.dump(data, open(sys.argv[2],"w"))
PY
no base_divergence_fails run_check "$TMP/diverged.json"

python3 - "$TMP/good-snapshot.json" "$TMP/latest-failure.json" <<'PY'
import json, sys
data=json.load(open(sys.argv[1]))
data["claims"][0]["pull_request_workflow_runs"].append({
  "id": 15,
  "name": "enforcement-tests",
  "event": "pull_request",
  "head_sha": "1"*40,
  "status": "completed",
  "conclusion": "failure",
  "run_number": 32,
  "run_attempt": 1,
  "run_started_at": "2026-07-22T03:50:00Z",
  "updated_at": "2026-07-22T03:51:00Z"
})
json.dump(data, open(sys.argv[2],"w"))
PY
no newest_failed_workflow_fails run_check "$TMP/latest-failure.json"

python3 - "$TMP/good-snapshot.json" "$TMP/rerun-late-failure.json" <<'PY'
import json, sys
data=json.load(open(sys.argv[1]))
data["claims"][0]["pull_request_workflow_runs"].append({
  "id": 16,
  "name": "enforcement-tests",
  "event": "pull_request",
  "head_sha": "1"*40,
  "status": "completed",
  "conclusion": "failure",
  "run_number": 30,
  "run_attempt": 2,
  "run_started_at": "2026-07-22T04:10:00Z",
  "updated_at": "2026-07-22T04:11:00Z"
})
json.dump(data, open(sys.argv[2],"w"))
PY
no later_rerun_of_older_run_fails run_check "$TMP/rerun-late-failure.json"

python3 - "$TMP/good-snapshot.json" "$TMP/skipped-push.json" <<'PY'
import json, sys
data=json.load(open(sys.argv[1]))
data["claims"][0]["push_workflow_runs"][0]["conclusion"]="skipped"
json.dump(data, open(sys.argv[2],"w"))
PY
no skipped_push_workflow_fails run_check "$TMP/skipped-push.json"

python3 - "$TMP/good-snapshot.json" "$TMP/neutral-check.json" <<'PY'
import json, sys
data=json.load(open(sys.argv[1]))
data["claims"][0]["check_runs"][0]["conclusion"]="neutral"
json.dump(data, open(sys.argv[2],"w"))
PY
no neutral_check_run_fails run_check "$TMP/neutral-check.json"

python3 - "$TMP/good-snapshot.json" "$TMP/missing-workflow.json" <<'PY'
import json, sys
data=json.load(open(sys.argv[1]))
data["claims"][0]["push_workflow_runs"]=[]
json.dump(data, open(sys.argv[2],"w"))
PY
no missing_required_workflow_fails run_check "$TMP/missing-workflow.json"

cat >"$TMP/open-gaps.tsv" <<EOF
fixture-closed	owner	open	P0	Risk description is sufficiently concrete.	Mitigation description is sufficiently concrete.	$TMP/test-artifact.sh	Closure description is sufficiently concrete.	NONE	Fixture notes.
EOF
no live_claim_for_open_gap_fails python3 "$CHECK" \
  --claims "$TMP/claims.json" \
  --snapshot "$TMP/good-snapshot.json" \
  --known-gaps "$TMP/open-gaps.tsv"

python3 - "$TMP/claims.json" "$TMP/self-only-claims.json" <<'PY'
import json, sys
data=json.load(open(sys.argv[1]))
data["claims"][0]["required_pull_request_workflows"]=["pr-policy"]
json.dump(data, open(sys.argv[2],"w"))
PY
no self_only_evidence_fails python3 "$CHECK" \
  --claims "$TMP/self-only-claims.json" \
  --snapshot "$TMP/good-snapshot.json" \
  --known-gaps "$TMP/gaps.tsv"

cat >"$TMP/bad-schema.json" <<'EOF'
{"schema_version":"wrong","generated_at":"2026-07-22T04:00:00Z","claims":[]}
EOF
no malformed_snapshot_fails run_check "$TMP/bad-schema.json"

cat >"$TMP/audit.md" <<'EOF'
# Audit

## Known gaps freshness ledger

| gap_id | status | priority | audit row / readiness context |
|---|---|---|---|
| fixture-closed | closed | P0 | Fixture live claim. |
EOF
ok canonical_checker_uses_live_snapshot env \
  EOS_KNOWN_GAPS_MIN_ROWS=1 \
  EOS_KNOWN_GAPS_LIVE_CLAIMS="$TMP/claims.json" \
  EOS_KNOWN_GAPS_LIVE_SNAPSHOT="$TMP/good-snapshot.json" \
  bash "$CANONICAL" "$TMP/gaps.tsv" "$TMP/audit.md"

no canonical_checker_propagates_live_failure env \
  EOS_KNOWN_GAPS_MIN_ROWS=1 \
  EOS_KNOWN_GAPS_LIVE_CLAIMS="$TMP/claims.json" \
  EOS_KNOWN_GAPS_LIVE_SNAPSHOT="$TMP/latest-failure.json" \
  bash "$CANONICAL" "$TMP/gaps.tsv" "$TMP/audit.md"

# Unit-test fetch normalization without network by importing the official CLI module
# and injecting a fake client with documented REST-shaped responses.
ok fetcher_normalizes_documented_fields python3 - "$FETCH" "$TMP/fetched.json" <<'PY'
import importlib.util, json, sys
spec=importlib.util.spec_from_file_location("fetch_live", sys.argv[1])
module=importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class FakeClient:
    def get(self, path, query=None):
        if "/pulls/" in path:
            return {
                "state":"closed","merged":True,"merge_commit_sha":"2"*40,
                "merged_at":"2026-07-22T03:59:16Z",
                "html_url":"https://github.com/octo-org/octo-repo/pull/7",
                "head":{"sha":"1"*40},"base":{"ref":"main"}
            }
        if "/compare/" in path:
            return {
                "status":"identical","ahead_by":0,"behind_by":0,"total_commits":0,
                "merge_base_commit":{"sha":"2"*40},
                "html_url":"https://github.com/octo-org/octo-repo/compare"
            }
        raise AssertionError(path)
    def get_paginated(self, path, *, list_field, query=None, max_pages=20):
        if list_field == "workflow_runs":
            event=query["event"]
            sha=query["head_sha"]
            return [{
                "id":1,"name":"fixture","event":event,"head_sha":sha,
                "status":"completed","conclusion":"success",
                "run_number":1,"run_attempt":1,
                "run_started_at":"2026-07-22T03:00:00Z",
                "created_at":"2026-07-22T03:00:00Z",
                "updated_at":"2026-07-22T03:01:00Z",
                "html_url":"https://github.com/example/run/1"
            }]
        if list_field == "check_runs":
            return [{
                "id":2,"name":"fixture-check","status":"completed",
                "conclusion":"success","started_at":"2026-07-22T03:00:00Z",
                "completed_at":"2026-07-22T03:01:00Z",
                "details_url":"https://github.com/example/check/2",
                "app":{"slug":"github-actions"}
            }]
        raise AssertionError(list_field)

claims=[{
  "claim_id":"fixture-pr-7","repository":"octo-org/octo-repo","pull_number":7,
  "base_branch":"main","expected_head_sha":"1"*40,
  "expected_merge_commit_sha":"2"*40
}]
snapshot=module.build_snapshot(claims, FakeClient())
assert snapshot["schema_version"] == module.SNAPSHOT_SCHEMA
entry=snapshot["claims"][0]
assert entry["pull"]["head_sha"] == "1"*40
assert entry["base_containment"]["merge_base_sha"] == "2"*40
assert entry["check_runs"][0]["app_slug"] == "github-actions"
json.dump(snapshot, open(sys.argv[2],"w"))
PY

no fetcher_requires_token env -u GITHUB_TOKEN -u GH_TOKEN \
  python3 "$FETCH" --claims "$TMP/claims.json" --output "$TMP/no-token.json" --require-token

echo "known gaps live-state tests passed"
