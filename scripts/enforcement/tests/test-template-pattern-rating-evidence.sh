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
mkplan(){ local mode="$1" step="$2"; cat > .claude/plans/rating.md <<PLAN
# Route Plan
| Field | Value |
|---|---|
| Task class | code_change |
| Domain tags | api, reuse |
| Target paths | src/app.js |
| Templates | not required |
| Patterns | patterns/security/README.md |
| External systems/connectors | github |
| Skills | superpowers |
| Validation gates | workflow-evidence-policy, enforcement-tests |
| Task-router evidence | read |
| Workflow evidence | read |

## Template Gap Waiver
reason: no template applies; this fixture is focused on pattern rating behavior.

## Source of Truth Checks
| Source | Status |
|---|---|
| core/workflow.md | checked |
| src/app.js | checked |

## Skill Evidence
- superpowers

PLAN
if [ "$mode" = allow ]; then cat >> .claude/plans/rating.md <<'PLAN'
## Template/Pattern Rating Waiver

Rating evidence is waived because this isolated fixture has no real reusable asset outcome yet.

PLAN
elif [ "$mode" != missing ]; then cat >> .claude/plans/rating.md <<'PLAN'
## Template/Pattern Rating Evidence
- asset: patterns/security/README.md
- rating: 4 medium confidence after fixture use.
- outcome: rating fixture reused the pattern successfully.
- decision: keep this pattern preferred for security-surface changes.

PLAN
fi
if [ "$mode" = invalid ]; then python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/rating.md')
p.write_text(p.read_text().replace('- decision: keep this pattern preferred for security-surface changes.\n',''))
PY
fi
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
run_case missing missing; no rating_asset_missing_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
run_case invalid invalid; no rating_asset_invalid_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
run_case waiver allow; ok rating_asset_waiver_passes bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
