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

make_repo() {
  local dir="$1"
  mkdir -p "$dir/core" "$dir/docs/operations" "$dir/external-systems" "$dir/external-skills"
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
| `core/` | Canonical policies; the live inventory is the directory itself. |
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

CORE_COUNT="$TMP/core-count"; cp -R "$GOOD" "$CORE_COUNT"
python3 - "$CORE_COUNT/README.md" <<'PY'
from pathlib import Path
p = Path(__import__('sys').argv[1])
p.write_text(p.read_text().replace('Canonical policies; the live inventory is the directory itself.', '14 policy files.'))
PY

SYSTEM_COUNT="$TMP/system-count"; cp -R "$GOOD" "$SYSTEM_COUNT"
python3 - "$SYSTEM_COUNT/README.md" <<'PY'
from pathlib import Path
p = Path(__import__('sys').argv[1])
p.write_text(p.read_text().replace('Service guides; the live inventory is `external-systems/README.md`.', '47 third-party service guides.'))
PY

UNCONDITIONAL_REVIEW="$TMP/unconditional-review"; cp -R "$GOOD" "$UNCONDITIONAL_REVIEW"
cat > "$UNCONDITIONAL_REVIEW/core/coderabbit-policy.md" <<'MD'
# CodeRabbit policy

1. Open a PR.
2. Wait for Actions.
3. Prepare evidence.
4. Wait for CodeRabbit review.

- [ ] CodeRabbit reviewed
MD

MISSING_FALLBACK="$TMP/missing-fallback"; cp -R "$GOOD" "$MISSING_FALLBACK"
cat > "$MISSING_FALLBACK/core/coderabbit-policy.md" <<'MD'
# CodeRabbit policy

Inspect live reviewer availability and status for the exact pull-request head.
Do not claim that CodeRabbit reviewed when no current review exists.
MD

STATIC_AVAILABILITY="$TMP/static-availability"; cp -R "$GOOD" "$STATIC_AVAILABILITY"
printf '\nCodeRabbit is not connected.\n' >> "$STATIC_AVAILABILITY/CLAUDE.md"

expect_pass current_manifest_passes bash "$CHECK" --root "$ROOT" --manifest "$ROOT/docs/operations/documentation-ownership.tsv"
expect_pass good_fixture_passes bash "$CHECK" --root "$GOOD" --manifest "$GOOD/docs/operations/documentation-ownership.tsv"
expect_fail duplicate_scope_fails bash "$CHECK" --root "$DUP" --manifest "$DUP/docs/operations/documentation-ownership.tsv"
expect_fail invalid_status_without_replacement_fails bash "$CHECK" --root "$BADSTATUS" --manifest "$BADSTATUS/docs/operations/documentation-ownership.tsv"
expect_fail missing_path_fails bash "$CHECK" --root "$BADPATH" --manifest "$BADPATH/docs/operations/documentation-ownership.tsv"
expect_fail waiver_requires_allow_flag bash "$CHECK" --root "$WAIVER" --manifest "$WAIVER/docs/operations/documentation-ownership.tsv"
expect_pass explicit_waiver_passes bash "$CHECK" --root "$WAIVER" --manifest "$WAIVER/docs/operations/documentation-ownership.tsv" --allow-waiver
expect_fail stale_runtime_scope_fails bash "$CHECK" --root "$STALE_RUNTIME" --manifest "$STALE_RUNTIME/docs/operations/documentation-ownership.tsv"
expect_fail core_inventory_count_fails bash "$CHECK" --root "$CORE_COUNT" --manifest "$CORE_COUNT/docs/operations/documentation-ownership.tsv"
expect_fail system_inventory_count_fails bash "$CHECK" --root "$SYSTEM_COUNT" --manifest "$SYSTEM_COUNT/docs/operations/documentation-ownership.tsv"
expect_fail unconditional_coderabbit_path_fails bash "$CHECK" --root "$UNCONDITIONAL_REVIEW" --manifest "$UNCONDITIONAL_REVIEW/docs/operations/documentation-ownership.tsv"
expect_fail missing_review_fallback_fails bash "$CHECK" --root "$MISSING_FALLBACK" --manifest "$MISSING_FALLBACK/docs/operations/documentation-ownership.tsv"
expect_fail static_coderabbit_availability_fails bash "$CHECK" --root "$STATIC_AVAILABILITY" --manifest "$STATIC_AVAILABILITY/docs/operations/documentation-ownership.tsv"

echo "documentation hygiene tests passed"
