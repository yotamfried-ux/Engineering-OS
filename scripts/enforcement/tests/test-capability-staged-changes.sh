#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-capability-staged-changes.sh"
chmod +x "$CHECK"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG_FILE="$TMP/staged.log"

pass() { local name="$1"; shift; "$@" >"$LOG_FILE" 2>&1 || { echo "fail: $name"; cat "$LOG_FILE"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$LOG_FILE" 2>&1; then echo "unexpected pass: $name"; cat "$LOG_FILE"; exit 1; else echo "ok: $name"; fi; }

write_plan() {
  local path="$1" evidence="$2" waiver="${3:-}"
  cat > "$path" <<EOF
# Route Plan

| Field | Value |
|---|---|
| Task class | engineering_os_governance |

## Capability Evidence

$evidence
EOF
  if [ -n "$waiver" ]; then
    cat >> "$path" <<EOF

## Capability Waiver

$waiver
EOF
  fi
}

pass checker_present test -f "$CHECK"

# positive: enforcement change with declared validator capability passes.
printf 'scripts/enforcement/check-foo.sh\n' > "$TMP/files-enforcement.txt"
write_plan "$TMP/plan-good.md" '- `validation.policy-change-has-validator` — checker added with tests.'
pass declared_implied_capability_passes bash "$CHECK" --files-from "$TMP/files-enforcement.txt" --plan "$TMP/plan-good.md"

# negative: enforcement change whose plan omits the implied capability fails.
write_plan "$TMP/plan-miss.md" '- `routing.task-router-read` — routed.'
failcase missing_implied_capability_fails bash "$CHECK" --files-from "$TMP/files-enforcement.txt" --plan "$TMP/plan-miss.md"

# waiver: implied capability listed in Capability Waiver passes.
write_plan "$TMP/plan-waived.md" '- `routing.task-router-read` — routed.' '- `validation.policy-change-has-validator` — not required because this fixture change is a comment-only edit.'
pass waived_implied_capability_passes bash "$CHECK" --files-from "$TMP/files-enforcement.txt" --plan "$TMP/plan-waived.md"

# irrelevant path: no implied capability, no plan needed.
printf 'docs/README.md\nsrc/app.ts\n' > "$TMP/files-none.txt"
pass irrelevant_paths_are_noop bash "$CHECK" --files-from "$TMP/files-none.txt"

# workflow change implies actions-checked.
printf '.github/workflows/ci.yml\n' > "$TMP/files-workflow.txt"
write_plan "$TMP/plan-actions.md" '- `validation.actions-checked` — CI results verified for the head SHA.'
pass workflow_change_with_actions_capability_passes bash "$CHECK" --files-from "$TMP/files-workflow.txt" --plan "$TMP/plan-actions.md"
failcase workflow_change_without_actions_capability_fails bash "$CHECK" --files-from "$TMP/files-workflow.txt" --plan "$TMP/plan-good.md"

# no changed plan at all fails closed when capabilities are implied.
failcase implied_capability_without_any_plan_fails bash "$CHECK" --files-from "$TMP/files-enforcement.txt"

# malformed map: unknown capability id fails closed.
printf 'scripts/enforcement/\tvalidation.no-such-capability\n' > "$TMP/bad-map.tsv"
failcase stale_map_capability_fails bash "$CHECK" --files-from "$TMP/files-enforcement.txt" --plan "$TMP/plan-good.md" --map "$TMP/bad-map.tsv"

# malformed map: wrong column count fails closed.
printf 'scripts/enforcement/\n' > "$TMP/short-map.tsv"
failcase malformed_map_row_fails bash "$CHECK" --files-from "$TMP/files-enforcement.txt" --plan "$TMP/plan-good.md" --map "$TMP/short-map.tsv"

# stale declared capability (declared but nothing implies it) does NOT fail by design.
write_plan "$TMP/plan-extra.md" '- `validation.policy-change-has-validator` — checker added.
- `skill.graphify` — declared but unrelated to the change.'
pass stale_declared_capability_is_not_failed bash "$CHECK" --files-from "$TMP/files-enforcement.txt" --plan "$TMP/plan-extra.md"

echo "capability staged-change simulations passed"
