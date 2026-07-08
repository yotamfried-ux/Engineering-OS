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

write_artifact() {
  local path="$1" head_sha="$2" changed="$3" commits="$4" empty_run="$5" ci_unavail="$6" review_unavail="$7" friction_any="$8" ci_failures="$9"
  mkdir -p "$(dirname "$path")"
  cat > "$path" <<JSON
{
  "pr_head_sha": "$head_sha",
  "changed_files_count": $changed,
  "commits_count": $commits,
  "empty_run": $empty_run,
  "ci_metadata_unavailable": $ci_unavail,
  "review_metadata_unavailable": $review_unavail,
  "friction_signals": {"any": $friction_any, "ci_failures": $ci_failures}
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

echo "operational work history evidence simulations passed"