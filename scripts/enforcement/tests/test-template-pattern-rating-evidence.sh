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
mkplan(){ cat > .claude/plans/rating.md <<'PLAN'
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

## Template/Pattern Rating Evidence
- asset: patterns/security/README.md
- rating: 4 medium confidence after fixture use.
- outcome: rating_asset_evidence_passes fixture reused the pattern successfully.
- decision: keep this pattern preferred for security-surface changes.

## Progress Lifecycle Evidence
- start: plan first.
- mid: fixture executed.
- pre-merge: CI final.

## Claude Run Trace
- goal: rating_asset_evidence_passes fixture.
PLAN
}
change(){ mkdir -p .claude/plans src; echo 'console.log("x")' > src/app.js; }
ok(){ local n="$1"; shift; "$@" >/dev/null || { echo "fail: $n"; exit 1; }; echo "ok: $n"; }
no(){ local n="$1"; shift; if "$@" >/dev/null 2>&1; then echo "unexpected pass: $n"; exit 1; else echo "ok: $n"; fi; }
run_case(){ local branch="$1" mode="$2"; git checkout -q -B "$branch" "$BASE"; mkdir -p .claude/plans src; mkplan; if [ "$mode" = missing ]; then python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/rating.md'); s=p.read_text(); p.write_text(s.split('## Template/Pattern Rating Evidence')[0]+'## Progress Lifecycle Evidence\n- start: plan first.\n- mid: fixture executed.\n- pre-merge: CI final.\n\n## Claude Run Trace\n- goal: rating_asset_missing_fails fixture.\n')
PY
elif [ "$mode" = invalid ]; then python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/rating.md'); s=p.read_text().replace('- decision: keep this pattern preferred for security-surface changes.\n',''); p.write_text(s)
PY
elif [ "$mode" = waiver ]; then python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/rating.md'); s=p.read_text(); a=s.index('## Template/Pattern Rating Evidence'); b=s.index('## Progress Lifecycle Evidence'); p.write_text(s[:a]+'## Template/Pattern Rating Waiver\n\nRating evidence is waived because this isolated fixture has no real reusable asset outcome yet.\n\n'+s[b:])
PY
fi; git add .claude/plans/rating.md; git commit -qm plan; change; git add src/app.js; git commit -qm code; }
run_case good good; ok rating_asset_evidence_passes bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
run_case missing missing; no rating_asset_missing_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
run_case invalid invalid; no rating_asset_invalid_fails bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
run_case waiver waiver; ok rating_asset_waiver_passes bash "$CHECK" "$BASE" "$(git rev-parse HEAD)"
