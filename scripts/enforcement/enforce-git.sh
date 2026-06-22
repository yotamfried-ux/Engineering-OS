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

  # Classify from the parsed token stream (shlex), not raw text. We skip the
  # program's GLOBAL options (which may take a value) to find the real subcommand
  # — so `git -c k=v push --force` and `gh --repo o/r pr create --draft` are still
  # caught — and skip VALUE-taking flags when scanning args, so a `--force`/`--draft`
  # sitting inside a --body/--title/-m value is not misread as a flag.
  # Emits: "G1" (plain force-push), "G2" (draft PR), or "" (allowed).
  local VERDICT
  VERDICT="$(printf '%s' "$CMD" | python3 -c '
import shlex, sys
try:
    t = shlex.split(sys.stdin.read())
except Exception:
    t = []

def short_force(a):  # short cluster containing f: -f, -fu … (not a long --flag)
    return len(a) >= 2 and a[0] == "-" and a[1] != "-" and "f" in a[1:]

verdict = ""
if t and t[0] == "git":
    gval = {"-c","-C","--git-dir","--work-tree","--namespace","--config-env","--exec-path","--super-prefix"}
    i = 1
    while i < len(t):
        if t[i] in gval: i += 2; continue
        if t[i].startswith("-"): i += 1; continue
        break
    if i < len(t) and t[i] == "push":
        for a in t[i+1:]:
            if a == "--force" or short_force(a):
                verdict = "G1"; break
elif t and t[0] == "gh":
    ghval = {"-R","--repo","--hostname"}
    i = 1
    while i < len(t) and t[i].startswith("-"):
        i += 2 if t[i] in ghval else 1
    if i + 1 < len(t) and t[i] == "pr" and t[i+1] == "create":
        vval = {"-t","--title","-b","--body","-F","--body-file","-H","--head","-B","--base",
                "-l","--label","-a","--assignee","-r","--reviewer","-p","--project","-m","--milestone","-T","--template"}
        args, j = t[i+2:], 0
        while j < len(args):
            a = args[j]
            if a in vval: j += 2; continue
            if a in ("--draft","-d"):
                verdict = "G2"; break
            j += 1
print(verdict)
' 2>/dev/null || printf '')"

  case "$VERDICT" in
    G1)
      bypass_active EOS_BYPASS_FORCEPUSH && exit 0
      echo "ERROR_FOR_AGENT: git-policy.md <safety> — 'git push --force' can overwrite others' history and needs explicit human approval."
      echo "ACTION: prefer 'git push --force-with-lease' (refuses to clobber unseen upstream commits), which is allowed."
      echo "BYPASS: EOS_BYPASS_FORCEPUSH=1 (or EOS_BYPASS_GIT=1) — only with the owner's explicit go-ahead."
      exit 1
      ;;
    G2)
      bypass_active EOS_BYPASS_DRAFTPR && exit 0
      echo "ERROR_FOR_AGENT: git-policy.md <pull_requests> — PRs must be opened ready-for-review, not as drafts. CodeRabbit and other auto-reviewers skip draft PRs."
      echo "ACTION: run 'gh pr create' without --draft (and without -d). If CI must gate review, use a 'wip' label instead."
      echo "BYPASS: EOS_BYPASS_DRAFTPR=1 (or EOS_BYPASS_GIT=1)."
      exit 1
      ;;
  esac

  # G6c: gh pr create requires reading core/maintenance-routine.md this session.
  # Checked AFTER VERDICT so G2 blocks and EOS_BYPASS_DRAFTPR take priority.
  # Uses shlex token parsing (same approach as VERDICT) to avoid substring false-positives.
  if printf '%s' "$CMD" | python3 -c '
import shlex, sys
try:
    t = shlex.split(sys.stdin.read())
except Exception:
    t = []
ok = False
if t and t[0] == "gh":
    ghval = {"-R","--repo","--hostname"}
    i = 1
    while i < len(t) and t[i].startswith("-"):
        i += 2 if t[i] in ghval else 1
    ok = i + 1 < len(t) and t[i] == "pr" and t[i+1] == "create"
print("1" if ok else "")
' 2>/dev/null | grep -q '^1$'; then
    evidence_has read_maintenance_routine 2>/dev/null || {
      echo "ERROR_FOR_AGENT: core/maintenance-routine.md not read in this session."
      echo "ACTION: read core/maintenance-routine.md (PR checklist) before creating a PR."
      echo "BYPASS: EOS_BYPASS_GIT=1"
      exit 1
    }
  fi

  exit 0
}

MODE="${1:-pretooluse}"
case "$MODE" in
  pretooluse) do_pretooluse ;;
  *) exit 0 ;;
esac
exit 0
