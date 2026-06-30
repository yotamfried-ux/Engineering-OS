#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-documentation-hygiene.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

expect_pass() { local name="$1"; shift; if "$@" >"$TMP/$name.out" 2>&1; then echo "ok: $name"; else echo "expected pass: $name"; cat "$TMP/$name.out"; exit 1; fi; }
expect_fail() { local name="$1"; shift; if "$@" >"$TMP/$name.out" 2>&1; then echo "unexpected pass: $name"; cat "$TMP/$name.out"; exit 1; else echo "ok: $name"; fi; }

make_repo() {
  local dir="$1"
  mkdir -p "$dir/core" "$dir/docs/operations" "$dir/external-systems" "$dir/external-skills"
  echo '# CLAUDE' > "$dir/CLAUDE.md"
  printf '# workflow\n## <workflow>\n' > "$dir/core/workflow.md"
  printf '# task router\n## <routing_algorithm>\n## <routing_matrix>\n' > "$dir/core/task-router.md"
  printf '# documentation\n## <canonical_ownership>\n' > "$dir/core/documentation-policy.md"
  echo 'version: 1' > "$dir/core/capability-registry.yaml"
  for f in connector-policy.md skill-orchestration-policy.md hooks-policy.md quality-gates.md git-policy.md learning-loop.md; do echo "# $f" > "$dir/core/$f"; done
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

expect_pass current_manifest_passes bash "$CHECK" --root "$ROOT" --manifest "$ROOT/docs/operations/documentation-ownership.tsv"
expect_pass good_fixture_passes bash "$CHECK" --root "$GOOD" --manifest "$GOOD/docs/operations/documentation-ownership.tsv"
expect_fail duplicate_scope_fails bash "$CHECK" --root "$DUP" --manifest "$DUP/docs/operations/documentation-ownership.tsv"
expect_fail invalid_status_without_replacement_fails bash "$CHECK" --root "$BADSTATUS" --manifest "$BADSTATUS/docs/operations/documentation-ownership.tsv"
expect_fail missing_path_fails bash "$CHECK" --root "$BADPATH" --manifest "$BADPATH/docs/operations/documentation-ownership.tsv"
expect_fail waiver_requires_allow_flag bash "$CHECK" --root "$WAIVER" --manifest "$WAIVER/docs/operations/documentation-ownership.tsv"
expect_pass explicit_waiver_passes bash "$CHECK" --root "$WAIVER" --manifest "$WAIVER/docs/operations/documentation-ownership.tsv" --allow-waiver

echo "documentation hygiene tests passed"
