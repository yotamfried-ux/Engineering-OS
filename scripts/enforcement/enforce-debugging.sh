#!/usr/bin/env bash
# enforce-debugging.sh — deterministic enforcer for core/debugging-policy.md
#
# One enforcer per md file (Engineering OS convention). debugging-policy.md is
# largely judgment-based (Sentry-first, hypothesis, "3 attempts without progress",
# rollback) — this script enforces ONLY the rules in it that are deterministically
# checkable:
#
#   D1 (pretooluse, BLOCK)  — no verification bypass: `git commit --no-verify|-n`
#                             and `git push --no-verify`. Makes debugging-policy.md
#                             lines 82-84 ("עקיפה ... נחסמת ב-hook") actually true.
#   D2 (commit-msg, BLOCK)  — a `fix:` commit must add a regression test
#                             (debug_loop step 7 + quality-gates "eval מצטבר").
#   D3 (pretooluse, REMIND) — rollback commands → non-blocking reminder to document
#                             the failed attempt in failed-solutions/ (debug_loop 6,75).
#
# Invocations:
#   enforce-debugging.sh pretooluse         # reads PreToolUse stdin JSON (Bash tool)
#   enforce-debugging.sh commit-msg <file>  # reads the commit message file
#
# Wired from .claude/settings.json (PreToolUse Bash) and scripts/hooks/commit-msg.sh.
# Master bypass: EOS_BYPASS_DEBUG=1. Governing policy: core/debugging-policy.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/evidence.sh
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true

# Fallback if the lib failed to source — keep the enforcer self-contained.
if ! declare -f bypass_active >/dev/null 2>&1; then
  bypass_active() {
    local name="${1:-}"; [ -z "$name" ] && return 1
    case "${!name:-}" in 1|true|TRUE|yes|YES) return 0 ;; *) return 1 ;; esac
  }
fi

# Master bypass — disables the whole debugging enforcer.
bypass_active EOS_BYPASS_DEBUG && exit 0

# ─────────────────────────────────────────────────────────────────────────────
# D1 + D3 — PreToolUse (Bash): inspect the command about to run.
# ─────────────────────────────────────────────────────────────────────────────
do_pretooluse() {
  local INPUT CMD
  INPUT="$(cat 2>/dev/null || true)"
  CMD="$(printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    print(''); sys.exit(0)
t = d.get('tool_input', d)
print(t.get('command', '') or '')
" 2>/dev/null || printf '')"
  [ -z "$CMD" ] && exit 0

  # ── D1: block verification bypass ──────────────────────────────────────────
  # Tokenize the command (shlex) and drop the value that follows a message flag,
  # so a commit MESSAGE containing "-n"/"--no-verify" is not misread as a flag —
  # while a flag placed AFTER the message (git commit -m x --no-verify) is caught.
  local flag_toks
  flag_toks="$(printf '%s' "$CMD" | python3 -c '
import shlex, sys
try:
    toks = shlex.split(sys.stdin.read())
except Exception:
    toks = []
msg_flags = {"-m", "--message", "-F", "--file"}
out, skip = [], False
for tok in toks:
    if skip:
        skip = False
        continue
    if tok in msg_flags:
        skip = True
        continue
    out.append(tok)
print("\n".join(out))
' 2>/dev/null || printf '')"

  # git commit: both --no-verify and the short -n flag mean "skip hooks".
  # Anchor on the `commit` SUBCOMMAND (not the word) to avoid e.g. `git log --grep commit -n 5`.
  if printf '%s' "$CMD" | grep -qE '\bgit[[:space:]]+commit\b'; then
    if printf '%s\n' "$flag_toks" | grep -qE '^--no-verify$' \
       || printf '%s\n' "$flag_toks" | grep -qE '^-[A-Za-z]*n[A-Za-z]*$'; then
      bypass_active EOS_BYPASS_NOVERIFY && exit 0
      echo "ERROR_FOR_AGENT: debugging-policy.md — '--no-verify'/'-n' bypasses the commit hooks (lint/tests/format). This is forbidden as a debugging shortcut."
      echo "ACTION: fix the underlying failure the hook reports; do not skip verification. See core/debugging-policy.md <debug_loop> (lines 82-84)."
      echo "BYPASS: EOS_BYPASS_NOVERIFY=1 (or EOS_BYPASS_DEBUG=1) — only for a genuinely justified case."
      exit 1
    fi
  fi
  # git push: only --no-verify skips hooks (-n here means --dry-run; allowed).
  if printf '%s' "$CMD" | grep -qE '\bgit[[:space:]]+push\b'; then
    if printf '%s\n' "$flag_toks" | grep -qE '^--no-verify$'; then
      bypass_active EOS_BYPASS_NOVERIFY && exit 0
      echo "ERROR_FOR_AGENT: debugging-policy.md — 'git push --no-verify' bypasses pre-push verification. Forbidden as a shortcut."
      echo "ACTION: resolve the failing check instead of skipping it. See core/debugging-policy.md <debug_loop>."
      echo "BYPASS: EOS_BYPASS_NOVERIFY=1 (or EOS_BYPASS_DEBUG=1)."
      exit 1
    fi
  fi

  # ── D3: rollback reminder (non-blocking) ───────────────────────────────────
  # Anchor on the git SUBCOMMAND so "revert" inside a commit message doesn't fire.
  if printf '%s' "$CMD" | grep -qE '\bgit[[:space:]]+(reset[[:space:]]+--hard|revert\b|checkout[[:space:]]+--[[:space:]]|restore\b)'; then
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"🪲 debugging-policy <debug_loop>: rolling back? If this follows a failed fix, document the attempt + the falsified hypothesis in failed-solutions/ (step 75), and state an explicit root-cause hypothesis before the next attempt (step 6). Stop after 3 attempts with no new information."}}'
  fi
  exit 0
}

# ─────────────────────────────────────────────────────────────────────────────
# D2 — commit-msg: a `fix:` commit must add a regression test.
# ─────────────────────────────────────────────────────────────────────────────
do_commit_msg() {
  local msg_file="$1"
  [ -z "$msg_file" ] || [ ! -f "$msg_file" ] && exit 0

  local subject; subject="$(head -1 "$msg_file" 2>/dev/null)"
  # Only conventional-commit fix subjects (fix:, fix(scope):, fix!:).
  printf '%s' "$subject" | grep -qE '^fix(\([^)]*\))?!?:' || exit 0

  bypass_active EOS_BYPASS_FIXTEST && exit 0

  # Outside a git repo there is nothing to check (commit-msg always runs inside one).
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
  # --diff-filter=ACMR excludes Deletions, so a fix cannot satisfy the gate by deleting
  # a test: a deletion-only staged set yields no test match below and is correctly blocked.
  local staged; staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"

  # Does the staged set include at least one test file?
  if printf '%s' "$staged" | grep -qE '(\.(test|spec)\.(ts|tsx|js|jsx|py|go|rb)|(^|/)__tests__/|(^|/)tests?/|_test\.(py|go)|(^|/)test_[^/]*\.py)'; then
    exit 0
  fi

  echo "❌ COMMIT BLOCKED — a 'fix:' commit must add a regression test that reproduces the bug."
  echo "   debugging-policy.md <debug_loop> step 7: write a test that fails on the buggy code, fix the root cause, confirm it passes."
  echo "   Stage a test file (*.test.*, *.spec.*, __tests__/, tests/, *_test.go, test_*.py), or:"
  echo "   BYPASS: EOS_BYPASS_FIXTEST=1 git commit ...  (only if a regression test is genuinely impossible — justify in the message)."
  exit 1
}

# ── Route by subcommand ──────────────────────────────────────────────────────
MODE="${1:-pretooluse}"
case "$MODE" in
  pretooluse) do_pretooluse ;;
  commit-msg) do_commit_msg "${2:-}" ;;
  *) exit 0 ;;
esac
exit 0
