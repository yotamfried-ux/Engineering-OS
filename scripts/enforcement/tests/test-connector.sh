#!/usr/bin/env bash
# test-connector.sh — regression tests for the connector-policy.md enforcer.
# Run: bash scripts/enforcement/tests/test-connector.sh
set -u

ENFORCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENFORCER="$ENFORCE_DIR/enforce-connector.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; }
expect() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected exit $2, got $3)"; fi; }

REPO="$(mktemp -d)"; trap 'rm -rf "$REPO" 2>/dev/null' EXIT
cd "$REPO" || exit 1
git init -q 2>/dev/null; git config user.email t@t.t; git config user.name t

# stage_run <path> <content> — stage a file with content, run the enforcer (pre-commit
# mode), echo its exit code, then reset the index so cases are independent.
stage_run() {
  local f="$1"; mkdir -p "$(dirname "$f")" 2>/dev/null
  printf '%s\n' "$2" > "$f"; git add "$f" 2>/dev/null
  bash "$ENFORCER" >/dev/null 2>&1; local rc=$?
  git reset -q 2>/dev/null; rm -f "$f" 2>/dev/null
  echo "$rc"
}

# Secret fixtures assembled at runtime with split literals, so this test file never
# contains a contiguous secret value of its own.
akia="AKIA"; akia="${akia}IOSFODNN7EXAMPLE"
pem="-----BEGIN RSA "; pem="${pem}PRIVATE KEY-----"
ghp="ghp_"; ghp="${ghp}abcdefghijklmnopqrstuvwxyz0123456789"

echo "── C1: block staged .env files ──"
expect ".env blocked"                 1 "$(stage_run .env 'SECRET=abc123')"
expect ".env.local blocked"           1 "$(stage_run .env.local 'X=1')"
expect "config/.env blocked"          1 "$(stage_run config/.env 'X=1')"
expect ".env.example allowed"         0 "$(stage_run .env.example 'X=dummy')"
expect "normal app.js allowed"        0 "$(stage_run app.js 'const x = 1')"
expect "EOS_BYPASS_ENVFILE skips C1"  0 "$(EOS_BYPASS_ENVFILE=1 stage_run .env 'S=1')"

echo "── C2: block high-confidence secret values ──"
expect "AWS AKIA key blocked"         1 "$(stage_run leak.js "const k = \"$akia\"")"
expect "PEM private key blocked"      1 "$(stage_run id_rsa "$pem")"
expect "GitHub token blocked"         1 "$(stage_run tok.js "token = \"$ghp\"")"
expect "env-var reference allowed"    0 "$(stage_run clean.js 'const k = process.env.API_KEY')"
expect "keyword-only mention allowed" 0 "$(stage_run doc.md 'set your api_key and secret in .env')"
expect "EOS_BYPASS_SECRETS skips C2"  0 "$(EOS_BYPASS_SECRETS=1 stage_run leak.js "const k = \"$akia\"")"

echo "── general ──"
expect "EOS_BYPASS_CONNECTOR (master) skips all" 0 "$(EOS_BYPASS_CONNECTOR=1 stage_run .env 'S=1')"
expect "no staged files → pass"       0 "$(bash "$ENFORCER" >/dev/null 2>&1; echo $?)"

echo
echo "════════ $PASS passed, $FAIL failed ════════"
[ "$FAIL" -eq 0 ]
