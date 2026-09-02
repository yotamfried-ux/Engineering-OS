#!/usr/bin/env bash
# test-run-evidence.sh — canonical owner of "an Engineering OS test suite executed".
#
# Why this exists: operational evidence used to key on an *incidental mechanism* —
# the exact text of the Bash command that happened to start a suite. A `cd` prefix,
# a pipe, a redirect or an `&&` chain changed the command text without changing the
# work, so the suite ran, passed, and left no runtime record. Since virtually every
# real invocation is wrapped, the miss was the common case rather than the edge.
#
# The fix is to record from inside the execution. run-enforcement-tests.sh already
# *is* the component that runs each suite, so it — not a matcher guessing from a
# command string — is the evidence producer. No wrapper can change what it records,
# because the wrapper is not part of the decision.
#
# Source it:
#   . "$(dirname "$0")/lib/test-run-evidence.sh"
#
# Records (through lib/evidence.sh, so the ledger contract is unchanged):
#   bash_suite_run  <corpus-relative-path>:<pass|fail>   — one per executed suite
#   tests_run       <corpus-relative-path>               — only for a passing suite
#
# `tests_run` keeps its bare-key semantics: `evidence_has tests_run` still matches a
# line that carries a value, so the G11 pre-commit gate and the Stop hook summary are
# unaffected by the added suite id.

_EOS_TEST_RUN_EVIDENCE_LIB_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"

if ! declare -f evidence_record >/dev/null 2>&1; then
  # shellcheck source=evidence.sh
  . "$_EOS_TEST_RUN_EVIDENCE_LIB_DIR/evidence.sh" 2>/dev/null || true
fi

# eos_suite_id <path> [root]
# Print the corpus-relative id of a suite path, or fail when the path is not a member
# of the canonical corpus. Membership is decided by location and filename shape — the
# same contract discover() applies in test_evidence.py — so a fixture script in a
# temporary directory can never be recorded as a corpus suite.
eos_suite_id() {
  local path="${1:-}" root="${2:-}" rel
  [ -n "$path" ] || return 1
  if [ -z "$root" ]; then
    root="$(CDPATH= cd -- "$_EOS_TEST_RUN_EVIDENCE_LIB_DIR/../../.." 2>/dev/null && pwd -P)" || return 1
  fi
  root="${root%/}"
  case "$path" in
    /*) rel="${path#"$root"/}" ;;
    *) rel="${path#./}" ;;
  esac
  # An absolute path outside the root still starts with "/" after the strip attempt
  # above, so it simply fails the corpus-shape test below rather than matching.
  case "$rel" in
    scripts/enforcement/tests/test-*.sh|scripts/enforcement/tests/test-*.py) ;;
    *) return 1 ;;
  esac
  # Reject any traversal segment so a crafted path cannot present itself as a member.
  case "$rel" in
    *..*) return 1 ;;
  esac
  printf '%s' "$rel"
}

# eos_suite_evidence_enabled — exit 0 when recording suite-run evidence is legitimate.
#
# Recording is suppressed for:
#   * EOS_SUITE_EVIDENCE_DISABLED=1 — the explicit off switch. The negative fixture
#     uses it to prove that a suppressed record is DETECTED by the reconciler rather
#     than silently tolerated. It can only ever remove evidence, so it cannot make a
#     gate pass that would otherwise fail.
#   * a nested runner (EOS_SUITE_RUN_ACTIVE=1) — a corpus suite that itself invokes
#     the runner must not write corpus evidence on behalf of the outer session.
eos_suite_evidence_enabled() {
  [ "${EOS_SUITE_EVIDENCE_DISABLED:-0}" = "1" ] && return 1
  [ "${EOS_SUITE_RUN_ACTIVE:-0}" = "1" ] && return 1
  return 0
}

# eos_record_suite_run <suite-path> <pass|fail> [root]
# Record that a corpus suite executed and how it ended. Returns non-zero *without*
# recording when the path is not a corpus member or the result is not a known terminal
# outcome — a recorder must never invent evidence from a malformed call.
eos_record_suite_run() {
  local path="${1:-}" result="${2:-}" root="${3:-}" suite
  case "$result" in
    pass|fail) ;;
    *) return 1 ;;
  esac
  suite="$(eos_suite_id "$path" "$root")" || return 1
  [ -n "$suite" ] || return 1
  eos_suite_evidence_enabled || return 0
  declare -f evidence_record >/dev/null 2>&1 || return 1
  evidence_record bash_suite_run "${suite}:${result}" || return 1
  if [ "$result" = "pass" ]; then
    evidence_record tests_run "$suite" || return 1
  fi
  return 0
}
