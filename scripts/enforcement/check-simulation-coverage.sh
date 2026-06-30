#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COVERAGE_FILE="${1:-$ROOT/scripts/enforcement/simulation-coverage.tsv}"
REQUIRED_GATES="${EOS_SIM_COVERAGE_REQUIRED_GATES:-simulation-coverage,workflow-plan-quality,workflow-semantic-quality,progress-lifecycle,connector-evidence,required-connectors,required-skills,runtime-evidence,learning-capture,run-trace,rtk-context,readiness-audit,use-in-project-contract}"

failures=0
seen="$(mktemp)"

fail() {
  echo "simulation coverage failed: $*" >&2
  failures=1
}

resolve_path() {
  local path="$1"
  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$ROOT" "$path" ;;
  esac
}

require_repo_file() {
  local gate="$1" label="$2" path="$3"
  case "$path" in
    NONE|none|n/a|N/A) return 0 ;;
  esac
  local resolved
  resolved="$(resolve_path "$path")"
  [ -f "$resolved" ] || fail "$gate: $label file not found: $path"
}

validate_cell() {
  local gate="$1" kind="$2" cell="$3" test_file="$4"
  case "$cell" in
    covered:*)
      local token="${cell#covered:}"
      if [ "$(printf '%s' "$token" | wc -c | tr -d ' ')" -lt 3 ]; then
        fail "$gate: $kind coverage token is too short"
        return 0
      fi
      case "$test_file" in
        NONE|none|n/a|N/A)
          fail "$gate: $kind is marked covered but no test_file is provided"
          return 0
          ;;
      esac
      local resolved_test
      resolved_test="$(resolve_path "$test_file")"
      if ! grep -Fq "$token" "$resolved_test" 2>/dev/null; then
        fail "$gate: $kind coverage token '$token' not found in $test_file"
      fi
      ;;
    waived:*)
      local reason="${cell#waived:}"
      if [ "$(printf '%s' "$reason" | wc -c | tr -d ' ')" -lt 20 ]; then
        fail "$gate: $kind waiver reason is too short"
      fi
      ;;
    *)
      fail "$gate: $kind must be covered:<token> or waived:<specific reason>"
      ;;
  esac
}

[ -f "$COVERAGE_FILE" ] || { echo "missing simulation coverage manifest: $COVERAGE_FILE" >&2; exit 1; }

row_count=0
while IFS=$'\t' read -r gate owner enforcer test_file positive negative invalid waiver notes extra; do
  case "${gate:-}" in ''|'#'*) continue ;; esac
  row_count=$((row_count + 1))

  if [ -n "${extra:-}" ]; then
    fail "$gate: too many columns; expected 9 tab-separated fields"
    continue
  fi
  for field_name in gate owner enforcer test_file positive negative invalid waiver notes; do
    value="${!field_name:-}"
    [ -n "$value" ] || fail "$gate: missing required field '$field_name'"
  done

  if printf '%s' "$gate" | grep -Eq '[[:space:]]'; then
    fail "$gate: gate_id must not contain whitespace"
  fi
  if grep -Fxq "$gate" "$seen" 2>/dev/null; then
    fail "$gate: duplicate gate_id"
  fi
  printf '%s\n' "$gate" >> "$seen"

  require_repo_file "$gate" enforcer "$enforcer"
  require_repo_file "$gate" test_file "$test_file"
  validate_cell "$gate" positive "$positive" "$test_file"
  validate_cell "$gate" negative "$negative" "$test_file"
  validate_cell "$gate" invalid "$invalid" "$test_file"
  validate_cell "$gate" waiver "$waiver" "$test_file"
done < "$COVERAGE_FILE"

if [ "$row_count" -lt 8 ]; then
  fail "expected at least 8 simulation coverage rows, found $row_count"
fi

IFS=',' read -r -a required <<< "$REQUIRED_GATES"
for gate in "${required[@]}"; do
  gate="$(printf '%s' "$gate" | xargs)"
  [ -n "$gate" ] || continue
  grep -Fxq "$gate" "$seen" 2>/dev/null || fail "missing required simulation coverage gate: $gate"
done

if [ "$failures" -ne 0 ]; then
  exit 1
fi

echo "simulation coverage checks passed ($row_count gates)"
