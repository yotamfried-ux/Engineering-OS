#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-rtk-contract.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG_FILE="$TMP/context-optimizer.log"

pass() { local name="$1"; shift; "$@" >"$LOG_FILE" 2>&1 || { echo "fail: $name"; cat "$LOG_FILE"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$LOG_FILE" 2>&1; then echo "unexpected pass: $name"; cat "$LOG_FILE"; exit 1; else echo "ok: $name"; fi; }

pass checker_present test -f "$CHECK"
pass repo_contract_passes bash "$CHECK"

mkdir -p "$TMP/bad/.claude" "$TMP/bad/scripts" "$TMP/bad/external-skills/rtk"
printf '%s\n' '{"hooks":{"SessionStart":[{"hooks":[{"command":"scripts/session-setup.sh"}]}]}}' > "$TMP/bad/.claude/settings.json"
printf '%s\n' '# setup' 'rtk init -g' 'rtk --version' > "$TMP/bad/scripts/session-setup.sh"
printf '%s\n' '# policy' 'mandatory' > "$TMP/bad/external-skills/rtk/policy.md"
failcase missing_bash_hook_fails bash "$CHECK" "$TMP/bad/.claude/settings.json" "$TMP/bad/scripts/session-setup.sh" "$TMP/bad/external-skills/rtk/policy.md"

rm -rf "$TMP/target"
mkdir -p "$TMP/target"
cd "$TMP/target"
git init >/dev/null
EOS_CONTRACT_TEST=1 ENGINEERING_OS_HOME="$ROOT" bash "$ROOT/scripts/use-in-project.sh" >/dev/null
pass installed_project_keeps_bash_hook grep -q 'rtk hook claude' .claude/settings.json
pass installed_project_keeps_session_setup grep -q 'scripts/session-setup.sh' .claude/settings.json

echo "context optimizer contract simulations passed"
