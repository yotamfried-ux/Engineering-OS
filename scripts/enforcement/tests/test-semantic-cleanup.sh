#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-semantic-cleanup.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

repo() {
  local dir="$1"
  mkdir -p "$dir"
  cd "$dir"
  git init -q
  git config user.email t@example.com
  git config user.name tester
}

expect_pass() { local name="$1"; shift; if "$@" >/tmp/semantic-cleanup.out 2>&1; then echo "ok: $name"; else echo "expected pass: $name"; cat /tmp/semantic-cleanup.out; exit 1; fi; }
expect_fail() { local name="$1"; shift; if "$@" >/tmp/semantic-cleanup.out 2>&1; then echo "unexpected pass: $name"; cat /tmp/semantic-cleanup.out; exit 1; else echo "ok: $name"; fi; }

GOOD="$TMP/good"; repo "$GOOD"
cat > app.py <<'PY'
import math
print(math.sqrt(4))
PY
git add app.py
expect_pass clean_code_passes bash "$CHECK"

TODO="$TMP/todo"; repo "$TODO"
cat > app.js <<'JS'
// TODO remove temporary branch before merge
export const value = 1;
JS
git add app.js
expect_fail risky_cleanup_marker_fails bash "$CHECK"

UNUSED="$TMP/unused"; repo "$UNUSED"
cat > app.py <<'PY'
import os
print('hello')
PY
git add app.py
expect_fail unused_import_fails bash "$CHECK"

DISABLED="$TMP/disabled"; repo "$DISABLED"
cat > app.ts <<'TS'
if (false) {
  console.log('unused branch')
}
TS
git add app.ts
expect_fail disabled_branch_fails bash "$CHECK"

WAIVER="$TMP/waiver"; repo "$WAIVER"
cat > app.py <<'PY'
# EOS_SEMANTIC_CLEANUP_WAIVER: fixture keeps an unused import to prove explicit waiver behavior.
import os
print('hello')
PY
git add app.py
expect_fail waiver_requires_allow_flag bash "$CHECK"
expect_pass explicit_waiver_passes bash "$CHECK" --allow-waiver

echo "semantic cleanup tests passed"
