#!/usr/bin/env bash
# Regression tests: hard-hook units and dependencies must not traverse symlinks.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
GATE="$ROOT/scripts/enforcement/lib/hook-gate.sh"
CHECK="$ROOT/scripts/enforcement/check-hard-hook-contract.py"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { printf '  ✅ %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf '  ❌ %s\n' "$1"; fail=$((fail + 1)); }

write_settings() {
  local root="$1" unit="$2"
  mkdir -p "$root/.claude"
  cat >"$root/.claude/settings.json" <<JSON
{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"GATE=\\"\${ENGINEERING_OS_HOME:-\$(pwd)}/scripts/enforcement/lib/hook-gate.sh\\"; [ -r \\"\$GATE\\" ] || { exit 2; }; bash \\"\$GATE\\" --event PreToolUse --matcher 'Bash' --unit \\"\${ENGINEERING_OS_HOME:-\$(pwd)}/$unit\\""}]}]}}
JSON
}

write_registry() {
  local root="$1" unit="$2" requires="${3:--}"
  cat >"$root/scripts/enforcement/hook-criticality.tsv" <<TSV
PreToolUse	Bash	$unit	hard	fail_closed	direct	-	both	$requires	pretool_json
TSV
}

make_root() {
  local name="$1"
  local root="$WORK/$name"
  mkdir -p "$root/scripts/enforcement/lib"
  cp "$GATE" "$root/scripts/enforcement/lib/hook-gate.sh"
  printf '%s\n' "$root"
}

run_static() {
  local root="$1"
  set +e
  python3 "$CHECK" --root "$root" --settings "$root/.claude/settings.json" --surface source >"$root/static.out" 2>"$root/static.err"
  STATIC_CODE=$?
  set -e
  STATIC_ERR="$(cat "$root/static.err")"
}

run_runtime() {
  local root="$1" unit="$2"
  local input='{"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"printf ok"}}'
  set +e
  printf '%s' "$input" | bash "$root/scripts/enforcement/lib/hook-gate.sh" \
    --event PreToolUse --matcher Bash --unit "$root/$unit" \
    >"$root/runtime.out" 2>"$root/runtime.err"
  RUNTIME_CODE=$?
  set -e
  RUNTIME_ERR="$(cat "$root/runtime.err")"
}

root="$(make_root unit-link)"
printf '#!/usr/bin/env bash\nexit 0\n' >"$root/scripts/enforcement/real-unit.sh"
ln -s real-unit.sh "$root/scripts/enforcement/unit.sh"
write_registry "$root" scripts/enforcement/unit.sh
write_settings "$root" scripts/enforcement/unit.sh
run_static "$root"
if [ "$STATIC_CODE" -ne 0 ] && printf '%s' "$STATIC_ERR" | grep -qi symlink; then
  ok "static contract rejects symlinked hard unit"
else
  bad "static contract accepted symlinked hard unit (code=$STATIC_CODE err=$STATIC_ERR)"
fi
run_runtime "$root" scripts/enforcement/unit.sh
if [ "$RUNTIME_CODE" -eq 2 ] && printf '%s' "$RUNTIME_ERR" | grep -qi symlink; then
  ok "runtime gate rejects symlinked hard unit"
else
  bad "runtime gate accepted symlinked hard unit (code=$RUNTIME_CODE err=$RUNTIME_ERR)"
fi

root="$(make_root dependency-link)"
printf '#!/usr/bin/env bash\nexit 0\n' >"$root/scripts/enforcement/unit.sh"
printf 'trusted\n' >"$root/scripts/enforcement/real-lib.sh"
ln -s real-lib.sh "$root/scripts/enforcement/required-lib.sh"
write_registry "$root" scripts/enforcement/unit.sh scripts/enforcement/required-lib.sh
write_settings "$root" scripts/enforcement/unit.sh
run_static "$root"
if [ "$STATIC_CODE" -ne 0 ] && printf '%s' "$STATIC_ERR" | grep -qi symlink; then
  ok "static contract rejects symlinked hard dependency"
else
  bad "static contract accepted symlinked hard dependency (code=$STATIC_CODE err=$STATIC_ERR)"
fi
run_runtime "$root" scripts/enforcement/unit.sh
if [ "$RUNTIME_CODE" -eq 2 ] && printf '%s' "$RUNTIME_ERR" | grep -qi symlink; then
  ok "runtime gate rejects symlinked hard dependency"
else
  bad "runtime gate accepted symlinked hard dependency (code=$RUNTIME_CODE err=$RUNTIME_ERR)"
fi

root="$(make_root directory-link)"
mkdir -p "$root/scripts/real-enforcement"
printf '#!/usr/bin/env bash\nexit 0\n' >"$root/scripts/real-enforcement/unit.sh"
ln -s ../real-enforcement "$root/scripts/enforcement/linkdir"
write_registry "$root" scripts/enforcement/linkdir/unit.sh
write_settings "$root" scripts/enforcement/linkdir/unit.sh
run_static "$root"
if [ "$STATIC_CODE" -ne 0 ] && printf '%s' "$STATIC_ERR" | grep -qi symlink; then
  ok "static contract rejects symlinked hard directory component"
else
  bad "static contract accepted symlinked hard directory (code=$STATIC_CODE err=$STATIC_ERR)"
fi
run_runtime "$root" scripts/enforcement/linkdir/unit.sh
if [ "$RUNTIME_CODE" -eq 2 ] && printf '%s' "$RUNTIME_ERR" | grep -qi symlink; then
  ok "runtime gate rejects symlinked hard directory component"
else
  bad "runtime gate accepted symlinked hard directory (code=$RUNTIME_CODE err=$RUNTIME_ERR)"
fi

printf '\nhard-hook symlink regression: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
