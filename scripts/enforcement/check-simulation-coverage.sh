#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COVERAGE_FILE="${1:-$ROOT/scripts/enforcement/simulation-coverage.tsv}"
REQUIRED_GATES_FILE="${EOS_SIM_COVERAGE_REQUIRED_GATES_FILE:-$ROOT/scripts/enforcement/coverage-required-gates.tsv}"
MIN_ROWS="${EOS_SIM_COVERAGE_MIN_ROWS:-8}"

failures=0
seen="$(mktemp)"
combined="$(mktemp)"
required_seen="$(mktemp)"
required_active="$(mktemp)"
trap 'rm -f "$seen" "$combined" "$required_seen" "$required_active"' EXIT

fail() { echo "simulation coverage failed: $*" >&2; failures=1; }
resolve_path() { case "$1" in /*) printf '%s\n' "$1" ;; *) printf '%s/%s\n' "$ROOT" "$1" ;; esac; }

require_repo_file() {
  local gate="$1" label="$2" path="$3"
  case "$path" in NONE|none|n/a|N/A) return 0 ;; esac
  [ -f "$(resolve_path "$path")" ] || fail "$gate: $label file not found: $path"
}

validate_cell() {
  local gate="$1" kind="$2" cell="$3" test_file="$4"
  case "$cell" in
    covered:*)
      local token="${cell#covered:}"
      [ "$(printf '%s' "$token" | wc -c | tr -d ' ')" -ge 3 ] || { fail "$gate: $kind coverage token is too short"; return; }
      case "$test_file" in NONE|none|n/a|N/A) fail "$gate: $kind is marked covered but no test_file is provided"; return ;; esac
      grep -Fq "$token" "$(resolve_path "$test_file")" 2>/dev/null || fail "$gate: $kind coverage token '$token' not found in $test_file"
      ;;
    waived:*)
      local reason="${cell#waived:}"
      [ "$(printf '%s' "$reason" | wc -c | tr -d ' ')" -ge 20 ] || fail "$gate: $kind waiver reason is too short"
      ;;
    *) fail "$gate: $kind must be covered:<token> or waived:<specific reason>" ;;
  esac
}

freshness_prose() {
  # Only surface prose meant for human review (waiver reasons); literal
  # covered:<token> values are exact test-file tokens, not deferred prose,
  # so they must not trip the stale-language scan below.
  case "$1" in
    covered:*) printf '' ;;
    waived:*) printf '%s' "${1#waived:}" ;;
    *) printf '%s' "$1" ;;
  esac
}

validate_freshness() {
  local gate="$1" text="$2"
  if printf '%s\n' "$text" | grep -Eiq '\b(future loop|pending|not yet|todo|tbd)\b'; then
    fail "$gate: coverage row contains deferred-language; use a coverage token or a by-design reason"
  fi
}

load_required_gates() {
  : > "$required_active"
  if [ -n "${EOS_SIM_COVERAGE_REQUIRED_GATES:-}" ]; then
    IFS=',' read -r -a required <<< "$EOS_SIM_COVERAGE_REQUIRED_GATES"
    for gate in "${required[@]}"; do printf '%s\n' "$gate" | xargs >> "$required_active"; done
    return 0
  fi
  [ -f "$REQUIRED_GATES_FILE" ] || { fail "required gates manifest missing: $REQUIRED_GATES_FILE"; return 0; }
  while IFS=$'\t' read -r gate owner status reason extra; do
    case "${gate:-}" in ''|'#'*) continue ;; esac
    if [ -n "${extra:-}" ]; then fail "$gate: required gates manifest has too many columns"; continue; fi
    [ -n "$gate" ] && [ -n "$owner" ] && [ -n "$status" ] && [ -n "$reason" ] || { fail "$gate: required gates manifest missing field"; continue; }
    if grep -Fxq "$gate" "$required_seen" 2>/dev/null; then fail "$gate: duplicate required gate"; fi
    printf '%s\n' "$gate" >> "$required_seen"
    case "$status" in
      active) printf '%s\n' "$gate" >> "$required_active" ;;
      waived) [ "$(printf '%s' "$reason" | wc -c | tr -d ' ')" -ge 25 ] || fail "$gate: required gate waiver reason is too short" ;;
      *) fail "$gate: invalid required gate status '$status'" ;;
    esac
  done < "$REQUIRED_GATES_FILE"
}

[ -f "$COVERAGE_FILE" ] || { echo "missing simulation coverage manifest: $COVERAGE_FILE" >&2; exit 1; }
cat "$COVERAGE_FILE" > "$combined"
extra_dir="${COVERAGE_FILE%.tsv}.d"
if [ -d "$extra_dir" ]; then
  for extra_file in "$extra_dir"/*.tsv; do
    [ -f "$extra_file" ] || continue
    printf '\n' >> "$combined"
    cat "$extra_file" >> "$combined"
  done
fi

row_count=0
while IFS=$'\t' read -r gate owner enforcer test_file positive negative invalid waiver notes extra; do
  case "${gate:-}" in ''|'#'*) continue ;; esac
  row_count=$((row_count + 1))
  if [ -n "${extra:-}" ]; then fail "$gate: too many columns; expected 9 tab-separated fields"; continue; fi
  for field_name in gate owner enforcer test_file positive negative invalid waiver notes; do
    value="${!field_name:-}"; [ -n "$value" ] || fail "$gate: missing required field '$field_name'"
  done
  validate_freshness "$gate" "$(freshness_prose "$positive") $(freshness_prose "$negative") $(freshness_prose "$invalid") $(freshness_prose "$waiver") $notes"
  printf '%s' "$gate" | grep -Eq '[[:space:]]' && fail "$gate: gate_id must not contain whitespace"
  grep -Fxq "$gate" "$seen" 2>/dev/null && fail "$gate: duplicate gate_id"
  printf '%s\n' "$gate" >> "$seen"
  require_repo_file "$gate" enforcer "$enforcer"
  require_repo_file "$gate" test_file "$test_file"
  validate_cell "$gate" positive "$positive" "$test_file"
  validate_cell "$gate" negative "$negative" "$test_file"
  validate_cell "$gate" invalid "$invalid" "$test_file"
  validate_cell "$gate" waiver "$waiver" "$test_file"
done < "$combined"

[ "$row_count" -ge "$MIN_ROWS" ] || fail "expected at least $MIN_ROWS simulation coverage rows, found $row_count"
load_required_gates
while IFS= read -r gate; do
  gate="$(printf '%s' "$gate" | xargs)"
  [ -n "$gate" ] || continue
  grep -Fxq "$gate" "$seen" 2>/dev/null || fail "missing required simulation coverage gate: $gate"
done < "$required_active"

[ "$failures" -eq 0 ] || exit 1
echo "simulation coverage checks passed ($row_count gates)"
