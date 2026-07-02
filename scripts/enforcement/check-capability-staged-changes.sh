#!/usr/bin/env bash
# check-capability-staged-changes.sh — staged-change guard for the capability registry.
#
# Changed files imply capabilities via capability-staged-map.tsv (high-confidence
# path prefixes only). Every implied capability must appear in the Capability
# Evidence or Capability Waiver section of at least one changed Route Plan.
# Stale declared capabilities are deliberately NOT failed (false-block risk);
# only missing implied capabilities fail. Map rows must reference capability ids
# that exist in core/capability-registry.yaml, so the map cannot go stale.
#
# Usage:
#   check-capability-staged-changes.sh [base] [head]           # git-range mode (CI)
#   check-capability-staged-changes.sh --files-from <list> --plan <plan.md> [...]
#                                      [--map <tsv>] [--registry <yaml>]  # fixture mode
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MAP="$SCRIPT_DIR/capability-staged-map.tsv"
REGISTRY="$ROOT/core/capability-registry.yaml"
FILES_FROM=""
PLANS=()
BASE="HEAD~1"
HEAD_REF="HEAD"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --files-from) FILES_FROM="${2:-}"; shift 2 ;;
    --plan) PLANS+=("${2:-}"); shift 2 ;;
    --map) MAP="${2:-}"; shift 2 ;;
    --registry) REGISTRY="${2:-}"; shift 2 ;;
    --*) echo "unknown argument: $1" >&2; exit 2 ;;
    *) BASE="$1"; HEAD_REF="${2:-HEAD}"; [ "$#" -ge 2 ] && shift 2 || shift ;;
  esac
done

[ -f "$MAP" ] || { echo "missing capability staged map: $MAP" >&2; exit 2; }
[ -f "$REGISTRY" ] || { echo "missing capability registry: $REGISTRY" >&2; exit 2; }

# Validate the map: two columns, and every capability id exists in the registry.
map_bad=0
while IFS=$'\t' read -r prefix cap extra; do
  case "${prefix:-}" in ''|'#'*) continue ;; esac
  if [ -n "${extra:-}" ] || [ -z "${cap:-}" ]; then
    echo "capability staged map malformed: row for '$prefix' must have exactly 2 columns" >&2
    map_bad=1
    continue
  fi
  grep -qE "^  ${cap//./\\.}:" "$REGISTRY" || {
    echo "capability staged map malformed: '$cap' not found in capability registry" >&2
    map_bad=1
  }
done < "$MAP"
[ "$map_bad" -eq 0 ] || exit 2

if [ -n "$FILES_FROM" ]; then
  [ -f "$FILES_FROM" ] || { echo "missing --files-from list: $FILES_FROM" >&2; exit 2; }
  changed="$(cat "$FILES_FROM")"
else
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git repository and no --files-from given" >&2; exit 2; }
  changed="$(git diff --name-only "$BASE" "$HEAD_REF")"
  while IFS= read -r plan; do
    case "$plan" in .claude/plans/*.md) [ -f "$plan" ] && PLANS+=("$plan") ;; esac
  done <<EOF_CHANGED
$changed
EOF_CHANGED
fi

# Collect implied capabilities from changed non-plan files.
implied=""
while IFS= read -r file; do
  [ -n "$file" ] || continue
  case "$file" in .claude/plans/*) continue ;; esac
  while IFS=$'\t' read -r prefix cap _extra; do
    case "${prefix:-}" in ''|'#'*) continue ;; esac
    case "$file" in
      "$prefix"*)
        case " $implied " in *" $cap "*) ;; *) implied="$implied $cap" ;; esac
        ;;
    esac
  done < "$MAP"
done <<EOF_FILES
$changed
EOF_FILES

implied="${implied# }"
if [ -z "$implied" ]; then
  echo "capability staged-change checks passed (no implied capabilities)"
  exit 0
fi

# Gather Capability Evidence + Capability Waiver text from changed plans.
plan_capability_text() {
  local plan="$1"
  awk '
    /^#{1,6}[[:space:]]+Capability (Evidence|Waiver)/ { on=1; next }
    on && /^#{1,6}[[:space:]]+/ { on=0 }
    on { print }
  ' "$plan" 2>/dev/null
}

evidence_text=""
for plan in ${PLANS[@]+"${PLANS[@]}"}; do
  [ -f "$plan" ] || continue
  evidence_text="${evidence_text}
$(plan_capability_text "$plan")"
done

if [ -z "$(printf '%s' "$evidence_text" | tr -d '[:space:]')" ]; then
  echo "ERROR_FOR_AGENT: staged changes imply capabilities [$implied] but no changed Route Plan carries Capability Evidence/Waiver text." >&2
  echo "ACTION: add the implied capability ids to the active plan's Capability Evidence, or waive them with a reason." >&2
  exit 1
fi

missing=""
for cap in $implied; do
  esc_cap="$(printf '%s' "$cap" | sed 's/[.[\*^$]/\\&/g')"
  printf '%s' "$evidence_text" | grep -qE "(^|[^A-Za-z0-9_.-])${esc_cap}([^A-Za-z0-9_.-]|\$)" || missing="${missing}${cap} "
done

if [ -n "$missing" ]; then
  echo "ERROR_FOR_AGENT: staged changes imply capabilities that no changed plan declares or waives: ${missing}" >&2
  echo "ACTION: add each missing capability id to Capability Evidence, or list it in Capability Waiver with a focused reason." >&2
  exit 1
fi

echo "capability staged-change checks passed (${implied})"
