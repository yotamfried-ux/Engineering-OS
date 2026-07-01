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
python3 -c "import json,sys; d=json.load(open('$d2/.claude/settings.json')); sys.exit(0 if 'hooks' in d else 1)" 2>/dev/null \
  && ok "refreshed settings is valid JSON with hooks" \
  || bad "refreshed settings must be valid JSON with a hooks block"

# Scenario 3 — update must NOT overwrite when the backup cannot be written.
# A read-only .claude dir blocks creating the new .bak while the existing
# settings.json inode stays writable (Codex's clobber-without-backup case).
# Root bypasses DAC permission bits, so this check only applies as a non-root user.
if [ "$(id -u)" != "0" ]; then
  d3="$(make_target)"
  chmod 555 "$d3/.claude"
  ( cd "$d3" && EOS_CONTRACT_TEST=1 ENGINEERING_OS_HOME="$ROOT" EOS_UPDATE_SETTINGS=1 bash "$UIP" >/dev/null 2>&1 ) || true
  chmod 755 "$d3/.claude"
  grep -q "KEEPME" "$d3/.claude/settings.json" \
    && ok "aborts refresh (preserves settings) when the backup cannot be written" \
    || bad "must not overwrite settings when the backup fails"
  rm -rf "$d3"
else
  echo "  ➖ backup-failure scenario skipped (running as root; chmod does not restrict root)"
fi

rm -rf "$d1" "$d2"
echo
echo "use-in-project update: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
