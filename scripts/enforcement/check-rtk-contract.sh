#!/usr/bin/env bash
set -euo pipefail

ROOT="${ENGINEERING_OS_HOME:-$(pwd)}"
settings="${1:-$ROOT/.claude/settings.json}"
session_setup="${2:-$ROOT/scripts/session-setup.sh}"
policy="${3:-$ROOT/external-skills/rtk/policy.md}"

[ -f "$settings" ] || { echo "rtk contract failed: settings file missing: $settings" >&2; exit 1; }
[ -f "$session_setup" ] || { echo "rtk contract failed: session setup missing: $session_setup" >&2; exit 1; }
[ -f "$policy" ] || { echo "rtk contract failed: RTK policy missing: $policy" >&2; exit 1; }

grep -q 'mandatory' "$policy" || { echo "rtk contract failed: policy must mark RTK mandatory" >&2; exit 1; }
grep -q 'rtk hook claude' "$settings" || { echo "rtk contract failed: .claude/settings.json must include rtk hook claude" >&2; exit 1; }
grep -q 'SessionStart' "$settings" || { echo "rtk contract failed: .claude/settings.json must run session setup" >&2; exit 1; }
grep -q 'scripts/session-setup.sh' "$settings" || { echo "rtk contract failed: SessionStart must call scripts/session-setup.sh" >&2; exit 1; }
grep -q 'rtk init -g' "$session_setup" || { echo "rtk contract failed: session setup must register rtk init -g" >&2; exit 1; }
grep -q 'rtk --version' "$session_setup" || { echo "rtk contract failed: session setup must verify rtk version" >&2; exit 1; }

echo "rtk contract checks passed"
