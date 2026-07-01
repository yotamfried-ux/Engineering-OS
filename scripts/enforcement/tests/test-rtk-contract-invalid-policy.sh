#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-rtk-contract.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG_FILE="$TMP/rtk-invalid.log"

pass() { local name="$1"; shift; "$@" >"$LOG_FILE" 2>&1 || { echo "fail: $name"; cat "$LOG_FILE"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$LOG_FILE" 2>&1; then echo "unexpected pass: $name"; cat "$LOG_FILE"; exit 1; else echo "ok: $name"; fi; }

mkdir -p "$TMP/fixture/.claude" "$TMP/fixture/scripts" "$TMP/fixture/external-skills/rtk"
cat > "$TMP/fixture/.claude/settings.json" <<'JSON'
{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"command":"rtk hook claude"}]}],"SessionStart":[{"hooks":[{"command":"scripts/session-setup.sh"}]}]}}
JSON
printf '%s\n' '# setup' 'rtk init -g' 'rtk --version' > "$TMP/fixture/scripts/session-setup.sh"
printf '%s\n' '# policy' 'optional' > "$TMP/fixture/external-skills/rtk/policy.md"

failcase optional_policy_fails_contract bash "$CHECK" "$TMP/fixture/.claude/settings.json" "$TMP/fixture/scripts/session-setup.sh" "$TMP/fixture/external-skills/rtk/policy.md"

printf '%s\n' '# policy' 'mandatory' > "$TMP/fixture/external-skills/rtk/policy.md"
pass mandatory_policy_passes_contract bash "$CHECK" "$TMP/fixture/.claude/settings.json" "$TMP/fixture/scripts/session-setup.sh" "$TMP/fixture/external-skills/rtk/policy.md"

echo "rtk invalid policy contract simulations passed"
