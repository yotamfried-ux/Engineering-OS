#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-operational-work-history-evidence.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG_FILE="$TMP/log"

pass() { local name="$1"; shift; "$@" >"$LOG_FILE" 2>&1 || { echo "fail: $name"; cat "$LOG_FILE"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$LOG_FILE" 2>&1; then echo "unexpected pass: $name"; cat "$LOG_FILE"; exit 1; else echo "ok: $name"; fi; }

pass checker_present test -f "$CHECK"

mkdir -p "$TMP/lessons-learned/bugs" "$TMP/failed-solutions"

cat > "$TMP/lessons-learned/bugs/complete.md" <<'EOF'
# complete lesson

## מה קרה
symptom

## שורש הבעיה
root cause

## השערות שנבדקו
- A rejected

## ראיה
log evidence

## רמת ביטחון
Medium

## איך מזהים מוקדם
early signal

## איך מונעים בעתיד
prevention

## טסט רגרסיה
tests/regression_test.py

## סטטוס הבשלה
Verified Lesson

## Prevented Future Issues: 0
EOF

cat > "$TMP/lessons-learned/bugs/incomplete.md" <<'EOF'
# incomplete lesson

## מה קרה
symptom only, missing everything else
EOF

DEFAULT_RLC='{
    "required": true,
    "selection_source": "derived",
    "selected_result_loop_contract": "engineering-os-governance",
    "validation_status": "valid",
    "matched_manifest_row": "scripts/enforcement/result-loop-requirements.tsv#engineering-os-governance",
    "reason": "deterministically derived: all changed path(s) map to exactly one result-loop contract (engineering-os-governance)."
  }'

write_artifact() {
  local path="$1" head_sha="$2" changed="$3" commits="$4" empty_run="$5" ci_unavail="$6" review_unavail="$7" friction_any="$8" ci_failures="$9"
  write_artifact_rlc "$path" "$head_sha" "$changed" "$commits" "$empty_run" "$ci_unavail" "$review_unavail" "$friction_any" "$ci_failures" "$DEFAULT_RLC"
}

write_artifact_rlc() {
  local path="$1" head_sha="$2" changed="$3" commits="$4" empty_run="$5" ci_unavail="$6" review_unavail="$7" friction_any="$8" ci_failures="$9" rlc_json="${10}"
  mkdir -p "$(dirname "$path")"
  cat > "$path" <<JSON
{
  "pr_head_sha": "$head_sha",
  "changed_files_count": $changed,
  "commits_count": $commits,
  "empty_run": $empty_run,
  "ci_metadata_unavailable": $ci_unavail,
  "review_metadata_unavailable": $review_unavail,
  "friction_signals": {"any": $friction_any, "ci_failures": $ci_failures},
  "result_loop_contract": $rlc_json
}
JSON
}

changed_files() { printf '%s\n' "$@" > "$TMP/changed.txt"; echo "$TMP/changed.txt"; }

# 1. Valid PR with a clean artifact and minimal none-with-reason passes.
write_artifact "$TMP/artifact-clean.json" "abcdef1234567890abcdef1234567890abcdef12" 3 1 false false false false 0
cat > "$TMP/body-clean.md" <<'EOF'
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
learning_loop_result: none-with-reason — small scoped change with no reusable lesson
EOF
CF="$(changed_files src/a.py src/b.py src/c.py)"
pass valid_clean_pr_passes bash "$CHECK" --body "$TMP/body-clean.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/artifact-clean.json" --changed-files "$CF" --root "$TMP"

# 2. Missing artifact fails.
CF="$(changed_files src/a.py src/b.py src/c.py)"
failcase missing_artifact_fails bash "$CHECK" --body "$TMP/body-clean.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/does-not-exist.json" --changed-files "$CF" --root "$TMP"

# 3. pr_head_sha mismatch fails.
CF="$(changed_files src/a.py src/b.py src/c.py)"
failcase head_sha_mismatch_fails bash "$CHECK" --body "$TMP/body-clean.md" --head-sha "zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz" \
  --artifact "$TMP/artifact-clean.json" --changed-files "$CF" --root "$TMP"

# 4. Zero-count artifact without any unavailability/empty-run marker is a dummy/mismatch.
write_artifact "$TMP/artifact-dummy.json" "abcdef1234567890abcdef1234567890abcdef12" 0 0 false false false false 0
CF="$(changed_files src/a.py src/b.py)"
failcase dummy_artifact_fails bash "$CHECK" --body "$TMP/body-clean.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/artifact-dummy.json" --changed-files "$CF" --root "$TMP"

# 5. Artifact WITH unavailability markers still passes when counts match the workflow metadata.
write_artifact "$TMP/artifact-unavailable.json" "abcdef1234567890abcdef1234567890abcdef12" 2 0 false true true false 0
CF="$(changed_files src/a.py src/b.py)"
pass unavailable_markers_still_pass bash "$CHECK" --body "$TMP/body-clean.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/artifact-unavailable.json" --changed-files "$CF" --root "$TMP"

# 6. PR diff touching the generated artifact path fails, regardless of body content.
CF="$(changed_files .engineering-os/work-history/latest.json src/a.py src/b.py)"
failcase artifact_in_diff_fails bash "$CHECK" --body "$TMP/body-clean.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/artifact-clean.json" --changed-files "$CF" --root "$TMP"

# 7. Friction-signal artifact with neither learning_loop_artifact nor learning_loop_result fails.
write_artifact "$TMP/artifact-friction.json" "abcdef1234567890abcdef1234567890abcdef12" 3 2 false false false true 1
cat > "$TMP/body-no-routing.md" <<'EOF'
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
EOF
CF="$(changed_files src/a.py src/b.py src/c.py)"
failcase friction_missing_routing_fails bash "$CHECK" --body "$TMP/body-no-routing.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/artifact-friction.json" --changed-files "$CF" --root "$TMP"

# 8. Friction-signal artifact with a generic/placeholder none-with-reason fails.
cat > "$TMP/body-generic-reason.md" <<'EOF'
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
learning_loop_result: none-with-reason — everything looked fine to me
EOF
CF="$(changed_files src/a.py src/b.py src/c.py)"
failcase friction_generic_reason_fails bash "$CHECK" --body "$TMP/body-generic-reason.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/artifact-friction.json" --changed-files "$CF" --root "$TMP"

# 9. Friction-signal artifact with a concrete, signal-addressing reason passes.
cat > "$TMP/body-concrete-reason.md" <<'EOF'
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
learning_loop_result: none-with-reason — the one CI failure was a known flaky network timeout unrelated to this diff
EOF
CF="$(changed_files src/a.py src/b.py src/c.py)"
pass friction_concrete_reason_passes bash "$CHECK" --body "$TMP/body-concrete-reason.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/artifact-friction.json" --changed-files "$CF" --root "$TMP"

# 10. Friction-signal artifact with a real, schema-complete learning_loop_artifact passes.
cat > "$TMP/body-real-lesson.md" <<'EOF'
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
learning_loop_artifact: lessons-learned/bugs/complete.md
EOF
CF="$(changed_files src/a.py src/b.py src/c.py)"
pass real_lesson_artifact_passes bash "$CHECK" --body "$TMP/body-real-lesson.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/artifact-friction.json" --changed-files "$CF" --root "$TMP"

# 11. learning_loop_artifact pointing to a missing file fails.
cat > "$TMP/body-missing-lesson.md" <<'EOF'
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
learning_loop_artifact: lessons-learned/bugs/does-not-exist.md
EOF
CF="$(changed_files src/a.py src/b.py src/c.py)"
failcase missing_lesson_artifact_fails bash "$CHECK" --body "$TMP/body-missing-lesson.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/artifact-friction.json" --changed-files "$CF" --root "$TMP"

# 12. learning_loop_artifact pointing to a schema-incomplete file fails.
cat > "$TMP/body-incomplete-lesson.md" <<'EOF'
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
learning_loop_artifact: lessons-learned/bugs/incomplete.md
EOF
CF="$(changed_files src/a.py src/b.py src/c.py)"
failcase incomplete_lesson_artifact_fails bash "$CHECK" --body "$TMP/body-incomplete-lesson.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/artifact-friction.json" --changed-files "$CF" --root "$TMP"

# 13. Both fields present fails.
cat > "$TMP/body-both.md" <<'EOF'
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
learning_loop_artifact: lessons-learned/bugs/complete.md
learning_loop_result: none-with-reason — also present, which is not allowed
EOF
CF="$(changed_files src/a.py src/b.py src/c.py)"
failcase both_routing_fields_fails bash "$CHECK" --body "$TMP/body-both.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/artifact-friction.json" --changed-files "$CF" --root "$TMP"

# 14. A single non-governance file is not automatically exempt; filename-only exemptions are too broad.
echo "no evidence section here" > "$TMP/body-empty.md"
CF="$(changed_files src/a.py)"
failcase single_non_governance_without_evidence_fails bash "$CHECK" --body "$TMP/body-empty.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/artifact-clean.json" --changed-files "$CF" --root "$TMP"

# 15. A single changed file under a governance path is never exemptible.
for governance_file in "docs/operations/known-gaps.tsv" ".github/workflows/pr-policy.yml" "scripts/enforcement/check-known-gaps.sh" \
                        "scripts/monitoring/eos-telemetry-event.sh" "core/learning-loop.md" "CLAUDE.md"; do
  CF="$(changed_files "$governance_file")"
  failcase "governance_path_${governance_file//\//_}_not_exempt" bash "$CHECK" --body "$TMP/body-empty.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
    --artifact "$TMP/artifact-clean.json" --changed-files "$CF" --root "$TMP"
done

# 16. More than one changed file is system-affecting and requires evidence.
CF="$(changed_files src/a.py src/b.py)"
failcase multi_file_change_requires_evidence bash "$CHECK" --body "$TMP/body-empty.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/artifact-clean.json" --changed-files "$CF" --root "$TMP"

# 17. Empty changed-files metadata in PR workflow mode fails closed.
: > "$TMP/no-changes.txt"
failcase empty_changed_files_fails_closed bash "$CHECK" --body "$TMP/body-clean.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/artifact-clean.json" --changed-files "$TMP/no-changes.txt" --root "$TMP"

# 18. Direct local compatibility mode still skips when --changed-files is not supplied at all.
pass no_changed_files_argument_skips_outside_pr_mode bash "$CHECK" --body "$TMP/body-empty.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/artifact-clean.json" --root "$TMP"

# 19. Artifact count mismatch fails, preventing stale/wrong-ref artifacts.
write_artifact "$TMP/artifact-count-mismatch.json" "abcdef1234567890abcdef1234567890abcdef12" 1 1 false false false false 0
CF="$(changed_files src/a.py src/b.py)"
failcase artifact_changed_file_count_mismatch_fails bash "$CHECK" --body "$TMP/body-clean.md" --head-sha "abcdef1234567890abcdef1234567890abcdef12" \
  --artifact "$TMP/artifact-count-mismatch.json" --changed-files "$CF" --root "$TMP"

# --- Result-loop contract selection (per-PR declaration dimension) ---

RLC_HEAD="abcdef1234567890abcdef1234567890abcdef12"

# 20. Derived, valid result_loop_contract passes (default block already covers this
# implicitly via write_artifact, but assert it explicitly too).
write_artifact "$TMP/artifact-rlc-derived.json" "$RLC_HEAD" 3 1 false false false false 0
CF="$(changed_files src/a.py src/b.py src/c.py)"
pass rlc_derived_valid_passes bash "$CHECK" --body "$TMP/body-clean.md" --head-sha "$RLC_HEAD" \
  --artifact "$TMP/artifact-rlc-derived.json" --changed-files "$CF" --root "$TMP"

# 21. Declared, valid result_loop_contract passes.
write_artifact_rlc "$TMP/artifact-rlc-declared.json" "$RLC_HEAD" 2 0 false false false false 0 '{
    "required": true,
    "selection_source": "declared",
    "selected_result_loop_contract": "web-application",
    "validation_status": "valid",
    "matched_manifest_row": "scripts/enforcement/result-loop-requirements.tsv#web-application",
    "reason": "explicitly declared in PR body; matches one of the 2 candidate contracts implied by changed paths (engineering-os-governance, web-application)."
  }'
CF="$(changed_files templates/web-application/README.md scripts/enforcement/check-known-gaps.sh)"
cat > "$TMP/body-rlc-declared.md" <<'EOF'
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
learning_loop_result: none-with-reason — small scoped change with no reusable lesson
selected_result_loop_contract: web-application
EOF
pass rlc_declared_valid_passes bash "$CHECK" --body "$TMP/body-rlc-declared.md" --head-sha "$RLC_HEAD" \
  --artifact "$TMP/artifact-rlc-declared.json" --changed-files "$CF" --root "$TMP"

# 22. Missing selected_result_loop_contract when required (ambiguous, nothing declared) fails.
write_artifact_rlc "$TMP/artifact-rlc-missing.json" "$RLC_HEAD" 2 0 false false false false 0 '{
    "required": true,
    "selection_source": "ambiguous",
    "selected_result_loop_contract": "",
    "validation_status": "missing",
    "matched_manifest_row": "",
    "reason": "changed paths imply multiple candidate result-loop contracts (engineering-os-governance, web-application) and no selected_result_loop_contract: field was declared under ## Operational Work History Evidence."
  }'
CF="$(changed_files templates/web-application/README.md scripts/enforcement/check-known-gaps.sh)"
failcase rlc_missing_declaration_fails bash "$CHECK" --body "$TMP/body-clean.md" --head-sha "$RLC_HEAD" \
  --artifact "$TMP/artifact-rlc-missing.json" --changed-files "$CF" --root "$TMP"

# 23. Ambiguous contract derivation without explicit selection fails (same underlying
# shape as case 22, tested as its own named case per the required test list).
write_artifact_rlc "$TMP/artifact-rlc-ambiguous.json" "$RLC_HEAD" 2 0 false false false false 0 '{
    "required": true,
    "selection_source": "ambiguous",
    "selected_result_loop_contract": "",
    "validation_status": "missing",
    "matched_manifest_row": "",
    "reason": "changed paths imply multiple candidate result-loop contracts (engineering-os-governance, mobile-application) and no selected_result_loop_contract: field was declared under ## Operational Work History Evidence."
  }'
CF="$(changed_files templates/mobile-application/README.md scripts/enforcement/check-known-gaps.sh)"
failcase rlc_ambiguous_without_selection_fails bash "$CHECK" --body "$TMP/body-clean.md" --head-sha "$RLC_HEAD" \
  --artifact "$TMP/artifact-rlc-ambiguous.json" --changed-files "$CF" --root "$TMP"

# 24. Unknown contract ID fails.
write_artifact_rlc "$TMP/artifact-rlc-unknown.json" "$RLC_HEAD" 2 0 false false false false 0 '{
    "required": true,
    "selection_source": "declared",
    "selected_result_loop_contract": "not-a-real-project-type",
    "validation_status": "unknown_id",
    "matched_manifest_row": "",
    "reason": "declared selected_result_loop_contract '"'"'not-a-real-project-type'"'"' is not a known project_type_id in scripts/enforcement/result-loop-requirements.tsv."
  }'
CF="$(changed_files templates/web-application/README.md scripts/enforcement/check-known-gaps.sh)"
failcase rlc_unknown_id_fails bash "$CHECK" --body "$TMP/body-clean.md" --head-sha "$RLC_HEAD" \
  --artifact "$TMP/artifact-rlc-unknown.json" --changed-files "$CF" --root "$TMP"

# 25. Placeholder contract value fails.
write_artifact_rlc "$TMP/artifact-rlc-placeholder.json" "$RLC_HEAD" 2 0 false false false false 0 '{
    "required": true,
    "selection_source": "declared",
    "selected_result_loop_contract": "tbd",
    "validation_status": "placeholder",
    "matched_manifest_row": "",
    "reason": "declared selected_result_loop_contract '"'"'tbd'"'"' looks like a placeholder; declare a real contract id."
  }'
CF="$(changed_files templates/web-application/README.md scripts/enforcement/check-known-gaps.sh)"
failcase rlc_placeholder_value_fails bash "$CHECK" --body "$TMP/body-clean.md" --head-sha "$RLC_HEAD" \
  --artifact "$TMP/artifact-rlc-placeholder.json" --changed-files "$CF" --root "$TMP"

# 26. Declared value unrelated to the actual diff candidates fails (anti-gaming).
write_artifact_rlc "$TMP/artifact-rlc-unrelated.json" "$RLC_HEAD" 2 0 false false false false 0 '{
    "required": true,
    "selection_source": "declared",
    "selected_result_loop_contract": "cli-tool",
    "validation_status": "invalid",
    "matched_manifest_row": "",
    "reason": "declared selected_result_loop_contract '"'"'cli-tool'"'"' does not match any contract implied by the changed paths (candidates: engineering-os-governance, web-application)."
  }'
CF="$(changed_files templates/web-application/README.md scripts/enforcement/check-known-gaps.sh)"
failcase rlc_declared_unrelated_to_candidates_fails bash "$CHECK" --body "$TMP/body-clean.md" --head-sha "$RLC_HEAD" \
  --artifact "$TMP/artifact-rlc-unrelated.json" --changed-files "$CF" --root "$TMP"

# 27/28. required:false is deliberately NOT checker-level testable through the real
# --changed-files-provided path: Stage 1's pre-existing rule (see test 17,
# empty_changed_files_fails_closed) already fails closed on empty changed-files
# metadata before this script's result_loop_contract block ever runs, and a non-empty
# --changed-files list can never legitimately pair with an empty-run artifact (the
# existing changed-file-count-match check would reject the mismatch first). So
# required:false is only ever genuinely produced by the collector for a true empty
# diff, and only ever validated there — see test-collect-pr-work-history.sh's
# empty_run_marker case, extended to assert result_loop_contract.required is false
# with a concrete reason. This checker's own required:false/else branch is retained
# as defense-in-depth for any future non-pr-policy caller of this script, documented
# here rather than covered by a misleading always-skips fixture.

# 29. Artifact missing the result_loop_contract key entirely fails (stale/pre-upgrade artifact).
cat > "$TMP/artifact-rlc-stale.json" <<JSON
{
  "pr_head_sha": "$RLC_HEAD",
  "changed_files_count": 3,
  "commits_count": 1,
  "empty_run": false,
  "ci_metadata_unavailable": false,
  "review_metadata_unavailable": false,
  "friction_signals": {"any": false, "ci_failures": 0}
}
JSON
CF="$(changed_files src/a.py src/b.py src/c.py)"
failcase rlc_stale_artifact_missing_key_fails bash "$CHECK" --body "$TMP/body-clean.md" --head-sha "$RLC_HEAD" \
  --artifact "$TMP/artifact-rlc-stale.json" --changed-files "$CF" --root "$TMP"

# 30. The artifact includes the selected contract metadata (schema sanity check).
python3 -c "
import json
r = json.load(open('$TMP/artifact-rlc-declared.json'))
rlc = r['result_loop_contract']
assert rlc['selected_result_loop_contract'] == 'web-application', rlc
assert rlc['selection_source'] == 'declared', rlc
assert rlc['validation_status'] == 'valid', rlc
assert rlc['matched_manifest_row'], rlc
assert rlc['reason'], rlc
print('artifact result_loop_contract metadata ok')
"
pass rlc_artifact_includes_metadata true

# 31. The PR body alone cannot override the artifact/checker: an artifact that correctly
# resolved to ambiguous/missing still fails even though the PR body claims a
# plausible-looking value outside the structured field format.
cat > "$TMP/body-prose-override-attempt.md" <<'EOF'
## Operational Work History Evidence

automatic_sources: .engineering-os/work-history/latest.json
learning_loop_result: none-with-reason — small scoped change with no reusable lesson

Note: this PR selects the web-application result loop contract for this change.
EOF
CF="$(changed_files templates/web-application/README.md scripts/enforcement/check-known-gaps.sh)"
failcase rlc_pr_body_prose_cannot_override_missing_artifact bash "$CHECK" --body "$TMP/body-prose-override-attempt.md" --head-sha "$RLC_HEAD" \
  --artifact "$TMP/artifact-rlc-missing.json" --changed-files "$CF" --root "$TMP"

# 32. check-route-plan-contract.sh remains unwired by design: confirmed via repo-wide
# grep that it is referenced only by its own test file, never by a real CI workflow or
# another enforcement script.
REFERENCES="$(grep -rl "check-route-plan-contract" "$ROOT" --include='*.yml' --include='*.yaml' --include='*.sh' 2>/dev/null || true)"
UNEXPECTED="$(printf '%s\n' "$REFERENCES" | { grep -v '/tests/test-required-gates-map.sh$' || true; } | { grep -v '/check-route-plan-contract.sh$' || true; } | { grep -v '/tests/test-operational-work-history-evidence.sh$' || true; } | sed '/^$/d')"
if [ -n "$UNEXPECTED" ]; then
  echo "fail: route_plan_contract_stays_unwired"
  echo "unexpected references: $UNEXPECTED"
  exit 1
fi
echo "ok: route_plan_contract_stays_unwired"

echo "operational work history evidence simulations passed"