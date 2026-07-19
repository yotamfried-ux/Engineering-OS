#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-pr-review-evidence.sh"
chmod +x "$CHECK"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG_FILE="$TMP/pr-review.log"

pass() { local name="$1"; shift; "$@" >"$LOG_FILE" 2>&1 || { echo "fail: $name"; cat "$LOG_FILE"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$LOG_FILE" 2>&1; then echo "unexpected pass: $name"; cat "$LOG_FILE"; exit 1; else echo "ok: $name"; fi; }
write_body() { printf '%s\n' "$2" > "$1"; }

pass checker_present test -f "$CHECK"

MERGE_OK='
## Merge Readiness

- base: main
- expected-head-sha: 29a21e1677bac0695652fc51ad9b3b22af425add
- ci: enforcement-tests and pr-policy both completed=success for the head SHA.
- threads: no unresolved review threads remain on the PR.
- approval: owner explicit go-ahead recorded in chat 2026-07-02.
'

OP_OK='
## Operational Behavior Evidence

behavior_summary: Completed a scoped governance update and recorded behavior.
engineering_os_influence: Route Plan, audit, checker, review, and CI gates constrained scope.
efficiency_signals: commands_run=12; test_runs=3; failed_test_runs=1; ci_runs=1.
friction_or_false_positives: One evidence wording issue caused a correction loop.
quality_signals: Negative fixture failed and positive fixture passed.
usage_surrogate: exact_token_usage_available=no; wall_clock_minutes=unknown; tool_calls=fixture.
next_system_improvement: Track repeated friction patterns.
'

write_body "$TMP/external-ok.md" "
## External Review Evidence

- source: senior engineer manual review on 2026-07-02.
- result: no blocking findings; two nitpicks addressed.
- decision: approved for merge after nitpick fixes landed.
$OP_OK
$MERGE_OK"
pass external_review_with_merge_readiness_passes bash "$CHECK" --body "$TMP/external-ok.md" --head-sha 29a21e1677bac0695652fc51ad9b3b22af425add

write_body "$TMP/fallback-ok.md" "
## Review Fallback Evidence

- reviewer: Claude agent structured self-review pending CodeRabbit and owner review.
- scope: check-pr-review-evidence.sh, pr-policy.yml, test-pr-review-evidence.sh.
- checks: test-pr-review-evidence.sh and enforcement-tests all green.
- risks: extraction could silently change behavior; mitigated by preserved-behavior fixtures.
- decision: safe to review and merge after CI is green and the owner approves.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh and PR #183.
$OP_OK
$MERGE_OK"
pass fallback_with_real_gate_and_concrete_evidence_passes bash "$CHECK" --body "$TMP/fallback-ok.md" --head-sha 29a21e1677bac0695652fc51ad9b3b22af425add

write_body "$TMP/missing-operational.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh.
$MERGE_OK"
EOS_DISABLE_PLAN_FALLBACK=1 failcase missing_operational_behavior_evidence_fails bash "$CHECK" --body "$TMP/missing-operational.md" --head-sha 29a21e1677bac0695652fc51ad9b3b22af425add

write_body "$TMP/missing-both.md" "
## Summary

Just a summary, no review evidence at all.
$OP_OK
$MERGE_OK"
failcase missing_both_review_sections_fails bash "$CHECK" --body "$TMP/missing-both.md"

write_body "$TMP/external-missing-field.md" "
## External Review Evidence

- source: senior engineer manual review on 2026-07-02.
- result: no blocking findings.
$OP_OK
$MERGE_OK"
failcase external_review_missing_decision_fails bash "$CHECK" --body "$TMP/external-missing-field.md"

write_body "$TMP/fallback-shallow-checks.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: everything in the diff.
- checks: reviewed everything carefully and it all looks fine.
- risks: none that I could find.
- decision: safe to merge.
- evidence: PR #183.
$OP_OK
$MERGE_OK"
failcase fallback_shallow_checks_fails bash "$CHECK" --body "$TMP/fallback-shallow-checks.md"

write_body "$TMP/fallback-vague-evidence.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: it all works, trust me.
$OP_OK
$MERGE_OK"
failcase fallback_vague_evidence_fails bash "$CHECK" --body "$TMP/fallback-vague-evidence.md"

write_body "$TMP/no-merge-readiness.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh.
$OP_OK"
failcase missing_merge_readiness_section_fails bash "$CHECK" --body "$TMP/no-merge-readiness.md"

write_body "$TMP/merge-readiness-placeholder.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh.
$OP_OK
## Merge Readiness

- base: main
- expected-head-sha: 29a21e1677bac0695652fc51ad9b3b22af425add
- ci: enforcement-tests all green.
- threads: no unresolved review threads remain on the PR.
- approval: tbd
"
failcase merge_readiness_placeholder_approval_fails bash "$CHECK" --body "$TMP/merge-readiness-placeholder.md"

write_body "$TMP/merge-readiness-bad-sha.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh.
$OP_OK
## Merge Readiness

- base: main
- expected-head-sha: whatever the latest commit is
- ci: enforcement-tests all green.
- threads: no unresolved review threads remain on the PR.
- approval: owner explicit go-ahead recorded in chat.
"
failcase merge_readiness_non_sha_value_fails bash "$CHECK" --body "$TMP/merge-readiness-bad-sha.md"

write_body "$TMP/merge-readiness-mismatch-full.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh.
$OP_OK
$MERGE_OK"
failcase merge_readiness_sha_mismatch_fails bash "$CHECK" --body "$TMP/merge-readiness-mismatch-full.md" --head-sha 0000000000000000000000000000000000000f

write_body "$TMP/merge-readiness-bad-ci.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh.
$OP_OK
## Merge Readiness

- base: main
- expected-head-sha: 29a21e1677bac0695652fc51ad9b3b22af425add
- ci: everything passed, all good.
- threads: no unresolved review threads remain on the PR.
- approval: owner explicit go-ahead recorded in chat.
"
failcase merge_readiness_ci_not_real_gate_fails bash "$CHECK" --body "$TMP/merge-readiness-bad-ci.md" --head-sha 29a21e1677bac0695652fc51ad9b3b22af425add

write_body "$TMP/merge-readiness-pending.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh.
$OP_OK
## Merge Readiness

- base: main
- expected-head-sha: 29a21e1677bac0695652fc51ad9b3b22af425add
- ci: enforcement-tests and pr-policy both green.
- threads: no unresolved review threads remain on the PR.
- approval: pending owner review before merge.
"
pass merge_readiness_pending_approval_is_allowed bash "$CHECK" --body "$TMP/merge-readiness-pending.md" --head-sha 29a21e1677bac0695652fc51ad9b3b22af425add

# C1: stale-claim check — the PR body can name a real gate token in `ci:` while
# lying about its outcome for the exact head SHA. When live check-run data is
# supplied (the shape `gh pr checks --json name,state,workflow` produces), the
# checker must cross-check the claim instead of trusting the PR-body prose.
write_body "$TMP/merge-readiness-real-gate.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh.
$OP_OK
## Merge Readiness

- base: main
- expected-head-sha: 29a21e1677bac0695652fc51ad9b3b22af425add
- ci: enforcement-tests completed=success for the head SHA.
- threads: no unresolved review threads remain on the PR.
- approval: owner explicit go-ahead recorded in chat.
"

cat > "$TMP/check-runs-success.json" <<'JSON'
[{"name": "enforcement-tests", "state": "SUCCESS", "workflow": "enforcement-tests"}]
JSON
pass merge_readiness_stale_check_matches_real_success bash "$CHECK" --body "$TMP/merge-readiness-real-gate.md" --head-sha 29a21e1677bac0695652fc51ad9b3b22af425add --check-runs "$TMP/check-runs-success.json"

cat > "$TMP/check-runs-failure.json" <<'JSON'
[{"name": "enforcement-tests", "state": "FAILURE", "workflow": "enforcement-tests"}]
JSON
failcase merge_readiness_stale_claim_vs_real_failure_fails bash "$CHECK" --body "$TMP/merge-readiness-real-gate.md" --head-sha 29a21e1677bac0695652fc51ad9b3b22af425add --check-runs "$TMP/check-runs-failure.json"

cat > "$TMP/check-runs-pending.json" <<'JSON'
[{"name": "enforcement-tests", "state": "PENDING", "workflow": "enforcement-tests"}]
JSON
failcase merge_readiness_stale_claim_vs_real_pending_fails bash "$CHECK" --body "$TMP/merge-readiness-real-gate.md" --head-sha 29a21e1677bac0695652fc51ad9b3b22af425add --check-runs "$TMP/check-runs-pending.json"

cat > "$TMP/check-runs-missing.json" <<'JSON'
[{"name": "some-other-check", "state": "SUCCESS", "workflow": "some-other-check"}]
JSON
failcase merge_readiness_stale_claim_no_matching_run_fails bash "$CHECK" --body "$TMP/merge-readiness-real-gate.md" --head-sha 29a21e1677bac0695652fc51ad9b3b22af425add --check-runs "$TMP/check-runs-missing.json"

# No --check-runs supplied at all: backward compatible, behaves like before C1.
pass merge_readiness_without_check_runs_arg_still_passes bash "$CHECK" --body "$TMP/merge-readiness-real-gate.md" --head-sha 29a21e1677bac0695652fc51ad9b3b22af425add

# Review finding: `gh pr checks --json name,state,workflow` reports a job's
# `name` (e.g. "Require ready-for-review PR") separately from its `workflow`
# (e.g. "pr-policy") — docs/operations/main-required-checks.md documents this
# exact split. A PR body naming the workflow, per this repo's own convention,
# must match via the `workflow` field even when no individual job is literally
# named that token.
write_body "$TMP/merge-readiness-workflow-name.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh.
$OP_OK
## Merge Readiness

- base: main
- expected-head-sha: 29a21e1677bac0695652fc51ad9b3b22af425add
- ci: workflow-evidence-policy completed=success for the head SHA.
- threads: no unresolved review threads remain on the PR.
- approval: owner explicit go-ahead recorded in chat.
"
cat > "$TMP/check-runs-workflow-name.json" <<'JSON'
[{"name": "Require Engineering OS workflow evidence", "state": "SUCCESS", "workflow": "workflow-evidence-policy"}]
JSON
pass merge_readiness_matches_via_workflow_field_not_job_name bash "$CHECK" --body "$TMP/merge-readiness-workflow-name.md" --head-sha 29a21e1677bac0695652fc51ad9b3b22af425add --check-runs "$TMP/check-runs-workflow-name.json"

# Review finding: pr-policy is the workflow this check itself runs inside of,
# so its own check run is necessarily still pending/in-progress at this exact
# point and can never report SUCCESS to itself. A conventional PR body citing
# "pr-policy" (used throughout this repo's own real merged PRs, e.g. #199/#200)
# must not be blocked by this self-referential impossibility, even when the
# supplied check-run data shows pr-policy as PENDING or missing entirely.
write_body "$TMP/merge-readiness-self-referential.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests and pr-policy both green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh.
$OP_OK
## Merge Readiness

- base: main
- expected-head-sha: 29a21e1677bac0695652fc51ad9b3b22af425add
- ci: enforcement-tests and pr-policy both completed=success for the head SHA.
- threads: no unresolved review threads remain on the PR.
- approval: owner explicit go-ahead recorded in chat.
"
cat > "$TMP/check-runs-self-referential-pending.json" <<'JSON'
[
  {"name": "enforcement-tests", "state": "SUCCESS", "workflow": "enforcement-tests"},
  {"name": "Require ready-for-review PR", "state": "PENDING", "workflow": "pr-policy"}
]
JSON
pass merge_readiness_self_referential_pr_policy_not_blocked bash "$CHECK" --body "$TMP/merge-readiness-self-referential.md" --head-sha 29a21e1677bac0695652fc51ad9b3b22af425add --check-runs "$TMP/check-runs-self-referential-pending.json"

echo "pr review + merge readiness simulations passed"
