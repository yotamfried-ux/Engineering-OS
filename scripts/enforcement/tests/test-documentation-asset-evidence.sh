#!/usr/bin/env bash
# Tests for check-documentation-asset-evidence.sh — the dedicated documentation/
# reference asset evidence gate. Each case builds an isolated branch in a temp git
# repo and asserts the checker's exit code for a base..head range.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-documentation-asset-evidence.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
git init -q
git config user.email test@example.com
git config user.name test
echo base > README.md
git add README.md
git commit -qm base
BASE="$(git rev-parse HEAD)"

ok(){ local n="$1"; shift; "$@" >/dev/null 2>&1 || { echo "fail (expected pass): $n"; "$@" || true; exit 1; }; echo "ok: $n"; }
no(){ local n="$1"; shift; if "$@" >/dev/null 2>&1; then echo "fail (expected fail): $n"; exit 1; else echo "ok: $n"; fi; }

# Writes .claude/plans/doc.md for the requested mode.
mkplan(){
  local mode="$1"
  mkdir -p .claude/plans
  {
    echo '# Route Plan'
    echo
    case "$mode" in
      valid_evidence)
        echo '## Documentation Asset Evidence'
        echo '- internal: core/workflow.md and scripts/enforcement/check-workflow-evidence.sh reviewed.'
        echo '- context7: /vercel/next.js routing docs checked for the external handler behavior.'
        echo '- decision: the internal validator pattern confirmed a dedicated gate is the right approach.'
        ;;
      valid_waiver)
        echo '## Documentation Asset Waiver'
        echo '- reason: this change only touches an isolated test fixture with no reference material to consult.'
        echo '- scope: src/app.js in this fixture branch only.'
        echo '- risk: none beyond the fixture; production documentation governance is unaffected.'
        ;;
      no_section)
        echo '## Source of Truth Checks'
        echo '- core/workflow.md checked.'
        ;;
      missing_internal)
        echo '## Documentation Asset Evidence'
        echo '- context7: /vercel/next.js routing docs checked for the external handler behavior.'
        echo '- decision: the internal validator pattern confirmed a dedicated gate is the right approach.'
        ;;
      missing_context7)
        echo '## Documentation Asset Evidence'
        echo '- internal: core/workflow.md and scripts/enforcement/check-workflow-evidence.sh reviewed.'
        echo '- decision: the internal validator pattern confirmed a dedicated gate is the right approach.'
        ;;
      missing_decision)
        echo '## Documentation Asset Evidence'
        echo '- internal: core/workflow.md and scripts/enforcement/check-workflow-evidence.sh reviewed.'
        echo '- context7: /vercel/next.js routing docs checked for the external handler behavior.'
        ;;
      placeholder)
        echo '## Documentation Asset Evidence'
        echo '- internal: todo'
        echo '- context7: none'
        echo '- decision: tbd'
        ;;
      broad_claim)
        echo '## Documentation Asset Evidence'
        echo '- internal: core/workflow.md and scripts/enforcement/check-workflow-evidence.sh reviewed.'
        echo '- context7: /vercel/next.js routing docs checked for the external handler behavior.'
        echo '- decision: searched everything and reviewed everything relevant before deciding.'
        ;;
      waiver_missing_field)
        echo '## Documentation Asset Waiver'
        echo '- reason: this change only touches an isolated test fixture with no reference material to consult.'
        echo '- scope: src/app.js in this fixture branch only.'
        ;;
      waiver_vague)
        echo '## Documentation Asset Waiver'
        echo '- reason: not needed'
        echo '- scope: none'
        echo '- risk: none'
        ;;
    esac
    echo
  } > .claude/plans/doc.md
}

change(){ mkdir -p src; echo 'console.log("x")' > src/app.js; }

# branch with a plan (given mode) plus a code change, committed as plan-then-code.
run_code_case(){
  local branch="$1" mode="$2"
  git checkout -q -B "$branch" "$BASE"
  mkplan "$mode"; git add .claude/plans/doc.md; git commit -qm plan
  change; git add src/app.js; git commit -qm code
}

# Positive 1: documentation-only change (docs/ file, no code, no plan) passes.
git checkout -q -B docs_only "$BASE"
mkdir -p docs; echo 'note' > docs/note.md; git add docs/note.md; git commit -qm docs
ok doc_asset_docs_only_passes bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"

# Positive 2: code change with valid Documentation Asset Evidence passes.
run_code_case ev_valid valid_evidence
ok doc_asset_evidence_valid_passes bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"

# Positive 3: code change with valid Documentation Asset Waiver passes.
run_code_case wv_valid valid_waiver
ok doc_asset_waiver_valid_passes bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"

# Negative 1: code change with no Route Plan fails.
git checkout -q -B code_no_plan "$BASE"
change; git add src/app.js; git commit -qm code
no doc_asset_code_without_plan_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"

# Negative 2: code change, plan present, but no evidence/waiver section fails.
run_code_case no_ev no_section
no doc_asset_no_evidence_or_waiver_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"

# Negative 3-5: evidence present but missing a required field fails.
run_code_case miss_int missing_internal
no doc_asset_missing_internal_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
run_code_case miss_ctx missing_context7
no doc_asset_missing_context7_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
run_code_case miss_dec missing_decision
no doc_asset_missing_decision_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"

# Negative 6: evidence with placeholder values fails.
run_code_case ph placeholder
no doc_asset_placeholder_values_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"

# Negative 6b: a decision that is only a broad search claim fails.
run_code_case broad broad_claim
no doc_asset_broad_claim_decision_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"

# Negative 7: waiver missing a required field fails.
run_code_case wv_miss waiver_missing_field
no doc_asset_waiver_missing_field_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"

# Negative 8: waiver with vague/placeholder values fails.
run_code_case wv_vague waiver_vague
no doc_asset_waiver_vague_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"

echo "all documentation asset evidence tests passed"
