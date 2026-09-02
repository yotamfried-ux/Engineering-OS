#!/usr/bin/env bash
# post-tool-use-skill-evidence.sh — PostToolUse evidence recorder for the Skill tool.
#
# Why this exists: the verification gate keyed on a Read of one file path,
# `.claude/commands/superpowers-verify.md`. Invoking the same verification as a skill
# runs the identical checklist and recorded nothing, so verification that genuinely
# happened was reported as not having happened. That is the same defect class as the
# Bash suite miss: operational evidence keyed on an incidental mechanism (which file
# was opened) rather than on the work (the verification ran).
#
# This recorder keys on the skill invocation itself, so every legitimate entry point to
# a skill produces the same evidence. The Read path stays valid — a reader who opens the
# checklist file is still doing the work — but it is no longer the only path.
#
# Records:
#   skill_used <canonical-skill-name>   — for any successfully invoked skill
#   <name>_run                          — the underscore form gates already look for,
#                                         e.g. superpowers_verify_run
#
# Classified `recorder` / false_evidence_safe in hook-criticality.tsv: malformed input
# records nothing and exits 0. A missing record blocks at the next hard gate rather
# than being papered over here.
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true

INPUT="$(cat 2>/dev/null || true)"
[ -n "$INPUT" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

# Extract the invoked skill name, and refuse to extract anything from a tool response
# that reports a failure — a skill that errored did not do the work.
SKILL="$(printf '%s' "$INPUT" | python3 -c '
import json
import re
import sys

try:
    payload = json.load(sys.stdin)
except Exception:
    sys.exit(0)

name = payload.get("tool_name") or payload.get("tool") or ""
if name != "Skill":
    sys.exit(0)

response = payload.get("tool_response")
if isinstance(response, dict):
    # An explicit error, or a non-zero-ish status, means the skill did not run.
    if response.get("is_error") or response.get("isError") or response.get("error"):
        sys.exit(0)

tool_input = payload.get("tool_input") or {}
if not isinstance(tool_input, dict):
    sys.exit(0)
skill = tool_input.get("skill") or tool_input.get("name") or tool_input.get("skill_name") or ""
if not isinstance(skill, str):
    sys.exit(0)

# Plugin-qualified names arrive as "plugin:skill"; the skill is the addressable part.
skill = skill.strip().split(":")[-1]
skill = skill.lstrip("/")
canonical = re.sub(r"[^a-z0-9_-]+", "-", skill.lower()).strip("-")
if canonical:
    print(canonical)
' 2>/dev/null || printf '')"

[ -n "$SKILL" ] || exit 0

declare -f evidence_record >/dev/null 2>&1 || exit 0

evidence_record skill_used "$SKILL" 2>/dev/null || true
evidence_record "${SKILL//-/_}_run" 2>/dev/null || true

exit 0
