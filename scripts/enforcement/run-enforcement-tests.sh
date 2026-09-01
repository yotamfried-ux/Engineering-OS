#!/usr/bin/env bash
# run-enforcement-tests.sh — canonical failure-propagating runner for EOS Bash suites.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVIDENCE_DIR="${EOS_TEST_EVIDENCE_DIR:-$ROOT/.engineering-os/test-evidence}"
RECEIPT_FILE="${EOS_TEST_RECEIPT_FILE:-$EVIDENCE_DIR/receipts.jsonl}"
HEAD_SHA="${EOS_TEST_HEAD_SHA:-${GITHUB_SHA:-}}"
if [ -z "$HEAD_SHA" ]; then
  HEAD_SHA="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || printf 'unknown')"
fi

FIXTURE_MODE=0
if [ "${1:-}" = "--fixture" ]; then
  FIXTURE_MODE=1
  shift
fi

if [ "$#" -gt 0 ]; then
  TESTS=("$@")
else
  [ "$FIXTURE_MODE" -eq 0 ] || { echo "❌ --fixture requires explicit test paths" >&2; exit 1; }
  shopt -s nullglob
  TESTS=("$ROOT"/scripts/enforcement/tests/test-*.sh)
  shopt -u nullglob
fi

if [ "${#TESTS[@]}" -eq 0 ]; then
  echo "❌ no enforcement test suites found" >&2
  exit 1
fi

mkdir -p "$EVIDENCE_DIR/logs"
fail=0
count=0
for test_path in "${TESTS[@]}"; do
  case "$test_path" in
    /*) abs_test="$test_path" ;;
    *) abs_test="$ROOT/$test_path" ;;
  esac
  if [ ! -f "$abs_test" ]; then
    echo "❌ enforcement test not found: $test_path" >&2
    fail=1
    continue
  fi
  rel_test="${abs_test#$ROOT/}"
  if [ "$FIXTURE_MODE" -eq 0 ]; then
    case "$rel_test" in
      scripts/enforcement/tests/test-*.sh) ;;
      *)
        echo "❌ canonical runner refuses non-corpus test path: $test_path" >&2
        fail=1
        continue
        ;;
    esac
  fi

  count=$((count + 1))
  if [ "$FIXTURE_MODE" -eq 1 ]; then
    echo "──────── fixture: $test_path ────────"
    if bash "$abs_test"; then :; else fail=1; fi
    continue
  fi

  attempt="$(python3 "$ROOT/scripts/enforcement/test_evidence.py" next-attempt \
    --root "$ROOT" --receipt-file "$RECEIPT_FILE" --test-path "$rel_test")" || {
      echo "❌ failed to allocate evidence attempt for $rel_test" >&2
      fail=1
      continue
    }
  safe_name="$(printf '%s' "$rel_test" | tr '/: ' '___')"
  log="$EVIDENCE_DIR/logs/${safe_name}.attempt-${attempt}.log"
  start_ms="$(date +%s%3N)"

  echo "──────── $rel_test ────────"
  if bash "$abs_test" >"$log" 2>&1; then
    result=pass
  else
    result=fail
    fail=1
  fi
  cat "$log"
  end_ms="$(date +%s%3N)"
  duration_ms=$((end_ms - start_ms))

  if ! python3 "$ROOT/scripts/enforcement/test_evidence.py" record \
      --root "$ROOT" \
      --receipt-file "$RECEIPT_FILE" \
      --test-path "$rel_test" \
      --runner "scripts/enforcement/run-enforcement-tests.sh" \
      --result "$result" \
      --log-path "$log" \
      --head-sha "$HEAD_SHA" \
      --attempt "$attempt" \
      --duration-ms "$duration_ms" >/dev/null; then
    echo "❌ failed to record execution receipt for $rel_test" >&2
    fail=1
  fi
done

echo
if [ "$fail" -ne 0 ]; then
  if [ "$FIXTURE_MODE" -eq 1 ]; then
    echo "❌ one or more fixture enforcement suites failed"
  else
    echo "❌ one or more enforcement suites failed or lacked trustworthy receipts"
  fi
  exit 1
fi

if [ "$FIXTURE_MODE" -eq 1 ]; then
  echo "✅ all $count fixture enforcement suites passed"
else
  echo "✅ all $count enforcement suites passed with execution receipts"
fi
