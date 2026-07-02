#!/usr/bin/env bash
set -euo pipefail

# enforce-run-trace.sh — deterministic gate for docs/operations/claude-run-trace.md.
#
# When staged changes modify enforcement, connector selection, settings, workflows,
# or simulations, the active Route Plan must contain a Claude Run Trace section.
# Connector-related changes require connector-specific trace evidence.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true
if ! declare -f bypass_active >/dev/null 2>&1; then
  bypass_active() {
    local name="${1:-}"; [ -z "$name" ] && return 1
    case "${!name:-}" in 1|true|TRUE|yes|YES) return 0 ;; *) return 1 ;; esac
  }
fi

bypass_active EOS_BYPASS_RUN_TRACE && exit 0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
[ -n "$staged" ] || exit 0

select_plan() {
  if [ -n "${EOS_ACTIVE_PLAN:-}" ] && [ -f "${EOS_ACTIVE_PLAN:-}" ]; then printf '%s\n' "$EOS_ACTIVE_PLAN"; return 0; fi
  if [ -f .claude/plans/active.md ]; then printf '%s\n' .claude/plans/active.md; return 0; fi
  local candidate
  for candidate in $(ls -t .claude/plans/*.md 2>/dev/null || true); do
    case "$(basename "$candidate")" in README.md|_TEMPLATE.md) continue ;; esac
    printf '%s\n' "$candidate"; return 0
  done
}

has_heading() {
  local file="$1" heading_re="$2"
  grep -qiE "^#{1,4}[[:space:]]+${heading_re}([[:space:]]|$)" "$file" 2>/dev/null
}

section_text() {
  local file="$1" heading_re="$2"
  awk -v re="$heading_re" '
    BEGIN { found=0 }
    /^#{1,4}[[:space:]]+/ {
      line=tolower($0)
      if (line ~ tolower(re)) { found=1; next }
      if (found) exit
    }
    found { print }
  ' "$file" 2>/dev/null || true
}

requires_trace=0
requires_connector_trace=0
code_count=0
while IFS= read -r path; do
  [ -n "$path" ] || continue
  case "$path" in
    scripts/enforcement/*|scripts/hooks/*|.claude/settings.json|.github/workflows/*|core/*|external-systems/*|patterns/*|templates/*|.claude/commands/*|evals/*|docs/operations/claude-run-trace.md)
      requires_trace=1 ;;
  esac
  case "$path" in
    *connector*|external-systems/*|core/connector-policy.md|.claude/settings.json|scripts/enforcement/post-tool-use-mcp.sh|scripts/enforcement/patch-settings-runtime-evidence.sh)
      requires_trace=1
      requires_connector_trace=1 ;;
  esac
  case "$path" in
    .claude/plans/*|docs/*|README.md|CHANGELOG.md|LICENSE*) ;;
    *) code_count=$((code_count + 1)) ;;
  esac
done <<EOF_STAGED
$staged
EOF_STAGED

# Size trigger: a significant agent run is also any staged range touching more
# than 5 code/config files, regardless of path.
[ "$code_count" -gt 5 ] && requires_trace=1

if printf '%s\n' "$staged" | grep -q '^docs/operations/claude-run-trace.md$'; then
  doc_blob="$(git show :docs/operations/claude-run-trace.md 2>/dev/null || true)"
  for heading in \
    'When to record a trace' \
    'Where traces live' \
    'Required fields' \
    'Notion progress validation' \
    'Relationship to learning' \
    'Enforcement contract'; do
    printf '%s\n' "$doc_blob" | grep -qiE "^#{1,4}[[:space:]]+${heading}([[:space:]]|$)" || {
      echo "run trace doc invalid: missing section '$heading'" >&2
      exit 1
    }
  done
fi

[ "$requires_trace" -eq 1 ] || exit 0

plan="$(select_plan || true)"
[ -n "$plan" ] || { echo "run trace required: no active Route Plan found" >&2; exit 1; }

if has_heading "$plan" 'Run[[:space:]]+Trace[[:space:]]+Waiver'; then
  # A waiver heading alone is not a waiver: the body must carry a concrete reason.
  waiver_body="$(section_text "$plan" 'run[[:space:]]+trace[[:space:]]+waiver' | sed -E '/^[[:space:]]*$/d; /^[[:space:]]*<!--/d')"
  if [ "$(printf '%s' "$waiver_body" | wc -c | tr -d ' ')" -ge 40 ] \
     && printf '%s\n' "$waiver_body" | grep -qiE 'reason|because|fallback|unavailable|scope'; then
    echo "run trace checks passed via focused waiver"
    exit 0
  fi
  echo "run trace waiver invalid: the waiver body must state a concrete reason (>=40 chars with reason/because/fallback/unavailable/scope)." >&2
  exit 1
fi

has_heading "$plan" '(Claude[[:space:]]+)?Run[[:space:]]+Trace' || {
  echo "run trace required: active plan must include ## Claude Run Trace" >&2
  echo "affected files:" >&2
  printf '%s\n' "$staged" >&2
  exit 1
}

trace="$(section_text "$plan" '(claude[[:space:]]+)?run[[:space:]]+trace')"
missing=""
for term in goal hypothesis connectors steps evidence rejected result follow-up; do
  printf '%s\n' "$trace" | grep -qi "$term" || missing="${missing}${term} "
done

if [ -n "$missing" ]; then
  echo "run trace incomplete: missing fields: ${missing}" >&2
  exit 1
fi

if [ "$requires_connector_trace" -eq 1 ]; then
  printf '%s\n' "$trace" | grep -qiE 'connector|github|notion|context7|sentry|postman|figma' || {
    echo "connector run trace required: trace must name connector decisions/evidence" >&2
    exit 1
  }
  printf '%s\n' "$trace" | grep -q 'notion_progress_validated' || {
    echo "connector run trace required: trace must mention notion_progress_validated evidence" >&2
    exit 1
  }
fi

echo "run trace checks passed"
