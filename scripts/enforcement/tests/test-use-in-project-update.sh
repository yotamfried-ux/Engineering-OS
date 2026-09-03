#!/usr/bin/env bash
# test-use-in-project-update.sh — verifies that use-in-project.sh refreshes an EXISTING
# target's .claude/settings.json only when EOS_UPDATE_SETTINGS=1 (with a backup), and
# preserves it on a default run. Guards the P1c target-propagation fix.
#
# Governing policy: core/hooks-policy.md (propagation of managed settings)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
UIP="$ROOT/scripts/use-in-project.sh"

pass=0; fail=0
ok()  { echo "  ✅ $1"; pass=$((pass+1)); }
bad() { echo "  ❌ $1"; fail=$((fail+1)); }

make_target() { # prints a fresh git-repo target dir with a stale settings.json
  local d; d="$(mktemp -d)"
  git -C "$d" init -q
  mkdir -p "$d/.claude"
  printf '{"hooks":{"_stale":"KEEPME"}}\n' > "$d/.claude/settings.json"
  printf '%s' "$d"
}

# Scenario 1 — default run must NOT overwrite an existing settings.json.
d1="$(make_target)"
( cd "$d1" && EOS_CONTRACT_TEST=1 ENGINEERING_OS_HOME="$ROOT" bash "$UIP" >/dev/null 2>&1 ) || true
grep -q "KEEPME" "$d1/.claude/settings.json" \
  && ok "default run preserves existing settings" \
  || bad "default run should not overwrite existing settings"

# Scenario 2 — EOS_UPDATE_SETTINGS=1 refreshes from the template and keeps a backup.
d2="$(make_target)"
( cd "$d2" && EOS_CONTRACT_TEST=1 ENGINEERING_OS_HOME="$ROOT" EOS_UPDATE_SETTINGS=1 bash "$UIP" >/dev/null 2>&1 ) || true
grep -q "KEEPME" "$d2/.claude/settings.json" \
  && bad "update flag should overwrite the stale settings" \
  || ok "EOS_UPDATE_SETTINGS refreshes settings from the template"
ls "$d2/.claude/settings.json.bak."* >/dev/null 2>&1 \
  && ok "a backup of the prior settings is created" \
  || bad "update run should create a .bak backup"
python3 -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if 'hooks' in d else 1)" "$d2/.claude/settings.json" 2>/dev/null \
  && ok "refreshed settings is valid JSON with hooks" \
  || bad "refreshed settings must be valid JSON with a hooks block"

# Scenario 3 — update must NOT overwrite when the backup cannot be written.
# A read-only .claude dir blocks creating the new .bak while the existing
# settings.json inode stays writable (Codex's clobber-without-backup case).
# Root bypasses DAC permission bits, so this check only applies as a non-root user.
platform="$(uname -s)"
if [ "$(id -u)" != "0" ] && [[ "$platform" != MINGW* && "$platform" != MSYS* && "$platform" != CYGWIN* ]]; then
  d3="$(make_target)"
  chmod 555 "$d3/.claude"
  ( cd "$d3" && EOS_CONTRACT_TEST=1 ENGINEERING_OS_HOME="$ROOT" EOS_UPDATE_SETTINGS=1 bash "$UIP" >/dev/null 2>&1 ) || true
  chmod 755 "$d3/.claude"
  grep -q "KEEPME" "$d3/.claude/settings.json" \
    && ok "aborts refresh (preserves settings) when the backup cannot be written" \
    || bad "must not overwrite settings when the backup fails"
  rm -rf "$d3"
else
  echo "  ➖ backup-failure scenario skipped (chmod does not enforce this fixture on $platform or for root)"
fi

# Scenario 4 — runtime preflight fails before the target receives Engineering OS files.
d4="$(mktemp -d)"
git -C "$d4" init -q
printf 'keep\n' > "$d4/original.txt"
set +e
( cd "$d4" && EOS_CONTRACT_TEST=1 ENGINEERING_OS_HOME="$ROOT" EOS_PYTHON_BIN=definitely-missing-python bash "$UIP" >"$d4/run.out" 2>"$d4/run.err" )
d4_code=$?
set -e
if [ "$d4_code" -ne 0 ] && [ ! -e "$d4/.engineering-os" ] && [ ! -e "$d4/.claude" ] && grep -q 'configured Python runtime' "$d4/run.err"; then
  ok "runtime preflight precedes target installation"
else
  bad "missing runtime mutated the target or lacked diagnostics (code=$d4_code)"
fi

rm -rf "$d1" "$d2" "$d4"
echo
echo "use-in-project update: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
