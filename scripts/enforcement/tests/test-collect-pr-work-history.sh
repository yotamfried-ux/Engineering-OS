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
  mkdir -p scripts
  echo "two" > scripts/b.txt
  git add scripts/b.txt
  git commit -qm "add feature"
  echo "three" > scripts/c.txt
  git add scripts/c.txt
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
rlc = r['result_loop_contract']
assert rlc['required'] is True, rlc
assert rlc['selection_source'] == 'derived', rlc
assert rlc['selected_result_loop_contract'] == 'engineering-os-governance', rlc
assert rlc['validation_status'] == 'valid', rlc
assert rlc['matched_manifest_row'] == 'scripts/enforcement/result-loop-requirements.tsv#engineering-os-governance', rlc
assert rlc['reason'], rlc
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
rlc = r['result_loop_contract']
assert rlc['required'] is False, rlc
assert rlc['selection_source'] == 'not_required', rlc
assert rlc['selected_result_loop_contract'] == '', rlc
assert rlc['reason'], rlc
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

# 8. Result-loop contract selection: ambiguous derivation (a templates/<id>/ path plus a
# plain governance-surface path) resolves via the declared PR-body field when present and
# valid, falls back to ambiguous/missing when absent, and rejects unknown/placeholder/
# unrelated declared values. --root points at a throwaway repo with no scripts/ tree at
# all, proving the manifest is resolved relative to the collector's own file location,
# not --root.
AMBIG_REPO="$TMP/ambig-repo"
mkdir -p "$AMBIG_REPO"
(
  cd "$AMBIG_REPO"
  git init -q
  git config user.email work-history@example.invalid
  git config user.name work-history-test
  echo "base" > base.txt
  git add base.txt
  git commit -qm "base commit"
)
AMBIG_BASE="$(cd "$AMBIG_REPO" && git rev-parse HEAD)"
(
  cd "$AMBIG_REPO"
  mkdir -p templates/web-application scripts
  echo "<html></html>" > templates/web-application/index.html
  echo "note" > scripts/notes.txt
  git add templates/web-application/index.html scripts/notes.txt
  git commit -qm "touch template and governance surface"
)
AMBIG_HEAD="$(cd "$AMBIG_REPO" && git rev-parse HEAD)"

# 8a. No selected_result_loop_contract declared -> ambiguous/missing.
BODY_NONE="$TMP/body-none.md"
cat > "$BODY_NONE" <<'EOF'
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
EOF
OUT8A="$TMP/out8a"
python3 "$COLLECTOR" --root "$AMBIG_REPO" --pr-head-sha "$AMBIG_HEAD" --base-sha "$AMBIG_BASE" \
  --pr-body-file "$BODY_NONE" --out "$OUT8A" >/dev/null
python3 -c "
import json
rlc = json.load(open('$OUT8A/latest.json'))['result_loop_contract']
assert rlc['required'] is True, rlc
assert rlc['selection_source'] == 'ambiguous', rlc
assert rlc['validation_status'] == 'missing', rlc
assert rlc['selected_result_loop_contract'] == '', rlc
assert 'web-application' in rlc['reason'] and 'engineering-os-governance' in rlc['reason'], rlc
print('ambiguous missing declaration ok')
"
pass ambiguous_missing_declaration true

# 8b. Valid declared value matching one of the real candidates passes.
BODY_VALID="$TMP/body-valid.md"
cat > "$BODY_VALID" <<'EOF'
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
selected_result_loop_contract: web-application
EOF
OUT8B="$TMP/out8b"
python3 "$COLLECTOR" --root "$AMBIG_REPO" --pr-head-sha "$AMBIG_HEAD" --base-sha "$AMBIG_BASE" \
  --pr-body-file "$BODY_VALID" --out "$OUT8B" >/dev/null
python3 -c "
import json
rlc = json.load(open('$OUT8B/latest.json'))['result_loop_contract']
assert rlc['selection_source'] == 'declared', rlc
assert rlc['validation_status'] == 'valid', rlc
assert rlc['selected_result_loop_contract'] == 'web-application', rlc
assert rlc['matched_manifest_row'] == 'scripts/enforcement/result-loop-requirements.tsv#web-application', rlc
print('declared valid ok')
"
pass declared_valid_matching_candidate true

# 8c. Declared value that is a real manifest id but unrelated to the actual diff fails
# (anti-gaming: a valid-but-irrelevant id must not satisfy the gate).
BODY_UNRELATED="$TMP/body-unrelated.md"
cat > "$BODY_UNRELATED" <<'EOF'
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
selected_result_loop_contract: cli-tool
EOF
OUT8C="$TMP/out8c"
python3 "$COLLECTOR" --root "$AMBIG_REPO" --pr-head-sha "$AMBIG_HEAD" --base-sha "$AMBIG_BASE" \
  --pr-body-file "$BODY_UNRELATED" --out "$OUT8C" >/dev/null
python3 -c "
import json
rlc = json.load(open('$OUT8C/latest.json'))['result_loop_contract']
assert rlc['selection_source'] == 'declared', rlc
assert rlc['validation_status'] == 'invalid', rlc
assert rlc['selected_result_loop_contract'] == 'cli-tool', rlc
print('declared unrelated ok')
"
pass declared_unrelated_to_diff_fails_validation true

# 8d. Declared value not present in the manifest at all fails as unknown_id.
BODY_UNKNOWN="$TMP/body-unknown.md"
cat > "$BODY_UNKNOWN" <<'EOF'
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
selected_result_loop_contract: not-a-real-project-type
EOF
OUT8D="$TMP/out8d"
python3 "$COLLECTOR" --root "$AMBIG_REPO" --pr-head-sha "$AMBIG_HEAD" --base-sha "$AMBIG_BASE" \
  --pr-body-file "$BODY_UNKNOWN" --out "$OUT8D" >/dev/null
python3 -c "
import json
rlc = json.load(open('$OUT8D/latest.json'))['result_loop_contract']
assert rlc['validation_status'] == 'unknown_id', rlc
print('declared unknown id ok')
"
pass declared_unknown_id_fails_validation true

# 8e. Declared placeholder value fails as placeholder.
BODY_PLACEHOLDER="$TMP/body-placeholder.md"
cat > "$BODY_PLACEHOLDER" <<'EOF'
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
selected_result_loop_contract: tbd
EOF
OUT8E="$TMP/out8e"
python3 "$COLLECTOR" --root "$AMBIG_REPO" --pr-head-sha "$AMBIG_HEAD" --base-sha "$AMBIG_BASE" \
  --pr-body-file "$BODY_PLACEHOLDER" --out "$OUT8E" >/dev/null
python3 -c "
import json
rlc = json.load(open('$OUT8E/latest.json'))['result_loop_contract']
assert rlc['validation_status'] == 'placeholder', rlc
print('declared placeholder ok')
"
pass declared_placeholder_fails_validation true

# 9. templates/rag-system/... (a real alias of the ai-agent project type, per
# project-type-roadmaps.tsv's template_path column) resolves to ai-agent, not
# an unrelated/unregistered bucket.
RAG_REPO="$TMP/rag-repo"
mkdir -p "$RAG_REPO"
(
  cd "$RAG_REPO"
  git init -q
  git config user.email work-history@example.invalid
  git config user.name work-history-test
  echo "base" > base.txt
  git add base.txt
  git commit -qm "base commit"
)
RAG_BASE="$(cd "$RAG_REPO" && git rev-parse HEAD)"
(
  cd "$RAG_REPO"
  mkdir -p templates/rag-system
  echo "content" > templates/rag-system/README.md
  git add templates/rag-system/README.md
  git commit -qm "touch rag-system template alias"
)
RAG_HEAD="$(cd "$RAG_REPO" && git rev-parse HEAD)"
OUT9="$TMP/out9"
python3 "$COLLECTOR" --root "$RAG_REPO" --pr-head-sha "$RAG_HEAD" --base-sha "$RAG_BASE" --out "$OUT9" >/dev/null
python3 -c "
import json
rlc = json.load(open('$OUT9/latest.json'))['result_loop_contract']
assert rlc['selection_source'] == 'derived', rlc
assert rlc['selected_result_loop_contract'] == 'ai-agent', rlc
assert rlc['validation_status'] == 'valid', rlc
print('rag-system alias resolves to ai-agent ok')
"
pass rag_system_alias_resolves_to_ai_agent true

# 10. Ordinary application source outside any recognized template/governance
# surface (simulating a downstream installed target project's own app code,
# e.g. src/App.tsx) is left unclassified — it must NOT silently resolve to
# engineering-os-governance, and must NOT be satisfied by an unrelated
# declared value either.
APP_REPO="$TMP/app-repo"
mkdir -p "$APP_REPO"
(
  cd "$APP_REPO"
  git init -q
  git config user.email work-history@example.invalid
  git config user.name work-history-test
  echo "base" > base.txt
  git add base.txt
  git commit -qm "base commit"
)
APP_BASE="$(cd "$APP_REPO" && git rev-parse HEAD)"
(
  cd "$APP_REPO"
  mkdir -p src
  echo "export default function App() {}" > src/App.tsx
  git add src/App.tsx
  git commit -qm "add App component"
)
APP_HEAD="$(cd "$APP_REPO" && git rev-parse HEAD)"
OUT10A="$TMP/out10a"
python3 "$COLLECTOR" --root "$APP_REPO" --pr-head-sha "$APP_HEAD" --base-sha "$APP_BASE" \
  --pr-body-file "$BODY_NONE" --out "$OUT10A" >/dev/null
python3 -c "
import json
rlc = json.load(open('$OUT10A/latest.json'))['result_loop_contract']
assert rlc['selection_source'] != 'derived', rlc
assert rlc['selected_result_loop_contract'] != 'engineering-os-governance', rlc
assert rlc['validation_status'] == 'missing', rlc
print('unclassified app source does not silently resolve to governance ok')
"
pass unclassified_app_source_not_silently_governance true

BODY_APP_DECLARED="$TMP/body-app-declared.md"
cat > "$BODY_APP_DECLARED" <<'EOF'
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
selected_result_loop_contract: web-application
EOF
OUT10B="$TMP/out10b"
python3 "$COLLECTOR" --root "$APP_REPO" --pr-head-sha "$APP_HEAD" --base-sha "$APP_BASE" \
  --pr-body-file "$BODY_APP_DECLARED" --out "$OUT10B" >/dev/null
python3 -c "
import json
rlc = json.load(open('$OUT10B/latest.json'))['result_loop_contract']
assert rlc['selection_source'] == 'declared', rlc
assert rlc['selected_result_loop_contract'] == 'web-application', rlc
assert rlc['validation_status'] == 'valid', rlc
print('unclassified app source accepts a real declared contract ok')
"
pass unclassified_app_source_accepts_declared_contract true

echo "collect-pr-work-history simulations passed"