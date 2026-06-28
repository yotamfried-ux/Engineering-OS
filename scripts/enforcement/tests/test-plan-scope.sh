#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-plan-scope.sh"
chmod +x "$CHECK"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
mkdir -p .claude/plans .claude/.evidence src/api src/ui graphify-out
: > .claude/.evidence/ledger

cat > .claude/plans/task.md <<'PLAN'
# Route Plan

| Field | Decision |
|---|---|
| Target paths | src/api, tests/api |
PLAN

ok() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "  ✅ $name"; else echo "  ❌ expected ok: $name"; exit 1; fi; }
not_ok() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "  ❌ expected not ok: $name"; exit 1; else echo "  ✅ $name"; fi; }

ok "in-scope api path" "$CHECK" .claude/plans/task.md src/api/users.ts
not_ok "out-of-scope ui path" "$CHECK" .claude/plans/task.md src/ui/button.ts

cat > .claude/plans/any.md <<'PLAN'
# Route Plan

| Field | Decision |
|---|---|
| Target paths | Any |
PLAN
ok "any target path" "$CHECK" .claude/plans/any.md src/ui/button.ts

echo '{}' > graphify-out/graph.json
not_ok "graph file needs graph evidence" "$CHECK" .claude/plans/any.md src/ui/button.ts
printf '%s\tgraphify_used\t\n' "$(date +%s)" >> .claude/.evidence/ledger
not_ok "graph evidence needs plan note" "$CHECK" .claude/plans/any.md src/ui/button.ts

cat > .claude/plans/graph.md <<'PLAN'
# Route Plan

| Field | Decision |
|---|---|
| Target paths | Any |

## Graphify findings

- graphify query showed the relevant dependency path for this change.
PLAN
ok "graph note accepted" "$CHECK" .claude/plans/graph.md src/ui/button.ts

echo "plan scope tests passed"
