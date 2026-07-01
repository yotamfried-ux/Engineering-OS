#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCRIPT="$ROOT/scripts/enforcement/check-plan-scope.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
p=0; f=0
ok(){ echo "ok $1"; p=$((p+1)); }
bad(){ echo "bad $1"; f=$((f+1)); }
run_case(){
  n="$1"; b="$2"; t="${3:-scripts/x.sh}"; d="$TMP/$n/project"
  mkdir -p "$d/.claude/plans" "$d/graphify-out" "$d/.claude/.evidence"
  echo '{}' > "$d/graphify-out/graph.json"
  printf 'ts\tgraphify_used\tquery\n' > "$d/.claude/.evidence/ledger"
  printf '%s\n' "$b" > "$d/.claude/plans/route.md"
  (cd "$d" && bash "$SCRIPT" .claude/plans/route.md "$t" >/dev/null 2>&1)
}
block(){ if run_case "$1" "$2" "${3:-scripts/x.sh}"; then bad "$1"; else ok "$1"; fi; }
allow(){ if run_case "$1" "$2" "${3:-scripts/x.sh}"; then ok "$1"; else bad "$1"; fi; }
block heading '# Route Plan
| Target paths | none |

## Graphify findings
graph query was used before this write.'
block wrong '# Route Plan
| Target paths | none |

## Graphify Usage Evidence
- source: graph query map for the repo.
- action: graph inspected dependency path before editing.
- result: graph path showed scripts/a.sh owns the module relationship.
- decision: selected scripts/a.sh because the path identified the local dependency.
- target: scripts/a.sh'
allow linked '# Route Plan
| Target paths | none |

## Graphify Usage Evidence
- source: graph query map for the repo.
- action: graph inspected dependency path before editing.
- result: graph path showed scripts/x.sh owns the module relationship.
- decision: selected scripts/x.sh because the path identified the local dependency.
- target: scripts/x.sh'
echo "$p passed $f failed"
[ "$f" -eq 0 ]
