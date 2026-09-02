#!/usr/bin/env bash
# check-bash-runtime-evidence.sh — reconcile the operational runtime evidence view
# against the canonical test corpus.
#
# The gap this closes: Bash enforcement suites executed in CI and produced per-run
# receipts, but nothing represented them in the operational runtime evidence view. A
# suite could genuinely run and pass while the evidence path had no record that it did,
# and nothing failed as a result — the absence was invisible rather than detected.
#
# This checker is the detector. Run it after a full corpus run on the same head:
#
#   bash scripts/enforcement/run-enforcement-tests.sh
#   bash scripts/enforcement/check-bash-runtime-evidence.sh --require-complete
#
# Without --require-complete it reports coverage and still fails on evidence that is
# actively wrong (a suite recorded as failing, or a record naming a suite that is not
# in the discovered corpus). With --require-complete it additionally requires every
# discovered Bash suite to be represented, which is the CI contract on the exact head.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LEDGER="${EOS_EVIDENCE_DIR:-.claude/.evidence}/ledger"
REQUIRE_COMPLETE=0
JSON=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --require-complete) REQUIRE_COMPLETE=1 ;;
    --ledger) shift; LEDGER="${1:-}" ;;
    --json) JSON=1 ;;
    -h|--help)
      sed -n '2,20p' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    *)
      echo "❌ unknown argument: $1" >&2
      exit 2
      ;;
  esac
  shift
done

[ -n "$LEDGER" ] || { echo "❌ --ledger requires a path" >&2; exit 2; }

command -v python3 >/dev/null 2>&1 || {
  # Fail closed: without python3 the corpus cannot be discovered, and "cannot tell"
  # must never be reported as "complete".
  echo "ERROR_FOR_AGENT: python3 is unavailable, so Bash suite runtime evidence cannot be reconciled." >&2
  exit 1
}

args=(runtime-reconcile --root "$ROOT" --ledger "$LEDGER")
[ "$REQUIRE_COMPLETE" -eq 1 ] && args+=(--require-complete)
[ "$JSON" -eq 1 ] && args+=(--json)

if ! python3 "$ROOT/scripts/enforcement/test_evidence.py" "${args[@]}"; then
  cat >&2 <<'EOF_HINT'
ACTION: run the canonical corpus so the executing runner records each suite:
    bash scripts/enforcement/run-enforcement-tests.sh
Every suite it executes is recorded by scripts/enforcement/lib/test-run-evidence.sh
from inside the execution, so no command wrapper can suppress the record. If a suite
is still missing after a full run, its execution produced no runtime evidence — treat
that as the defect, not as an expected absence.
EOF_HINT
  exit 1
fi

if [ "$REQUIRE_COMPLETE" -eq 1 ]; then
  echo "✅ every discovered Bash enforcement suite is represented in operational runtime evidence"
fi
