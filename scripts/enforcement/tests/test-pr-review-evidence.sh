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

# positive: external review evidence + valid merge readiness passes.
write_body "$TMP/external-ok.md" "
## External Review Evidence

- source: senior engineer manual review on 2026-07-02.
- result: no blocking findings; two nitpicks addressed.
- decision: approved for merge after nitpick fixes landed.
$MERGE_OK"
pass external_review_with_merge_readiness_passes bash "$CHECK" --body "$TMP/external-ok.md" --head-sha 29a21e1677bac0695652fc51ad9b3b22af425add

# positive: review fallback evidence with real gate names and concrete evidence passes.
write_body "$TMP/fallback-ok.md" "
## Review Fallback Evidence

- reviewer: Claude agent structured self-review pending CodeRabbit and owner review.
- scope: check-pr-review-evidence.sh, pr-policy.yml, test-pr-review-evidence.sh.
- checks: test-pr-review-evidence.sh (16 cases) and enforcement-tests all green.
- risks: extraction could silently change behavior; mitigated by preserved-behavior fixtures.
- decision: safe to review and merge after CI is green and the owner approves.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh and PR #183.
$MERGE_OK"
pass fallback_with_real_gate_and_concrete_evidence_passes bash "$CHECK" --body "$TMP/fallback-ok.md" --head-sha 29a21e1677bac0695652fc51ad9b3b22af425add

# negative: neither section present.
write_body "$TMP/missing-both.md" "
## Summary

Just a summary, no review evidence at all.
$MERGE_OK"
failcase missing_both_review_sections_fails bash "$CHECK" --body "$TMP/missing-both.md"

# negative: external review evidence missing a required field.
write_body "$TMP/external-missing-field.md" "
## External Review Evidence

- source: senior engineer manual review on 2026-07-02.
- result: no blocking findings.
$MERGE_OK"
failcase external_review_missing_decision_fails bash "$CHECK" --body "$TMP/external-missing-field.md"

# negative: fallback checks: field is shallow (no real gate/workflow named).
write_body "$TMP/fallback-shallow-checks.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: everything in the diff.
- checks: reviewed everything carefully and it all looks fine.
- risks: none that I could find.
- decision: safe to merge.
- evidence: PR #183.
$MERGE_OK"
failcase fallback_shallow_checks_fails bash "$CHECK" --body "$TMP/fallback-shallow-checks.md"

# negative: fallback evidence: field is vague (no concrete artifact reference).
write_body "$TMP/fallback-vague-evidence.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: it all works, trust me, I checked it myself very carefully.
$MERGE_OK"
failcase fallback_vague_evidence_fails bash "$CHECK" --body "$TMP/fallback-vague-evidence.md"

# negative: no ## Merge Readiness section at all.
write_body "$TMP/no-merge-readiness.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh.
"
failcase missing_merge_readiness_section_fails bash "$CHECK" --body "$TMP/no-merge-readiness.md"

# negative: Merge Readiness has a placeholder approval field.
write_body "$TMP/merge-readiness-placeholder.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh.

## Merge Readiness

- base: main
- expected-head-sha: 29a21e1677bac0695652fc51ad9b3b22af425add
- ci: enforcement-tests all green.
- threads: no unresolved review threads remain on the PR.
- approval: tbd
"
failcase merge_readiness_placeholder_approval_fails bash "$CHECK" --body "$TMP/merge-readiness-placeholder.md"

# negative: expected-head-sha does not look like a commit SHA.
write_body "$TMP/merge-readiness-bad-sha.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh.

## Merge Readiness

- base: main
- expected-head-sha: whatever the latest commit is
- ci: enforcement-tests all green.
- threads: no unresolved review threads remain on the PR.
- approval: owner explicit go-ahead recorded in chat.
"
failcase merge_readiness_non_sha_value_fails bash "$CHECK" --body "$TMP/merge-readiness-bad-sha.md"

# negative: expected-head-sha does not match the live PR head SHA passed via --head-sha.
write_body "$TMP/merge-readiness-mismatch.md" "$MERGE_OK"
write_body "$TMP/merge-readiness-mismatch-full.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh.
$MERGE_OK"
failcase merge_readiness_sha_mismatch_fails bash "$CHECK" --body "$TMP/merge-readiness-mismatch-full.md" --head-sha 0000000000000000000000000000000000000f

# negative: Merge Readiness ci: field names no real gate/workflow.
write_body "$TMP/merge-readiness-bad-ci.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh.

## Merge Readiness

- base: main
- expected-head-sha: 29a21e1677bac0695652fc51ad9b3b22af425add
- ci: everything passed, all good.
- threads: no unresolved review threads remain on the PR.
- approval: owner explicit go-ahead recorded in chat.
"
failcase merge_readiness_ci_not_real_gate_fails bash "$CHECK" --body "$TMP/merge-readiness-bad-ci.md" --head-sha 29a21e1677bac0695652fc51ad9b3b22af425add

# positive: approval: pending is allowed (records intent, not a placeholder).
write_body "$TMP/merge-readiness-pending.md" "
## Review Fallback Evidence

- reviewer: Claude agent self-review.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-pr-review-evidence.sh.

## Merge Readiness

- base: main
- expected-head-sha: 29a21e1677bac0695652fc51ad9b3b22af425add
- ci: enforcement-tests and pr-policy both green.
- threads: no unresolved review threads remain on the PR.
- approval: pending owner review before merge.
"
pass merge_readiness_pending_approval_is_allowed bash "$CHECK" --body "$TMP/merge-readiness-pending.md" --head-sha 29a21e1677bac0695652fc51ad9b3b22af425add

echo "pr review + merge readiness simulations passed"
