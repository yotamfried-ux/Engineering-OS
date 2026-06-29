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

mkdir -p "$TMP/good/.claude" "$TMP/good/scripts" "$TMP/good/external-skills/rtk"
printf '%s\n' '{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"command":"rtk hook claude"}]}],"SessionStart":[{"hooks":[{"command":"scripts/session-setup.sh"}]}]}}' > "$TMP/good/.claude/settings.json"
printf '%s\n' '# setup' 'rtk init -g' 'rtk --version' > "$TMP/good/scripts/session-setup.sh"
printf '%s\n' '# policy' 'mandatory' > "$TMP/good/external-skills/rtk/policy.md"
pass good_fixture_contract_passes bash "$CHECK" "$TMP/good/.claude/settings.json" "$TMP/good/scripts/session-setup.sh" "$TMP/good/external-skills/rtk/policy.md"

# Case 4: valid_waiver_passes — EOS_BYPASS_RTK=1 allows missing hook (waiver mechanism)
EOS_BYPASS_RTK=1 pass valid_waiver_passes bash "$CHECK" "$TMP/bad/.claude/settings.json" "$TMP/bad/scripts/session-setup.sh" "$TMP/bad/external-skills/rtk/policy.md"

# Case 5: new_project_install_rtk_wired — simulates a project wired by use-in-project.sh / skill-bootstrap
mkdir -p "$TMP/newproj/.claude" "$TMP/newproj/scripts" "$TMP/newproj/external-skills/rtk"
printf '%s\n' '{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"command":"rtk hook claude"}]}],"SessionStart":[{"hooks":[{"command":"scripts/session-setup.sh"}]}]}}' \
  > "$TMP/newproj/.claude/settings.json"
printf '%s\n' '# Engineering OS session setup' 'rtk init -g' 'rtk --version' \
  > "$TMP/newproj/scripts/session-setup.sh"
printf '%s\n' '# RTK policy' 'mandatory: yes' \
  > "$TMP/newproj/external-skills/rtk/policy.md"
pass new_project_install_rtk_wired bash "$CHECK" "$TMP/newproj/.claude/settings.json" "$TMP/newproj/scripts/session-setup.sh" "$TMP/newproj/external-skills/rtk/policy.md"

echo "context optimizer contract simulations passed"
