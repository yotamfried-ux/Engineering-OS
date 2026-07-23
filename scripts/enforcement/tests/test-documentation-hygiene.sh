#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-documentation-hygiene.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

expect_pass() {
  local name="$1"; shift
  if "$@" >"$TMP/$name.out" 2>&1; then
    echo "ok: $name"
  else
    echo "expected pass: $name"
    cat "$TMP/$name.out"
    exit 1
  fi
}

expect_fail() {
  local name="$1"; shift
  if "$@" >"$TMP/$name.out" 2>&1; then
    echo "unexpected pass: $name"
    cat "$TMP/$name.out"
    exit 1
  else
    echo "ok: $name"
  fi
}

expect_fail_contains() {
  local name="$1" expected="$2"; shift 2
  expect_fail "$name" "$@"
  if ! grep -Fq "$expected" "$TMP/$name.out"; then
    echo "failure output for $name did not contain: $expected"
    cat "$TMP/$name.out"
    exit 1
  fi
}

make_repo() {
  local dir="$1"
  mkdir -p "$dir/core" "$dir/docs/operations" "$dir/external-systems" "$dir/external-skills" "$dir/scripts/enforcement" "$dir/scripts/monitoring"
  cat > "$dir/CLAUDE.md" <<'MD'
# CLAUDE

Engineering OS review uses a live CodeRabbit status check and a structured fallback when the reviewer is unavailable.

| File | Purpose | Enforcer |
|---|---|---|
| `core/capability-registry.yaml` | capabilities | active plan-level write gate |
MD
  cat > "$dir/README.md" <<'MD'
# Engineering OS

| Directory | Purpose |
|---|---|
| `core/` | Canonical policies; the live inventory is the navigation table in `CLAUDE.md`. |
| `patterns/` | Pattern domains; lifecycle metadata is in `patterns/registry.yaml`. |
| `external-skills/` | Skill wrappers; the live inventory is `external-skills/README.md`. |
| `external-systems/` | Service guides; the live inventory is `external-systems/README.md`. |
MD
  printf '# workflow\n## <workflow>\n' > "$dir/core/workflow.md"
  printf '# task router\n## <routing_algorithm>\n## <routing_matrix>\n' > "$dir/core/task-router.md"
  printf '# documentation\n## <canonical_ownership>\n' > "$dir/core/documentation-policy.md"
  cat > "$dir/core/capability-registry.yaml" <<'YAML'
version: 1
runtime_enabled: true
runtime_scope: plan_level_write_gate
YAML
  cat > "$dir/scripts/enforcement/MANIFEST.tsv" <<'TSV'
core/capability-registry.yaml	scripts/enforcement/tests/test-capability-registry.sh	active plan-level write gate
TSV
  cat > "$dir/docs/operations/project8-telemetry-preflight.md" <<'MD'
# Telemetry preflight

The first-run monitoring usefulness decision is complete after one imported run.
A later second valid run is required for longitudinal comparison, but it does not block the first experiment.
MD
  cat > "$dir/docs/operations/runtime-telemetry-archive-plan.md" <<'MD'
# Runtime telemetry archive plan

Monitoring longitudinally sufficient means at least two valid runs were compared reproducibly.
MD
  cat > "$dir/docs/operations/runtime-telemetry-archive-audit-checklist.md" <<'MD'
# Runtime telemetry archive audit checklist

Track implementation, first-run evidence, and later longitudinal learning as three separate layers.
- [ ] `monitoring-metrics-sufficiency` is closed from the imported and analyzed first run.
- [ ] `monitoring-longitudinal-sufficiency` is backed by reviewed multi-run evidence.
MD
  cat > "$dir/scripts/monitoring/analyze-telemetry-archive.py" <<'PY'
"""Telemetry archive analyzer."""
# longitudinal comparison: pending at least two runs
PY
  cat > "$dir/core/coderabbit-policy.md" <<'MD'
# CodeRabbit policy

Inspect the live reviewer availability and status for the exact pull-request head.
When CodeRabbit is unavailable, record structured Review Fallback Evidence and perform an exact-head self-review.
Do not claim that CodeRabbit reviewed when no current review exists.
MD
  for f in connector-policy.md skill-orchestration-policy.md hooks-policy.md quality-gates.md git-policy.md learning-loop.md; do
    echo "# $f" > "$dir/core/$f"
  done
  echo '# systems' > "$dir/external-systems/README.md"
  echo '# skills' > "$dir/external-skills/README.md"
  echo '# docs' > "$dir/docs/README.md"
  echo '# audit' > "$dir/docs/operations/operational-readiness-audit.md"
  cat > "$dir/docs/operations/documentation-ownership.tsv" <<'TSV'
entrypoint	core-governance	CLAUDE.md	active	Entry point.
workflow-order	workflow-governance	core/workflow.md	active	Workflow owner.
task-routing	workflow-governance	core/task-router.md	active	Routing owner.
documentation-hygiene	docs-governance	core/documentation-policy.md	active	Documentation owner.
capability-vocabulary	capability-governance	core/capability-registry.yaml	active	Capability owner.
connector-policy	connector-governance	core/connector-policy.md	active	Connector owner.
skill-policy	skill-governance	core/skill-orchestration-policy.md	active	Skill owner.
hooks-policy	hooks-governance	core/hooks-policy.md	active	Hooks owner.
quality-gates	validation-governance	core/quality-gates.md	active	Quality owner.
git-policy	merge-governance	core/git-policy.md	active	Git owner.
learning-loop	learning-governance	core/learning-loop.md	active	Learning owner.
docs-index	docs-governance	docs/README.md	active	Docs index.
operational-readiness-audit	ops-readiness	docs/operations/operational-readiness-audit.md	active	Audit owner.
TSV
}

GOOD="$TMP/good"; make_repo "$GOOD"
DUP="$TMP/duplicate"; cp -R "$GOOD" "$DUP"; printf 'workflow-order\tother\tcore/workflow.md\tactive\tDuplicate scope.\n' >> "$DUP/docs/operations/documentation-ownership.tsv"
BADSTATUS="$TMP/badstatus"; cp -R "$GOOD" "$BADSTATUS"; printf 'old-doc\tdocs-governance\tdocs/operations/missing.md\tdeprecated\tNo replacement named.\n' >> "$BADSTATUS/docs/operations/documentation-ownership.tsv"
BADPATH="$TMP/badpath"; cp -R "$GOOD" "$BADPATH"; printf 'missing-doc\tdocs-governance\tdocs/operations/missing.md\tactive\tMissing path.\n' >> "$BADPATH/docs/operations/documentation-ownership.tsv"
WAIVER="$TMP/waiver"; cp -R "$GOOD" "$WAIVER"; printf 'temporary-waiver\tdocs-governance\tdocs/operations/missing.md\twaived\tThis waiver is intentionally long enough for a temporary documentation migration gap.\n' >> "$WAIVER/docs/operations/documentation-ownership.tsv"

STALE_RUNTIME="$TMP/stale-runtime"; cp -R "$GOOD" "$STALE_RUNTIME"
python3 - "$STALE_RUNTIME/CLAUDE.md" <<'PY'
from pathlib import Path
p = Path(__import__('sys').argv[1])
p.write_text(p.read_text().replace('active plan-level write gate', 'runtime planned'))
PY

DISABLED_RUNTIME="$TMP/disabled-runtime"; cp -R "$GOOD" "$DISABLED_RUNTIME"
sed -i 's/runtime_enabled: true/runtime_enabled: false/' "$DISABLED_RUNTIME/core/capability-registry.yaml"

CHANGED_SCOPE="$TMP/changed-scope"; cp -R "$GOOD" "$CHANGED_SCOPE"
sed -i 's/runtime_scope: plan_level_write_gate/runtime_scope: report_only/' "$CHANGED_SCOPE/core/capability-registry.yaml"

MANIFEST_STALE="$TMP/manifest-stale"; cp -R "$GOOD" "$MANIFEST_STALE"
cat > "$MANIFEST_STALE/scripts/enforcement/MANIFEST.tsv" <<'TSV'
core/capability-registry.yaml	NONE	skeleton capability vocabulary — non-runtime, no enforcer yet
TSV

MANIFEST_OVERCLAIM="$TMP/manifest-overclaim"; cp -R "$GOOD" "$MANIFEST_OVERCLAIM"
sed -i 's/runtime_enabled: true/runtime_enabled: false/' "$MANIFEST_OVERCLAIM/core/capability-registry.yaml"

MANIFEST_MISSING_ROW="$TMP/manifest-missing-row"; cp -R "$GOOD" "$MANIFEST_MISSING_ROW"
: > "$MANIFEST_MISSING_ROW/scripts/enforcement/MANIFEST.tsv"

TELEMETRY_LONGITUDINAL_UNSUPPORTED="$TMP/telemetry-longitudinal-unsupported"; cp -R "$GOOD" "$TELEMETRY_LONGITUDINAL_UNSUPPORTED"
cat > "$TELEMETRY_LONGITUDINAL_UNSUPPORTED/docs/operations/runtime-telemetry-archive-plan.md" <<'MD'
# Runtime telemetry archive plan

The import of one qualification run makes monitoring longitudinally sufficient.
MD

TELEMETRY_LONGITUDINAL_ID_UNSUPPORTED="$TMP/telemetry-longitudinal-id-unsupported"; cp -R "$GOOD" "$TELEMETRY_LONGITUDINAL_ID_UNSUPPORTED"
cat > "$TELEMETRY_LONGITUDINAL_ID_UNSUPPORTED/docs/operations/runtime-telemetry-archive-audit-checklist.md" <<'MD'
# Runtime telemetry archive audit checklist

- [x] `monitoring-longitudinal-sufficiency` is closed from the imported first run.
MD

TELEMETRY_FIRST_RUN_OVERREACH="$TMP/telemetry-first-run-overreach"; cp -R "$GOOD" "$TELEMETRY_FIRST_RUN_OVERREACH"
cat > "$TELEMETRY_FIRST_RUN_OVERREACH/docs/operations/project8-telemetry-preflight.md" <<'MD'
# Telemetry preflight

The first-run monitoring usefulness decision requires a second run before it is complete.
MD

TELEMETRY_METRICS_ID_OVERREACH="$TMP/telemetry-metrics-id-overreach"; cp -R "$GOOD" "$TELEMETRY_METRICS_ID_OVERREACH"
cat > "$TELEMETRY_METRICS_ID_OVERREACH/docs/operations/runtime-telemetry-archive-plan.md" <<'MD'
# Runtime telemetry archive plan

Closing `monitoring-metrics-sufficiency` requires a second run before it counts.
MD

TELEMETRY_SEPARATE_CLAUSES_PASS="$TMP/telemetry-separate-clauses-pass"; cp -R "$GOOD" "$TELEMETRY_SEPARATE_CLAUSES_PASS"
cat > "$TELEMETRY_SEPARATE_CLAUSES_PASS/docs/operations/project8-telemetry-preflight.md" <<'MD'
# Telemetry preflight

First-run monitoring usefulness is complete. Longitudinal sufficiency requires a second run.
MD

CORE_COUNT="$TMP/core-count"; cp -R "$GOOD" "$CORE_COUNT"
python3 - "$CORE_COUNT/README.md" <<'PY'
from pathlib import Path
p = Path(__import__('sys').argv[1])
p.write_text(p.read_text().replace('Canonical policies; the live inventory is the navigation table in `CLAUDE.md`.', '14 policy files; inventory is in `CLAUDE.md`.'))
PY

SYSTEM_COUNT="$TMP/system-count"; cp -R "$GOOD" "$SYSTEM_COUNT"
python3 - "$SYSTEM_COUNT/README.md" <<'PY'
from pathlib import Path
p = Path(__import__('sys').argv[1])
p.write_text(p.read_text().replace('Service guides; the live inventory is `external-systems/README.md`.', '47 third-party service guides; see `external-systems/README.md`.'))
PY

VERSION_NUMERAL="$TMP/version-numeral"; cp -R "$GOOD" "$VERSION_NUMERAL"
python3 - "$VERSION_NUMERAL/README.md" <<'PY'
from pathlib import Path
p = Path(__import__('sys').argv[1])
p.write_text(p.read_text().replace('Pattern domains;', 'Pattern domains including OAuth 2 integrations;'))
PY

MISSING_INVENTORY_REFERENCE="$TMP/missing-inventory-reference"; cp -R "$GOOD" "$MISSING_INVENTORY_REFERENCE"
python3 - "$MISSING_INVENTORY_REFERENCE/README.md" <<'PY'
from pathlib import Path
p = Path(__import__('sys').argv[1])
p.write_text(p.read_text().replace('Service guides; the live inventory is `external-systems/README.md`.', 'Service integration documentation.'))
PY

UNCONDITIONAL_REVIEW="$TMP/unconditional-review"; cp -R "$GOOD" "$UNCONDITIONAL_REVIEW"
cat >> "$UNCONDITIONAL_REVIEW/core/coderabbit-policy.md" <<'MD'

4. Wait for CodeRabbit review.
- [ ] CodeRabbit reviewed
MD

MISSING_FALLBACK="$TMP/missing-fallback"; cp -R "$GOOD" "$MISSING_FALLBACK"
cat > "$MISSING_FALLBACK/core/coderabbit-policy.md" <<'MD'
# CodeRabbit policy

Inspect live reviewer availability and status for the exact pull-request head.
Do not claim that CodeRabbit reviewed when no current review exists.
MD

MISSING_POLICY="$TMP/missing-policy"; cp -R "$GOOD" "$MISSING_POLICY"
rm "$MISSING_POLICY/core/coderabbit-policy.md"

STATIC_AVAILABILITY="$TMP/static-availability"; cp -R "$GOOD" "$STATIC_AVAILABILITY"
printf '\nCodeRabbit is not connected.\n' >> "$STATIC_AVAILABILITY/CLAUDE.md"

STATIC_DISCONNECTED="$TMP/static-disconnected"; cp -R "$GOOD" "$STATIC_DISCONNECTED"
printf '\nCodeRabbit is disconnected.\n' >> "$STATIC_DISCONNECTED/CLAUDE.md"

STATIC_CONTRACTION="$TMP/static-contraction"; cp -R "$GOOD" "$STATIC_CONTRACTION"
printf "\nCodeRabbit isn't connected.\n" >> "$STATIC_CONTRACTION/CLAUDE.md"

expect_pass current_manifest_passes bash "$CHECK" --root "$ROOT" --manifest "$ROOT/docs/operations/documentation-ownership.tsv"
expect_pass good_fixture_passes bash "$CHECK" --root "$GOOD" --manifest "$GOOD/docs/operations/documentation-ownership.tsv"
expect_fail duplicate_scope_fails bash "$CHECK" --root "$DUP" --manifest "$DUP/docs/operations/documentation-ownership.tsv"
expect_fail invalid_status_without_replacement_fails bash "$CHECK" --root "$BADSTATUS" --manifest "$BADSTATUS/docs/operations/documentation-ownership.tsv"
expect_fail missing_path_fails bash "$CHECK" --root "$BADPATH" --manifest "$BADPATH/docs/operations/documentation-ownership.tsv"
expect_fail waiver_requires_allow_flag bash "$CHECK" --root "$WAIVER" --manifest "$WAIVER/docs/operations/documentation-ownership.tsv"
expect_pass explicit_waiver_passes bash "$CHECK" --root "$WAIVER" --manifest "$WAIVER/docs/operations/documentation-ownership.tsv" --allow-waiver
expect_fail_contains stale_runtime_scope_fails 'runtime planned' bash "$CHECK" --root "$STALE_RUNTIME" --manifest "$STALE_RUNTIME/docs/operations/documentation-ownership.tsv"
expect_fail_contains disabled_runtime_rejects_active_wording 'describes an active plan-level write gate' bash "$CHECK" --root "$DISABLED_RUNTIME" --manifest "$DISABLED_RUNTIME/docs/operations/documentation-ownership.tsv"
expect_fail_contains changed_scope_rejects_active_wording 'describes an active plan-level write gate' bash "$CHECK" --root "$CHANGED_SCOPE" --manifest "$CHANGED_SCOPE/docs/operations/documentation-ownership.tsv"
expect_fail_contains manifest_stale_rejects_non_runtime_wording 'NONE/non-runtime' bash "$CHECK" --root "$MANIFEST_STALE" --manifest "$MANIFEST_STALE/docs/operations/documentation-ownership.tsv"
expect_fail_contains manifest_overclaim_rejects_active_enforcer 'claims an active enforcer' bash "$CHECK" --root "$MANIFEST_OVERCLAIM" --manifest "$MANIFEST_OVERCLAIM/docs/operations/documentation-ownership.tsv"
expect_fail_contains manifest_missing_row_fails 'must declare core/capability-registry.yaml' bash "$CHECK" --root "$MANIFEST_MISSING_ROW" --manifest "$MANIFEST_MISSING_ROW/docs/operations/documentation-ownership.tsv"
expect_fail_contains telemetry_longitudinal_unsupported_fails 'not backed by an explicit multi-run requirement' bash "$CHECK" --root "$TELEMETRY_LONGITUDINAL_UNSUPPORTED" --manifest "$TELEMETRY_LONGITUDINAL_UNSUPPORTED/docs/operations/documentation-ownership.tsv"
expect_fail_contains telemetry_longitudinal_id_unsupported_fails 'not backed by an explicit multi-run requirement' bash "$CHECK" --root "$TELEMETRY_LONGITUDINAL_ID_UNSUPPORTED" --manifest "$TELEMETRY_LONGITUDINAL_ID_UNSUPPORTED/docs/operations/documentation-ownership.tsv"
expect_fail_contains telemetry_first_run_overreach_fails 'incorrectly demands a second run' bash "$CHECK" --root "$TELEMETRY_FIRST_RUN_OVERREACH" --manifest "$TELEMETRY_FIRST_RUN_OVERREACH/docs/operations/documentation-ownership.tsv"
expect_fail_contains telemetry_metrics_id_overreach_fails 'incorrectly demands a second run' bash "$CHECK" --root "$TELEMETRY_METRICS_ID_OVERREACH" --manifest "$TELEMETRY_METRICS_ID_OVERREACH/docs/operations/documentation-ownership.tsv"
expect_pass telemetry_separate_clauses_pass bash "$CHECK" --root "$TELEMETRY_SEPARATE_CLAUSES_PASS" --manifest "$TELEMETRY_SEPARATE_CLAUSES_PASS/docs/operations/documentation-ownership.tsv"
expect_fail_contains core_inventory_count_fails 'volatile numeric inventory count' bash "$CHECK" --root "$CORE_COUNT" --manifest "$CORE_COUNT/docs/operations/documentation-ownership.tsv"
expect_fail_contains system_inventory_count_fails 'volatile numeric inventory count' bash "$CHECK" --root "$SYSTEM_COUNT" --manifest "$SYSTEM_COUNT/docs/operations/documentation-ownership.tsv"
expect_pass version_numeral_is_not_inventory_count bash "$CHECK" --root "$VERSION_NUMERAL" --manifest "$VERSION_NUMERAL/docs/operations/documentation-ownership.tsv"
expect_fail_contains missing_inventory_reference_fails 'must reference canonical inventory' bash "$CHECK" --root "$MISSING_INVENTORY_REFERENCE" --manifest "$MISSING_INVENTORY_REFERENCE/docs/operations/documentation-ownership.tsv"
expect_fail_contains unconditional_coderabbit_path_fails 'unconditional CodeRabbit waiting' bash "$CHECK" --root "$UNCONDITIONAL_REVIEW" --manifest "$UNCONDITIONAL_REVIEW/docs/operations/documentation-ownership.tsv"
expect_fail_contains missing_review_fallback_fails 'structured Review Fallback Evidence' bash "$CHECK" --root "$MISSING_FALLBACK" --manifest "$MISSING_FALLBACK/docs/operations/documentation-ownership.tsv"
expect_fail_contains missing_coderabbit_policy_fails 'core/coderabbit-policy.md is required' bash "$CHECK" --root "$MISSING_POLICY" --manifest "$MISSING_POLICY/docs/operations/documentation-ownership.tsv"
expect_fail_contains static_coderabbit_availability_fails 'static CodeRabbit availability claim' bash "$CHECK" --root "$STATIC_AVAILABILITY" --manifest "$STATIC_AVAILABILITY/docs/operations/documentation-ownership.tsv"
expect_fail_contains disconnected_coderabbit_availability_fails 'static CodeRabbit availability claim' bash "$CHECK" --root "$STATIC_DISCONNECTED" --manifest "$STATIC_DISCONNECTED/docs/operations/documentation-ownership.tsv"
expect_fail_contains contraction_coderabbit_availability_fails 'static CodeRabbit availability claim' bash "$CHECK" --root "$STATIC_CONTRACTION" --manifest "$STATIC_CONTRACTION/docs/operations/documentation-ownership.tsv"

echo "documentation hygiene tests passed"
