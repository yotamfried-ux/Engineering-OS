#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECKER="$ROOT/scripts/enforcement/check-cv-external-system-selection.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/.claude/plans"
cd "$TMP"
cat > .claude/plans/base.md <<'PLAN'
# Route Plan
| Field | Decision |
|---|---|
| Task type | governance |
| Templates | not required |
| Architecture guides | none |
| Patterns | none |
| Domain tags | video |
| Evidence to check | validator output |
| External systems/connectors | GitHub |
## Capability Evidence
- `routing.task-router-read`
PLAN
cp .claude/plans/base.md .claude/plans/template-cv-missing.md
sed -i 's/| Templates | not required |/| Templates | templates\/computer-vision |/' .claude/plans/template-cv-missing.md
if bash "$CHECKER" .claude/plans/template-cv-missing.md >/tmp/template-cv-missing.out 2>&1; then exit 1; fi
grep -q 'Computer Vision task' /tmp/template-cv-missing.out
cp .claude/plans/template-cv-missing.md .claude/plans/template-cv-selected.md
sed -i 's/| External systems\/connectors | GitHub |/| External systems\/connectors | GitHub, supervision |/' .claude/plans/template-cv-selected.md
bash "$CHECKER" .claude/plans/template-cv-selected.md >/tmp/template-cv-selected.out
cp .claude/plans/template-cv-missing.md .claude/plans/template-cv-waived.md
cat >> .claude/plans/template-cv-waived.md <<'PLAN'

## External System Selection Waiver

- supervision reason: fixture validates documented fallback path.
PLAN
bash "$CHECKER" .claude/plans/template-cv-waived.md >/tmp/template-cv-waived.out
cp .claude/plans/template-cv-missing.md .claude/plans/template-cv-shallow.md
cat >> .claude/plans/template-cv-shallow.md <<'PLAN'

## External System Selection Waiver

supervision
PLAN
if bash "$CHECKER" .claude/plans/template-cv-shallow.md >/tmp/template-cv-shallow.out 2>&1; then exit 1; fi
echo "cv external system selection tests passed"
