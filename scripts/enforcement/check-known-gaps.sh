#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FILE="${1:-$ROOT/docs/operations/known-gaps.tsv}"
[ -f "$FILE" ] || { echo "known gaps failed: missing $FILE" >&2; exit 1; }
seen="$(mktemp)"; trap 'rm -f "$seen"' EXIT
fail=0
err(){ echo "known gaps failed: $*" >&2; fail=1; }
resolve(){ case "$1" in NONE|none|n/a|N/A) return 1;; /*) printf '%s\n' "$1";; *) printf '%s/%s\n' "$ROOT" "$1";; esac; }
rows=0
while IFS=$'\t' read -r gap owner status priority risk mitigation test closure evidence notes extra; do
  case "${gap:-}" in ''|'#'*) continue ;; esac
  rows=$((rows+1))
  [ -z "${extra:-}" ] || { err "$gap: too many columns"; continue; }
  for f in gap owner status priority risk mitigation test closure evidence notes; do
    v="${!f:-}"; [ -n "$v" ] || err "$gap: missing $f"
  done
  echo "$gap" | grep -Eq '[[:space:]]' && err "$gap: gap_id must not contain whitespace"
  grep -Fxq "$gap" "$seen" 2>/dev/null && err "$gap: duplicate gap_id"
  printf '%s\n' "$gap" >> "$seen"
  case "$status" in open|mitigated|closed|accepted-manual|blocked) : ;; *) err "$gap: invalid status $status" ;; esac
  case "$priority" in P0|P1|P2|P3) : ;; *) err "$gap: invalid priority $priority" ;; esac
  [ "$(printf '%s' "$risk" | wc -c | tr -d ' ')" -ge 20 ] || err "$gap: risk too short"
  [ "$(printf '%s' "$mitigation" | wc -c | tr -d ' ')" -ge 20 ] || err "$gap: mitigation too short"
  [ "$(printf '%s' "$closure" | wc -c | tr -d ' ')" -ge 20 ] || err "$gap: closure too short"
  tp="$(resolve "$test" || true)"; [ -z "$tp" ] || [ -f "$tp" ] || err "$gap: test file not found: $test"
  ep="$(resolve "$evidence" || true)"; [ -z "$ep" ] || [ -e "$ep" ] || err "$gap: evidence path not found: $evidence"
  if [ "$status" = closed ]; then
    echo "$closure" | grep -qiE 'merged|verified|closed|done|complete' || err "$gap: closed gap needs closure proof"
  fi
done < "$FILE"
[ "$rows" -ge "${EOS_KNOWN_GAPS_MIN_ROWS:-5}" ] || err "expected at least ${EOS_KNOWN_GAPS_MIN_ROWS:-5} rows, found $rows"
[ "$fail" -eq 0 ] || exit 1
echo "known gaps checks passed ($rows gaps)"
