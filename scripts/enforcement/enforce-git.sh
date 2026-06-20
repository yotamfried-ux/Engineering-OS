#!/usr/bin/env bash
# enforce-git.sh — deterministic enforcer for core/git-policy.md
#
# git-policy.md is mostly already enforced elsewhere (one-branch → settings.json
# PreToolUse; --no-verify → enforce-debugging D1; commit format → commit-msg hook;
# merge-to-main → human judgment by design, <safety> lines 132-135). This enforces
# the two remaining deterministic gaps, both as PreToolUse(Bash) command guards:
#
#   G1 (BLOCK) — `git push --force` / `-f` (plain). The destructive force that can
#                clobber others' history. `--force-with-lease` (the safe rebase
#                variant) is explicitly ALLOWED. Enforces <safety> line 123.
#   G2 (BLOCK) — `gh pr create --draft`. CodeRabbit skips draft PRs. Enforces
#                <pull_requests>.
#
# Invocation: enforce-git.sh pretooluse   (reads the tool-call JSON on stdin)
# Wired from .claude/settings.json PreToolUse(Bash) chain.
# Master bypass: EOS_BYPASS_GIT=1. Governing policy: core/git-policy.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/evidence.sh
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true
if ! declare -f bypass_active >/dev/null 2>&1; then
  bypass_active() {
    local name="${1:-}"; [ -z "$name" ] && return 1
    case "${!name:-}" in 1|true|TRUE|yes|YES) return 0 ;; *) return 1 ;; esac
  }
fi

bypass_active EOS_BYPASS_GIT && exit 0

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

  # Tokenize and drop the value following a message/body flag, so a PR body or
  # commit message containing "--force"/"--draft" is not misread as a flag.
  local toks
  toks="$(printf '%s' "$CMD" | python3 -c '
import shlex, sys
try:
    toks = shlex.split(sys.stdin.read())
except Exception:
    toks = []
val_flags = {"-m","--message","-F","--file","-t","--title","-b","--body","--body-file"}
out, skip = [], False
for tok in toks:
    if skip:
        skip = False
        continue
    if tok in val_flags:
        skip = True
        continue
    out.append(tok)
print("\n".join(out))
' 2>/dev/null || printf '')"

  # ── G1: block plain force-push (allow --force-with-lease) ───────────────────
  if printf '%s' "$CMD" | grep -qE '\bgit[[:space:]]+push\b'; then
    if printf '%s\n' "$toks" | grep -qE '^--force$' \
       || printf '%s\n' "$toks" | grep -qE '^-[A-Za-z]*f[A-Za-z]*$'; then
      bypass_active EOS_BYPASS_FORCEPUSH && exit 0
      echo "ERROR_FOR_AGENT: git-policy.md <safety> — 'git push --force' can overwrite others' history and needs explicit human approval."
      echo "ACTION: prefer 'git push --force-with-lease' (refuses to clobber unseen upstream commits), which is allowed."
      echo "BYPASS: EOS_BYPASS_FORCEPUSH=1 (or EOS_BYPASS_GIT=1) — only with the owner's explicit go-ahead."
      exit 1
    fi
  fi

  # ── G2: block draft PR creation ─────────────────────────────────────────────
  if printf '%s' "$CMD" | grep -qE '\bgh[[:space:]]+pr[[:space:]]+create\b'; then
    if printf '%s\n' "$toks" | grep -qE '^--draft$'; then
      bypass_active EOS_BYPASS_DRAFTPR && exit 0
      echo "ERROR_FOR_AGENT: git-policy.md <pull_requests> — PRs must be opened ready-for-review, not as drafts. CodeRabbit and other auto-reviewers skip draft PRs."
      echo "ACTION: run 'gh pr create' without --draft. If CI must gate review, use a 'wip' label instead."
      echo "BYPASS: EOS_BYPASS_DRAFTPR=1 (or EOS_BYPASS_GIT=1)."
      exit 1
    fi
  fi

  exit 0
}

MODE="${1:-pretooluse}"
case "$MODE" in
  pretooluse) do_pretooluse ;;
  *) exit 0 ;;
esac
exit 0
