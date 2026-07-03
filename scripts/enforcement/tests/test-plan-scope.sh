#!/usr/bin/env bash
# test-plan-scope.sh — proves check-plan-scope.sh keeps writes in the active Route
# Plan's declared scope (CLI + hook modes) and that it is wired into installed
# settings via patch-settings-runtime-evidence.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCRIPT="$ROOT/scripts/enforcement/check-plan-scope.sh"
PATCHER="$ROOT/scripts/enforcement/patch-settings-runtime-evidence.sh"
chmod +x "$SCRIPT" "$PATCHER"

pass=0; fail=0
ok()   { echo "  ✅ $1"; pass=$((pass+1)); }
bad()  { echo "  ❌ $1"; fail=$((fail+1)); }

# fresh_project <fn> — run <fn> inside an isolated temp project dir (CWD-sensitive
# checks read graphify-out/ and .claude/.evidence/ relative to CWD).
fresh_project() {
  local dir; dir="$(mktemp -d)"
  ( cd "$dir" && mkdir -p .claude/plans && "$@" )
  local rc=$?
  rm -rf "$dir"
  return $rc
}

# ---------- CLI mode: Target paths scope ----------
scenario_inside_scope() {
  cat > .claude/plans/p.md <<'EOF'
# Route Plan
| Target paths | scripts/foo/, docs/bar.md |
EOF
  bash "$SCRIPT" .claude/plans/p.md scripts/foo/new.sh >/dev/null 2>&1
}
fresh_project scenario_inside_scope && ok "allows write inside declared Target paths" \
  || bad "should allow write inside Target paths"

scenario_outside_scope() {
  cat > .claude/plans/p.md <<'EOF'
# Route Plan
| Target paths | scripts/foo/ |
EOF
  if bash "$SCRIPT" .claude/plans/p.md scripts/other/new.sh >/dev/null 2>&1; then return 1; else return 0; fi
}
fresh_project scenario_outside_scope && ok "blocks write outside declared Target paths" \
  || bad "should block write outside Target paths"

# ---------- CLI mode: graphify evidence ----------
scenario_graph_no_evidence() {
  mkdir -p graphify-out
  echo '{}' > graphify-out/graph.json
  cat > .claude/plans/p.md <<'EOF'
# Route Plan
| Target paths | none |
EOF
  if bash "$SCRIPT" .claude/plans/p.md scripts/x.sh >/dev/null 2>&1; then return 1; else return 0; fi
}
fresh_project scenario_graph_no_evidence && ok "blocks when graph.json exists but no graphify_used evidence" \
  || bad "should block when graph.json present without graphify_used evidence"

scenario_evidence_no_findings() {
  mkdir -p graphify-out .claude/.evidence
  echo '{}' > graphify-out/graph.json
  printf 'ts\tgraphify_used\tquery\n' > .claude/.evidence/ledger
  cat > .claude/plans/p.md <<'EOF'
# Route Plan
| Target paths | none |
EOF
  if bash "$SCRIPT" .claude/plans/p.md scripts/x.sh >/dev/null 2>&1; then return 1; else return 0; fi
}
fresh_project scenario_evidence_no_findings && ok "blocks when graphify_used but plan lacks Graphify findings" \
  || bad "should block when graphify_used recorded without findings in plan"

scenario_evidence_with_findings() {
  mkdir -p graphify-out .claude/.evidence
  echo '{}' > graphify-out/graph.json
  printf 'ts\tgraphify_used\tquery\n' > .claude/.evidence/ledger
  cat > .claude/plans/p.md <<'EOF'
# Route Plan
| Target paths | none |

## Graphify findings
graphify query oriented the wiring before this write.
EOF
  bash "$SCRIPT" .claude/plans/p.md scripts/x.sh >/dev/null 2>&1
}
fresh_project scenario_evidence_with_findings && ok "allows when graphify_used and Graphify findings present" \
  || bad "should allow when graphify_used and findings both present"

# Regression: section_text/section_field must be case-insensitive without relying on
# gawk's IGNORECASE, which mawk (the default /usr/bin/awk on Debian/Ubuntu) does not
# support. A heading/field casing that differs from the exact literal the script
# checks for must still match.
scenario_evidence_mixed_case() {
  mkdir -p graphify-out .claude/.evidence
  echo '{}' > graphify-out/graph.json
  printf 'ts\tgraphify_used\tquery\n' > .claude/.evidence/ledger
  cat > .claude/plans/p.md <<'EOF'
# Route Plan
| Target paths | none |

## graphify FINDINGS
Source: Graphify query
Action: traced callers of scripts/x.sh
Result: found 2 dependent modules
Decision: scripts/x.sh selected as the write target based on the graph path
Target: scripts/x.sh
EOF
  bash "$SCRIPT" .claude/plans/p.md scripts/x.sh >/dev/null 2>&1
}
if fresh_project scenario_evidence_mixed_case; then
  ok "allows mixed-case Graphify heading/fields (mawk-safe, no gawk IGNORECASE)"
else
  bad "should allow mixed-case heading/fields without gawk IGNORECASE"
fi

# ---------- Hook mode: PreToolUse JSON on stdin (deny is emitted as JSON, exit 0) ----------
scenario_hook_deny() {
  cat > .claude/plans/p.md <<'EOF'
# Route Plan
| Target paths | scripts/foo/ |
EOF
  printf '{"tool_name":"Write","tool_input":{"file_path":"scripts/other/x.sh"}}' \
    | bash "$SCRIPT" | grep -q '"permissionDecision": "deny"'
}
fresh_project scenario_hook_deny && ok "hook mode emits permissionDecision=deny for out-of-scope write" \
  || bad "hook mode should deny out-of-scope write"

scenario_hook_allow_in_scope() {
  cat > .claude/plans/p.md <<'EOF'
# Route Plan
| Target paths | scripts/foo/ |
EOF
  out="$(printf '{"tool_name":"Write","tool_input":{"file_path":"scripts/foo/x.sh"}}' | bash "$SCRIPT")"
  [ -z "$out" ]
}
fresh_project scenario_hook_allow_in_scope && ok "hook mode stays silent for in-scope write" \
  || bad "hook mode should allow in-scope write"

scenario_hook_skip_other_tool() {
  out="$(printf '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | bash "$SCRIPT")"
  [ -z "$out" ]
}
fresh_project scenario_hook_skip_other_tool && ok "hook mode ignores non-Write/Edit tools" \
  || bad "hook mode should ignore non-edit tools"

# ---------- Install wiring: patch-settings adds check-plan-scope.sh, idempotently ----------
scenario_install_wiring() {
  local tmp; tmp="$(mktemp -d)"
  cp "$ROOT/.claude/settings.json" "$tmp/settings.json"
  bash "$PATCHER" "$tmp/settings.json" >/dev/null 2>&1
  bash "$PATCHER" "$tmp/settings.json" >/dev/null 2>&1
  local count
  count="$(python3 - "$tmp/settings.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
cmds = [h.get("command", "") for b in d.get("hooks", {}).get("PreToolUse", []) for h in b.get("hooks", [])]
print(sum("check-plan-scope.sh" in c for c in cmds))
PY
)"
  rm -rf "$tmp"
  [ "$count" = "1" ]
}
scenario_install_wiring && ok "patch-settings wires check-plan-scope.sh exactly once (idempotent)" \
  || bad "patch-settings should wire check-plan-scope.sh exactly once"

echo
if [ "$fail" -ne 0 ]; then
  echo "❌ plan-scope tests: $fail failed, $pass passed"
  exit 1
fi
echo "✅ plan-scope tests passed ($pass checks)"
