#!/usr/bin/env bash
# test-no-grep-c-echo.sh — regression guard against the `grep -c ... || echo 0`
# anti-pattern in enforcement / session scripts.
#
# Root cause it guards: `grep -c PAT` prints "0" AND exits 1 when there are no
# matches, so `grep -c PAT || echo 0` appends a SECOND "0" → the variable holds
# "0\n0" and a later `[ "$VAR" -gt 0 ]` fails with "integer expression expected".
# This bit session-setup.sh:128 (visible every SessionStart) and the Stop hook
# in .claude/settings.json. The correct form handles the exit code separately:
#   VAR=$(... | grep -c PAT) || VAR=0
#
# Run: bash scripts/enforcement/tests/test-no-grep-c-echo.sh
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; }

echo "── static scan: no 'grep -c ... || echo' anti-pattern ──"
# Scan the scripts that feed integer tests + the live hooks config.
# `grep -c` followed (on the same logical command) by `|| echo` is the bug.
TARGETS=(
  "$ROOT/scripts"
  "$ROOT/.claude/settings.json"
)
HITS="$(grep -rEn "grep -c[E]?[^|]*\|\| *echo" "${TARGETS[@]}" \
          --include='*.sh' --include='settings.json' 2>/dev/null \
        | grep -v 'test-no-grep-c-echo.sh' \
        | grep -vE ':[0-9]+:[[:space:]]*#' || true)"
if [ -z "$HITS" ]; then
  ok "no 'grep -c ... || echo' found in scripts/ or settings.json"
else
  bad "found 'grep -c ... || echo' anti-pattern:"
  printf '%s\n' "$HITS" | sed 's/^/      /'
fi

echo "── behavior: correct form yields a single-line 0 on no match ──"
# The buggy form: produces two lines.
BUGGY="$(printf 'a\nb\n' | grep -c "zzz-no-match" || echo 0)"
buggy_lines="$(printf '%s' "$BUGGY" | wc -l | tr -d ' ')"
# wc -l counts newlines; "0\n0" has 1 newline → buggy_lines == 1 means 2 values.
[ "$buggy_lines" = "1" ] && ok "buggy form reproduced (proves the hazard is real)" \
  || bad "buggy form did not reproduce (got '$BUGGY')"

# The fixed form: single value, and usable in an arithmetic test without error.
GOOD="$(printf 'a\nb\n' | grep -c "zzz-no-match")" || GOOD=0
good_lines="$(printf '%s' "$GOOD" | wc -l | tr -d ' ')"
[ "$good_lines" = "0" ] && ok "fixed form yields a single line" \
  || bad "fixed form yielded multiple lines (got '$GOOD')"

# A valid integer makes [ -gt ] return 0/1; a malformed "0\n0" returns 2 (error).
[ "${GOOD:-0}" -gt 0 ] 2>/dev/null; arith_rc=$?
[ "$arith_rc" -ne 2 ] && ok "fixed form is a valid integer in [ -gt ] (no error)" \
  || bad "fixed form broke the integer test (rc=$arith_rc)"

echo
echo "════════ $PASS passed, $FAIL failed ════════"
[ "$FAIL" -eq 0 ]
