#!/usr/bin/env bash
# test-tests.sh — regression tests for the comprehensive pre-commit test gate.
# Stacks' tools are stubbed on a controlled PATH so exit codes are deterministic.
# Run: bash scripts/enforcement/tests/test-tests.sh
set -u

ENFORCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENFORCER="$ENFORCE_DIR/enforce-tests.sh"

PASS=0; FAIL=0
# ok <label> — record a passed test case.
ok()  { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
# bad <label> — record a failed test case.
bad() { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; }
# expect <label> <want> <got> — pass when want==got, fail otherwise.
expect() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected $2, got $3)"; fi; }

REPO="$(mktemp -d)"; trap 'rm -rf "$REPO" 2>/dev/null' EXIT
cd "$REPO" || exit 1
git init -q 2>/dev/null; git config user.email t@t.t; git config user.name t
# Initial empty commit so `git reset` in reset_case clears the index reliably
# (without a HEAD, reset is unreliable across git versions → index leakage between cases).
git commit --allow-empty -qm init 2>/dev/null

STUBDIR="$REPO/.stubs"; mkdir -p "$STUBDIR"
RUNLOG="$REPO/.runlog"

# mkstub <tool> — fake executable that logs its name and exits per STUB_<TOOL>.
mkstub() {
  local name="$1" var="STUB_$(printf '%s' "$1" | tr 'a-z' 'A-Z')"
  cat > "$STUBDIR/$name" <<EOF
#!/usr/bin/env bash
echo "$name \$*" >> "$RUNLOG"
exit "\${$var:-0}"
EOF
  chmod +x "$STUBDIR/$name"
}

# runE — run the enforcer in REPO with a controlled PATH (only our stubs + coreutils).
runE() { ( cd "$REPO" && PATH="$STUBDIR:/usr/bin:/bin" bash "$ENFORCER" ) >/dev/null 2>&1; echo $?; }

# reset_case — clear repo state between test cases (index, fixtures, stubs, log).
reset_case() {
  git reset -q >/dev/null 2>&1 || true
  rm -f "$REPO"/package.json "$REPO"/go.mod "$REPO"/*.js "$REPO"/*.go "$REPO"/*.sh "$RUNLOG" 2>/dev/null
  rm -f "$STUBDIR"/* 2>/dev/null
}

echo "── aggregation: all detected stacks run (not elif) ──"
reset_case
printf '{"scripts":{"lint":"x","test":"y"}}\n' > package.json
printf 'module example\n' > go.mod
echo 'const a=1' > app.js; printf 'package main\n' > main.go
git add package.json go.mod app.js main.go 2>/dev/null
mkstub npm; mkstub go
rc="$(STUB_NPM=0 STUB_GO=0 runE)"
expect "both stacks pass → commit allowed" 0 "$rc"
if grep -q '^npm ' "$RUNLOG" 2>/dev/null; then ok "node stack ran"; else bad "node stack ran"; fi
if grep -q '^go '  "$RUNLOG" 2>/dev/null; then ok "go stack ran (proves no elif)"; else bad "go stack ran"; fi

echo "── a running check that fails blocks ──"
rc="$(STUB_NPM=1 STUB_GO=0 runE)"
expect "node failure blocks commit" 1 "$rc"
rc="$(STUB_NPM=0 STUB_GO=1 runE)"
expect "go failure blocks commit"   1 "$rc"

echo "── declared stack, tool missing → warn, not block ──"
reset_case
printf 'module example\n' > go.mod; printf 'package main\n' > main.go
git add go.mod main.go 2>/dev/null   # no go stub on PATH
expect "missing go tool warns (exit 0)" 0 "$(runE)"

echo "── shell syntax gate ──"
reset_case
printf 'if then fi\n' > broken.sh           # invalid bash syntax
git add broken.sh 2>/dev/null
expect "staged .sh syntax error blocks" 1 "$(runE)"
reset_case
printf '#!/usr/bin/env bash\necho hi\n' > ok.sh
git add ok.sh 2>/dev/null
expect "clean staged .sh allowed"       0 "$(runE)"

echo "── general ──"
reset_case
echo 'const a=1' > app.js; printf '{"scripts":{"test":"y"}}\n' > package.json
git add app.js package.json 2>/dev/null; mkstub npm
expect "EOS_BYPASS_TESTS skips all checks when set" 0 "$(EOS_BYPASS_TESTS=1 STUB_NPM=1 runE)"
reset_case
echo readme > notes.txt; git add notes.txt 2>/dev/null
expect "no relevant stack staged → pass" 0 "$(runE)"

echo
echo "════════ $PASS passed, $FAIL failed ════════"
[ "$FAIL" -eq 0 ]
