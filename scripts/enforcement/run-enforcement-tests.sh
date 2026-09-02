#!/usr/bin/env bash
# run-enforcement-tests.sh — canonical failure-propagating runner for EOS Bash suites.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Runtime evidence is recorded from inside the execution, not inferred from the command
# that started it. A `cd` prefix, an `&&` chain, a pipe or a redirect changes the
# command text without changing the work, so a matcher reading that text reports a real
# run as "did not happen". Here the runner records what it actually ran.
# Deliberately non-fatal when absent: the runner's job is to run suites and emit
# receipts, and a missing evidence helper must not take that down. A missing record is
# not silently tolerated either — check-bash-runtime-evidence.sh reconciles the ledger
# against the discovered corpus and fails when a suite ran without one.
# shellcheck source=lib/test-run-evidence.sh
. "$ROOT/scripts/enforcement/lib/test-run-evidence.sh" 2>/dev/null || true
HEAD_SHA="${EOS_TEST_HEAD_SHA:-${GITHUB_SHA:-}}"
if [ -z "$HEAD_SHA" ]; then
  HEAD_SHA="$(git -C "$ROOT" rev-parse HEAD 2>/dev/null || printf 'unknown')"
fi
safe_head="$(printf '%s' "$HEAD_SHA" | tr -cd 'A-Za-z0-9._-')"
[ -n "$safe_head" ] || safe_head=unknown
EVIDENCE_DIR="${EOS_TEST_EVIDENCE_DIR:-$ROOT/.engineering-os/test-evidence/$safe_head}"
RECEIPT_FILE="${EOS_TEST_RECEIPT_FILE:-$EVIDENCE_DIR/receipts.jsonl}"

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
  # Attempt numbers are report metadata, not a safe filesystem lock. Use the
  # filesystem's atomic exclusive-create primitive so nested/concurrent
  # runners cannot ever select the same backing log, even with identical
  # clocks, random seeds, or container PIDs.
  log="$(mktemp "$EVIDENCE_DIR/logs/${safe_name}.attempt-${attempt}.run-XXXXXXXX.log")" || {
    echo "❌ failed to allocate immutable evidence log for $rel_test" >&2
    fail=1
    continue
  }
  start_ms="$(date +%s%3N)"

  echo "──────── $rel_test ────────"
  # EOS_SUITE_RUN_ACTIVE marks the nesting boundary: a corpus suite that invokes this
  # runner itself must not write corpus evidence on behalf of the outer session.
  if EOS_SUITE_RUN_ACTIVE=1 bash "$abs_test" >"$log" 2>&1; then
    result=pass
  else
    result=fail
    fail=1
  fi
  if declare -f eos_record_suite_run >/dev/null 2>&1; then
    eos_record_suite_run "$rel_test" "$result" "$ROOT" || true
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
