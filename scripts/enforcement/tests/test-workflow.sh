#!/usr/bin/env bash
# test-workflow.sh — regression tests for the workflow.md enforcer + md-sync gate.
# Run: bash scripts/enforcement/tests/test-workflow.sh
set -u

ENFORCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENFORCER="$ENFORCE_DIR/enforce-workflow.sh"
SYNC="$ENFORCE_DIR/enforce-sync.sh"

PASS=0; FAIL=0
# ok <desc> — record a passing assertion.
ok()   { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
# bad <desc> — record a failing assertion.
bad()  { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; }

# run_enforcer <tool> <file_path|command> ; returns enforcer exit code
run_enforcer() {
  local tool="$1" arg="$2" key="file_path"
  [ "$tool" = "Bash" ] && key="command"
  printf '{"tool_name":"%s","tool_input":{"%s":"%s"}}' "$tool" "$key" "$arg" \
    | bash "$ENFORCER" >/dev/null 2>&1
}
# expect <desc> <expected_code> <actual_code> — assert exit code and record result.
expect() {
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected exit $2, got $3)"; fi
}

# ── isolated workspace for the Write/Bash/Agent gates ────────────────────────
GITREPO=""
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK" "${GITREPO:-}" 2>/dev/null' EXIT
cd "$WORK" || exit 1

echo "── workflow enforcer: Write gate ──"
run_enforcer Write "src/app.ts"; expect "code write blocked without plan" 1 $?

mkdir -p .claude/plans
cat > .claude/plans/p.md <<'EOF'
# Task
## מטרה
goal here
## תכנון
steps here
## DoD
done criteria
## חלופות
alternatives considered
EOF
run_enforcer Write "src/app.ts"; expect "code write allowed with full+fresh plan" 0 $?

cat > .claude/plans/p.md <<'EOF'
# Task
## מטרה
goal
## תכנון
steps
EOF
run_enforcer Write "src/app.ts"; expect "code write blocked when plan missing DoD" 1 $?

run_enforcer Write "notes.md"; expect "non-critical .md write allowed" 0 $?

EOS_BYPASS_WORKFLOW=1 run_enforcer Write "src/app.ts"; expect "EOS_BYPASS_WORKFLOW skips write gate" 0 $?

echo "── workflow enforcer: Context7-before-install gate ──"
rm -rf .claude/.evidence
run_enforcer Bash "npm install react"; expect "install blocked without Context7 evidence" 1 $?
run_enforcer Bash "ls -la"; expect "non-install Bash allowed" 0 $?
mkdir -p .claude/.evidence
printf '%s\tcontext7\t\n' "$(date +%s)" > .claude/.evidence/ledger
run_enforcer Bash "npm install react"; expect "install allowed after Context7 evidence" 0 $?
rm -rf .claude/.evidence
EOS_BYPASS_CONTEXT7=1 run_enforcer Bash "npm install react"; expect "EOS_BYPASS_CONTEXT7 skips install gate" 0 $?

echo "── workflow enforcer: Agent/tasks.json gate ──"
rm -f .claude/tasks.json
run_enforcer Agent ""; expect "agent blocked without tasks.json" 1 $?

# Schema validation: empty tasks array blocked
echo '{}' > .claude/tasks.json
run_enforcer Agent ""; expect "agent blocked with empty tasks.json ({})" 1 $?

echo '{"tasks":[]}' > .claude/tasks.json
run_enforcer Agent ""; expect "agent blocked with empty tasks array" 1 $?

# Schema validation: missing required fields blocked
printf '{"tasks":[{"id":"t1","title":"do thing"}]}\n' > .claude/tasks.json
run_enforcer Agent ""; expect "agent blocked when task missing status field" 1 $?

printf '{"tasks":[{"title":"do thing","status":"todo"}]}\n' > .claude/tasks.json
run_enforcer Agent ""; expect "agent blocked when task missing id field" 1 $?

printf '{"tasks":[{"id":"t1","status":"todo"}]}\n' > .claude/tasks.json
run_enforcer Agent ""; expect "agent blocked when task missing title field" 1 $?

printf '{"tasks":["idtitlestatus"]}\n' > .claude/tasks.json
run_enforcer Agent ""; expect "agent blocked when task item is a string not an object" 1 $?

# Valid schema: all required fields present
printf '{"tasks":[{"id":"t1","title":"do thing","status":"todo"}]}\n' > .claude/tasks.json
run_enforcer Agent ""; expect "agent allowed with valid tasks.json schema" 0 $?

# Multiple tasks: all must be valid
printf '{"tasks":[{"id":"t1","title":"a","status":"done"},{"id":"t2","title":"b","status":"todo"}]}\n' > .claude/tasks.json
run_enforcer Agent ""; expect "agent allowed with multiple valid tasks" 0 $?

EOS_BYPASS_TASKSJSON=1 rm -f .claude/tasks.json 2>/dev/null; true
printf '{"tool_name":"Agent","tool_input":{}}' | EOS_BYPASS_TASKSJSON=1 bash "$ENFORCER" >/dev/null 2>&1
expect "EOS_BYPASS_TASKSJSON skips schema gate" 0 $?

echo "── workflow enforcer: G1 — .github/ critical path ──"
rm -rf .claude/plans
run_enforcer Write ".github/workflows/ci.yml"; expect "G1: .github/ write blocked without plan" 1 $?
mkdir -p .claude/plans
cat > .claude/plans/g.md <<'EOF'
# Task
## מטרה
goal here
## תכנון
steps here
## DoD
done criteria
## חלופות
alternatives considered
EOF
run_enforcer Write ".github/workflows/ci.yml"; expect "G1: .github/ write allowed with full plan" 0 $?
rm -rf .claude/plans

echo "── workflow enforcer: G3 — self-bypass detection ──"
run_enforcer Bash "export EOS_BYPASS_WORKFLOW=1"; expect "G3: export EOS_BYPASS_* via Bash blocked" 1 $?
run_enforcer Bash "EOS_BYPASS_CONTEXT7=1 npm install react"; expect "G3: EOS_BYPASS_* prefix via Bash blocked" 1 $?
run_enforcer Bash "echo EOS_BYPASS_WORKFLOW=1"; expect "G3: echo of bypass var allowed (not assignment)" 0 $?

echo "── workflow enforcer: G6a — pattern-lifecycle evidence gate ──"
mkdir -p .claude/plans
cat > .claude/plans/g6.md <<'EOF'
# Task
## מטרה
goal here
## תכנון
steps here
## DoD
done criteria
## חלופות
alternatives considered
EOF
rm -rf .claude/.evidence
run_enforcer Write "patterns/api/test.ts"; expect "G6a: patterns/ write blocked without pattern-lifecycle evidence" 1 $?
mkdir -p .claude/.evidence
printf '%s\tread_pattern_lifecycle\t\n' "$(date +%s)" > .claude/.evidence/ledger
run_enforcer Write "patterns/api/test.ts"; expect "G6a: patterns/ write allowed with pattern-lifecycle evidence" 0 $?
rm -rf .claude/.evidence

echo "── workflow enforcer: G6b — hooks-policy evidence gate ──"
rm -rf .claude/.evidence
run_enforcer Write "scripts/enforcement/test.sh"; expect "G6b: enforcement write blocked without hooks-policy evidence" 1 $?
mkdir -p .claude/.evidence
printf '%s\tread_hooks_policy\t\n' "$(date +%s)" > .claude/.evidence/ledger
run_enforcer Write "scripts/enforcement/test.sh"; expect "G6b: enforcement write allowed with hooks-policy evidence" 0 $?
rm -rf .claude/.evidence

echo "── workflow enforcer: G4 — bypass audit trail ──"
rm -rf .claude/.evidence
mkdir -p .claude/plans
cat > .claude/plans/p2.md <<'EOF'
# Task
## מטרה
goal
## תכנון
steps
## DoD
done
## חלופות
alts
EOF
EOS_BYPASS_WORKFLOW=1 run_enforcer Write ".github/workflows/ci.yml"
if grep -q "bypass_used.*EOS_BYPASS_WORKFLOW" .claude/.evidence/ledger 2>/dev/null; then
  ok "G4: bypass activation recorded to evidence ledger"
else
  bad "G4: bypass activation NOT recorded in ledger"
fi
rm -rf .claude/.evidence .claude/plans

# ── md-sync gate (needs a git repo) ──────────────────────────────────────────
echo "── enforce-sync: md ↔ enforcer ──"
GITREPO="$(mktemp -d)"
cd "$GITREPO" || exit 1
git init -q 2>/dev/null
git config user.email t@t.t; git config user.name t
mkdir -p core scripts/enforcement
echo "x" > core/workflow.md
git add core/workflow.md 2>/dev/null
bash "$SYNC" >/dev/null 2>&1; expect "workflow.md staged without enforcer blocked" 1 $?
mkdir -p scripts/enforcement
echo "y" > scripts/enforcement/enforce-workflow.sh
git add scripts/enforcement/enforce-workflow.sh 2>/dev/null
bash "$SYNC" >/dev/null 2>&1; expect "workflow.md + enforcer staged allowed" 0 $?
git reset -q 2>/dev/null
echo "z" > core/precedence.md
git add core/precedence.md 2>/dev/null
bash "$SYNC" >/dev/null 2>&1; expect "NONE-mapped md (precedence) allowed alone" 0 $?
git reset -q 2>/dev/null
echo "w" > core/made-up.md
git add core/made-up.md 2>/dev/null
bash "$SYNC" >/dev/null 2>&1; expect "md not in MANIFEST blocked" 1 $?
git reset -q 2>/dev/null
echo "w2" > core/made-up.md; git add core/made-up.md 2>/dev/null
EOS_BYPASS_MDSYNC=1 bash "$SYNC" >/dev/null 2>&1; expect "EOS_BYPASS_MDSYNC skips sync gate" 0 $?

echo "── workflow enforcer: G7 — graphify gate ──"
cd "$WORK" || exit 1
mkdir -p .claude/plans graphify-out
cat > .claude/plans/g7.md <<'EOF'
# Task
## מטרה
goal here
## תכנון
steps here
## DoD
done criteria
## חלופות
alternatives considered
EOF
rm -rf .claude/.evidence
# G7 fires only when graphify-out/graph.json exists
run_enforcer Write "src/app.ts"; expect "G7: code write allowed when graph.json absent (no gate)" 0 $?
echo '{}' > graphify-out/graph.json
run_enforcer Write "src/app.ts"; expect "G7: code write blocked without graphify_used evidence" 1 $?
mkdir -p .claude/.evidence
printf '%s\tgraphify_used\t\n' "$(date +%s)" > .claude/.evidence/ledger
run_enforcer Write "src/app.ts"; expect "G7: code write allowed after graphify_used evidence" 0 $?
rm -rf .claude/.evidence graphify-out
mkdir -p graphify-out && echo '{}' > graphify-out/graph.json
EOS_BYPASS_GRAPHIFY=1 run_enforcer Write "src/app.ts"; expect "G7: EOS_BYPASS_GRAPHIFY skips gate" 0 $?
rm -f graphify-out/graph.json .claude/plans/g7.md

echo "── workflow enforcer: G8 — domain patterns gate ──"
mkdir -p .claude/plans
cat > .claude/plans/g8.md <<'EOF'
# Task
## מטרה
goal here
## תכנון
steps here
## DoD
done criteria
## חלופות
alternatives considered
EOF
mkdir -p graphify-out patterns/auth patterns/billing
echo '{}' > graphify-out/graph.json
mkdir -p .claude/.evidence
printf '%s\tgraphify_used\t\n' "$(date +%s)" > .claude/.evidence/ledger
# G8 fires when patterns/<domain>/ exists and file path matches that domain
run_enforcer Write "src/auth/service.ts"; expect "G8: auth domain write blocked without any patterns evidence" 1 $?
# Cross-domain negative: reading billing patterns must NOT unlock auth writes
printf '%s\tpatterns_read_billing\t\n' "$(date +%s)" >> .claude/.evidence/ledger
run_enforcer Write "src/auth/service.ts"; expect "G8: auth domain write blocked after reading billing patterns (cross-domain)" 1 $?
# Domain-specific: reading auth patterns unlocks auth writes
printf '%s\tpatterns_read_auth\t\n' "$(date +%s)" >> .claude/.evidence/ledger
run_enforcer Write "src/auth/service.ts"; expect "G8: auth domain write allowed after reading auth patterns" 0 $?
# Non-existent domain dir — no G8 block
rm -rf patterns/auth
run_enforcer Write "src/auth/service.ts"; expect "G8: auth write allowed when patterns/auth/ absent" 0 $?
# Bypass
mkdir -p patterns/auth
rm -rf .claude/.evidence
mkdir -p .claude/.evidence
printf '%s\tgraphify_used\t\n' "$(date +%s)" > .claude/.evidence/ledger
EOS_BYPASS_PATTERNS=1 run_enforcer Write "src/auth/service.ts"; expect "G8: EOS_BYPASS_PATTERNS skips gate" 0 $?
rm -rf .claude/.evidence patterns graphify-out .claude/plans/g8.md

echo "── workflow enforcer: G9a — DoD integrity gate ──"
mkdir -p .claude/plans .claude/.evidence
cat > .claude/plans/task.md <<'EOF'
# Task
## מטרה
goal here
## תכנון
steps here
## DoD
- [ ] item one
- [ ] item two
- [ ] item three
## חלופות
alternatives considered
EOF
# Snapshot initial DoD count (3 items) in evidence — simulates PostToolUse Read recording
printf '%s\tdod_initial_task\t3\n' "$(date +%s)" > .claude/.evidence/ledger
# Attempt to reduce DoD count: 3 → 2 (delete a line)
NEW_CONTENT=$'# Task\n## מטרה\ngoal\n## תכנון\nsteps\n## DoD\n- [ ] item one\n- [x] item two\n## חלופות\nalts'
python3 -c "
import json, sys
print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'.claude/plans/task.md','new_string':sys.argv[1]}}))
" "$NEW_CONTENT" | bash "$ENFORCER" >/dev/null 2>&1
expect "G9a: plan write blocked when DoD count reduced (3→2)" 1 $?
# Same count (3 items, 1 checked) — allowed
NEW_CONTENT2=$'# Task\n## מטרה\ngoal\n## תכנון\nsteps\n## DoD\n- [x] item one\n- [ ] item two\n- [ ] item three\n## חלופות\nalts'
python3 -c "
import json, sys
print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'.claude/plans/task.md','new_string':sys.argv[1]}}))
" "$NEW_CONTENT2" | bash "$ENFORCER" >/dev/null 2>&1
expect "G9a: plan write allowed when DoD count unchanged (3→3)" 0 $?
# Bypass
NEW_CONTENT_BAD=$'# Task\n## DoD\n- [x] one\n## חלופות\nalts'
python3 -c "
import json, sys
print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'.claude/plans/task.md','new_string':sys.argv[1]}}))
" "$NEW_CONTENT_BAD" | EOS_BYPASS_DOD=1 bash "$ENFORCER" >/dev/null 2>&1
expect "G9a: EOS_BYPASS_DOD skips integrity gate" 0 $?
rm -rf .claude/.evidence .claude/plans/task.md

echo "── workflow enforcer: G9b — DoD completion gate ──"
mkdir -p .claude/plans .claude/.evidence
printf '%s\tgraphify_used\t\n' "$(date +%s)" > .claude/.evidence/ledger
cat > .claude/plans/finish.md <<'EOF'
# Task
## מטרה
goal here
## תכנון
steps here
## DoD
- [x] item one
- [ ] item two unchecked
## חלופות
alternatives considered
EOF
TASKS_COMPLETE='{"tasks":[{"id":"t1","title":"do thing","status":"complete"}]}'
python3 -c "
import json, sys
print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'.claude/tasks.json','new_string':sys.argv[1]}}))
" "$TASKS_COMPLETE" | bash "$ENFORCER" >/dev/null 2>&1
expect "G9b: tasks.json complete blocked when plan has unchecked DoD item" 1 $?
# All DoD items checked — allowed
cat > .claude/plans/finish.md <<'EOF'
# Task
## מטרה
goal here
## תכנון
steps here
## DoD
- [x] item one
- [x] item two
## חלופות
alternatives considered
EOF
python3 -c "
import json, sys
print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'.claude/tasks.json','new_string':sys.argv[1]}}))
" "$TASKS_COMPLETE" | bash "$ENFORCER" >/dev/null 2>&1
expect "G9b: tasks.json complete allowed when all DoD items checked" 0 $?
# Bypass
cat > .claude/plans/finish.md <<'EOF'
# Task
## מטרה
goal
## תכנון
steps
## DoD
- [ ] unchecked
## חלופות
alts
EOF
python3 -c "
import json, sys
print(json.dumps({'tool_name':'Write','tool_input':{'file_path':'.claude/tasks.json','new_string':sys.argv[1]}}))
" "$TASKS_COMPLETE" | EOS_BYPASS_DOD=1 bash "$ENFORCER" >/dev/null 2>&1
expect "G9b: EOS_BYPASS_DOD skips completion gate" 0 $?
rm -rf .claude/.evidence .claude/plans

echo
echo "════════ $PASS passed, $FAIL failed ════════"
[ "$FAIL" -eq 0 ]
