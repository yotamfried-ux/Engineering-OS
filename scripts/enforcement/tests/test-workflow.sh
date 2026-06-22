#!/usr/bin/env bash
# test-workflow.sh — regression tests for the workflow.md enforcer + md-sync gate.
# Run: bash scripts/enforcement/tests/test-workflow.sh
set -u

ENFORCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENFORCER="$ENFORCE_DIR/enforce-workflow.sh"
SYNC="$ENFORCE_DIR/enforce-sync.sh"

PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; }

# run_enforcer <tool> <file_path|command> ; returns enforcer exit code
run_enforcer() {
  local tool="$1" arg="$2" key="file_path"
  [ "$tool" = "Bash" ] && key="command"
  printf '{"tool_name":"%s","tool_input":{"%s":"%s"}}' "$tool" "$key" "$arg" \
    | bash "$ENFORCER" >/dev/null 2>&1
}
expect() { # <desc> <expected_code> <actual_code>
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
echo '{}' > .claude/tasks.json
run_enforcer Agent ""; expect "agent allowed with tasks.json" 0 $?

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

echo "── workflow enforcer: G3 — self-bypass detection ──"
run_enforcer Bash "export EOS_BYPASS_WORKFLOW=1"; expect "G3: export EOS_BYPASS_* via Bash blocked" 1 $?
run_enforcer Bash "EOS_BYPASS_CONTEXT7=1 npm install react"; expect "G3: EOS_BYPASS_* prefix via Bash blocked" 1 $?
run_enforcer Bash "echo EOS_BYPASS_WORKFLOW=1"; expect "G3: echo of bypass var allowed (not assignment)" 0 $?

echo "── workflow enforcer: G6a — pattern-lifecycle evidence gate ──"
rm -rf .claude/.evidence
run_enforcer Write "patterns/api/test.ts"; expect "G6a: patterns/ write blocked without pattern-lifecycle evidence" 1 $?
mkdir -p .claude/.evidence
printf '%s\tread_pattern_lifecycle\t\n' "$(date +%s)" > .claude/.evidence/ledger
run_enforcer Write "patterns/api/test.ts"; expect "G6a: patterns/ write allowed with pattern-lifecycle evidence" 0 $?

echo "── workflow enforcer: G6b — hooks-policy evidence gate ──"
rm -rf .claude/.evidence
run_enforcer Write "scripts/enforcement/test.sh"; expect "G6b: enforcement write blocked without hooks-policy evidence" 1 $?
mkdir -p .claude/.evidence
printf '%s\tread_hooks_policy\t\n' "$(date +%s)" > .claude/.evidence/ledger
run_enforcer Write "scripts/enforcement/test.sh"; expect "G6b: enforcement write allowed with hooks-policy evidence" 0 $?
rm -rf .claude/.evidence

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

echo
echo "════════ $PASS passed, $FAIL failed ════════"
[ "$FAIL" -eq 0 ]
