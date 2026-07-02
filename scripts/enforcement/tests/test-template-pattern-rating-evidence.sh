#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-workflow-evidence.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
git init -q
git config user.email test@example.com
git config user.name test
echo base > README.md
git add README.md
git commit -qm base
BASE="$(git rev-parse HEAD)"
progress(){ case "$1" in start) echo '- start: plan first.';; mid) echo '- start: plan first.'; echo '- mid: fixture executed after code began.';; *) echo '- start: plan first.'; echo '- mid: fixture executed after code began.'; echo '- pre-merge: final fixture check recorded after code.';; esac; }
patterns_for(){ case "$1" in partial|multi) echo 'patterns/security/README.md, patterns/api/README.md';; *) echo 'patterns/security/README.md';; esac; }
mkplan(){ local mode="$1" step="$2"; local patterns; patterns="$(patterns_for "$mode")"; cat > .claude/plans/rating.md <<PLAN
# Route Plan
| Field | Value |
|---|---|
| Task class | code_change |
| Domain tags | api, reuse |
| Target paths | src/app.js |
| Templates | not required |
| Patterns | $patterns |
| External systems/connectors | github |
| Skills | superpowers |
| Validation gates | workflow-evidence-policy, enforcement-tests |
| Task-router evidence | read |
| Workflow evidence | read |

## DoD

- [x] fixture verified by this suite checker run.

## Source of Truth Checks
| Source | Status |
|---|---|
| core/workflow.md | checked |
| src/app.js | checked |

## Skill Evidence
- superpowers

PLAN
case "$mode" in
  allow)
    cat >> .claude/plans/rating.md <<'PLAN'
## Template/Pattern Rating Waiver

Rating evidence is waived because this isolated fixture has no real reusable asset outcome yet.

PLAN
    ;;
  missing)
    ;;
  invalid)
    cat >> .claude/plans/rating.md <<'PLAN'
## Template/Pattern Rating Evidence
- asset: patterns/security/README.md
- rating: 4 after fixture use.
- outcome: rating fixture reused the pattern successfully.
- decision: keep this pattern preferred for matching changes.

PLAN
    ;;
  wrong)
    cat >> .claude/plans/rating.md <<'PLAN'
## Template/Pattern Rating Evidence
- asset: patterns/infrastructure/README.md
- rating: 4 after fixture use.
- confidence: medium because the fixture has direct target evidence.
- outcome: rating fixture reused the pattern successfully.
- decision: keep this pattern preferred for matching changes.

PLAN
    ;;
  extra)
    cat >> .claude/plans/rating.md <<'PLAN'
## Template/Pattern Rating Evidence
- asset: patterns/security/README.md, patterns/infrastructure/README.md
- rating: 4 after fixture use.
- confidence: medium because the fixture has direct target evidence.
- outcome: rating fixture reused the pattern successfully.
- decision: keep this pattern preferred for matching changes.

PLAN
    ;;
  partial)
    cat >> .claude/plans/rating.md <<'PLAN'
## Template/Pattern Rating Evidence
- asset: patterns/security/README.md
- rating: 4 after fixture use.
- confidence: medium because the fixture has direct target evidence.
- outcome: rating fixture reused the pattern successfully.
- decision: keep this pattern preferred for matching changes.

PLAN
    ;;
  multi)
    cat >> .claude/plans/rating.md <<'PLAN'
## Template/Pattern Rating Evidence
- asset: patterns/security/README.md, patterns/api/README.md
- rating: 4 after fixture use.
- confidence: medium because the fixture has direct target evidence.
- outcome: rating fixture reused both declared patterns successfully.
- decision: keep these patterns preferred for matching changes.

PLAN
    ;;
  *)
    cat >> .claude/plans/rating.md <<'PLAN'
## Template/Pattern Rating Evidence
- asset: patterns/security/README.md
- rating: 4 after fixture use.
- confidence: medium because the fixture has direct target evidence.
- outcome: rating fixture reused the pattern successfully.
- decision: keep this pattern preferred for matching changes.

PLAN
    ;;
esac
printf '%s
' '## Progress Lifecycle Evidence' '' >> .claude/plans/rating.md
progress "$step" >> .claude/plans/rating.md
printf '%s
' '' '## Claude Run Trace' '- goal: rating fixture.' >> .claude/plans/rating.md
}
change(){ mkdir -p .claude/plans src; echo 'console.log("x")' > src/app.js; }
ok(){ local n="$1"; shift; "$@" >/dev/null || { echo "fail: $n"; exit 1; }; echo "ok: $n"; }
no(){ local n="$1"; shift; if "$@" >/dev/null 2>&1; then echo "unexpected pass: $n"; exit 1; else echo "ok: $n"; fi; }
run_case(){ local branch="$1" mode="$2"; git checkout -q -B "$branch" "$BASE"; mkdir -p .claude/plans src; mkplan "$mode" start; git add .claude/plans/rating.md; git commit -qm plan-start; change; git add src/app.js; git commit -qm code; mkplan "$mode" mid; git add .claude/plans/rating.md; git commit -qm plan-mid; mkplan "$mode" full; git add .claude/plans/rating.md; git commit -qm plan-pre-merge; }
run_case good good; ok rating_asset_evidence_passes bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
run_case multi multi; ok rating_asset_multi_evidence_passes bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
run_case missing missing; no rating_asset_missing_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
run_case invalid invalid; no rating_asset_missing_confidence_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
run_case wrong wrong; no rating_asset_wrong_asset_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
run_case extra extra; no rating_asset_extra_asset_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
run_case partial partial; no rating_asset_partial_asset_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
run_case waiver allow; ok rating_asset_waiver_passes bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
