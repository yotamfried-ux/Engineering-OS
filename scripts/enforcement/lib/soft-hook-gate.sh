#!/usr/bin/env bash
# soft-hook-gate.sh — observable fail-open runner for advisory/recorder hook units.
set -u
set -o pipefail

EVENT="unknown"
UNIT=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --event) EVENT="${2:-unknown}"; shift 2 ;;
    --unit) UNIT="${2:-}"; shift 2 ;;
    --) shift; break ;;
    *) printf 'WARNING_FOR_AGENT: soft hook runner received an unexpected argument: %s\n' "$1" >&2; exit 0 ;;
  esac
done
ARGS=("$@")

observe() {
  local code="$1" message="$2"
  local root log
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  log="$root/.engineering-os/hook-errors.log"
  mkdir -p "$(dirname "$log")" 2>/dev/null || true
  printf '%s\tevent=%s\tunit=%s\texit=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || printf unknown-time)" "$EVENT" "${UNIT##*/}" "$code" >>"$log" 2>/dev/null || true
  printf 'WARNING_FOR_AGENT: %s\n' "$message" >&2
}

if [ -z "$UNIT" ] || [ ! -f "$UNIT" ] || [ -L "$UNIT" ] || [ ! -r "$UNIT" ]; then
  observe 127 "Engineering OS soft hook unit is missing or unreadable: ${UNIT:-<empty>}"
  exit 0
fi

TMP="$(mktemp -d 2>/dev/null || true)"
if [ -z "$TMP" ]; then
  observe 125 "Engineering OS soft hook could not create a temporary directory for ${UNIT##*/}."
  exit 0
fi
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
cat >"$TMP/input" 2>/dev/null || true
set +e
bash "$UNIT" "${ARGS[@]}" <"$TMP/input" >"$TMP/out" 2>"$TMP/err"
CODE=$?
if [ "$CODE" -ne 0 ]; then
  observe "$CODE" "Engineering OS ${EVENT} ${UNIT##*/} failed open as explicitly classified; see .engineering-os/hook-errors.log."
fi
exit 0
