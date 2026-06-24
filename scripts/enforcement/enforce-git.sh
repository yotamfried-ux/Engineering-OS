#!/usr/bin/env bash
# enforce-git.sh — deterministic enforcer for core/git-policy.md
#
# git-policy.md is mostly already enforced elsewhere (one-branch → settings.json
# PreToolUse; --no-verify → enforce-debugging D1; commit format → commit-msg hook;
# merge-to-main → human judgment by design, <safety> lines 132-135). This enforces
# deterministic git/PR safety gaps as PreToolUse(Bash) command guards:
#
#   G1 (BLOCK) — `git push --force` / `-f` (plain). The destructive force that can
#                clobber others' history. `--force-with-lease` (the safe rebase
#                variant) is explicitly ALLOWED. Enforces <safety> line 123.
#   G2 (BLOCK) — `gh pr create --draft`. CodeRabbit skips draft PRs. Enforces
#                <pull_requests>.
#   G3 (BLOCK) — direct push to main/master (`git push origin main`, `HEAD:main`).
#                All main changes must flow through reviewed PRs.
#   G4 (BLOCK) — GitHub Contents API writes to default branch via `gh api`.
#                If a branch is omitted, GitHub writes to the default branch.
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
  # Emits: G1/G2/G3/G4 or "" (allowed).
  local VERDICT
  VERDICT="$(printf '%s' "$CMD" | python3 -c '
import shlex, sys
try:
    t = shlex.split(sys.stdin.read())
except Exception:
    t = []

def short_force(a):
    return len(a) >= 2 and a[0] == "-" and a[1] != "-" and "f" in a[1:]

def is_main_ref(a):
    return a in {"main", "master", "refs/heads/main", "refs/heads/master"} or a.endswith(":main") or a.endswith(":master")

def skip_git_globals(tokens):
    gval = {"-c","-C","--git-dir","--work-tree","--namespace","--config-env","--exec-path","--super-prefix"}
    i = 1
    while i < len(tokens):
        if tokens[i] in gval:
            i += 2; continue
        if tokens[i].startswith("-"):
            i += 1; continue
        break
    return i

def skip_gh_globals(tokens):
    ghval = {"-R","--repo","--hostname"}
    i = 1
    while i < len(tokens) and tokens[i].startswith("-"):
        i += 2 if tokens[i] in ghval else 1
    return i

verdict = ""
if t and t[0] == "git":
    i = skip_git_globals(t)
    if i < len(t) and t[i] == "push":
        args = t[i+1:]
        for a in args:
            if a == "--force" or short_force(a):
                verdict = "G1"; break
        if not verdict:
            for a in args:
                if is_main_ref(a):
                    verdict = "G3"; break
elif t and t[0] == "gh":
    i = skip_gh_globals(t)
    if i + 1 < len(t) and t[i] == "pr" and t[i+1] == "create":
        vval = {"-t","--title","-b","--body","-F","--body-file","-H","--head","-B","--base",
                "-l","--label","-a","--assignee","-r","--reviewer","-p","--project","-m","--milestone","-T","--template"}
        args, j = t[i+2:], 0
        while j < len(args):
            a = args[j]
            if a in vval:
                j += 2; continue
            if a in ("--draft","-d"):
                verdict = "G2"; break
            j += 1
    elif i < len(t) and t[i] == "api":
        args = t[i+1:]
        path = ""
        method = "GET"
        branch = None
        j = 0
        val_flags = {"-H","--header","-F","--field","-f","--raw-field","--input","--preview"}
        while j < len(args):
            a = args[j]
            if a in {"-X", "--method"} and j + 1 < len(args):
                method = args[j+1].upper(); j += 2; continue
            if a in {"-F","--field","-f","--raw-field"} and j + 1 < len(args):
                v = args[j+1]
                if v.startswith("branch="):
                    branch = v.split("=", 1)[1]
                j += 2; continue
            if a in val_flags:
                j += 2; continue
            if not a.startswith("-") and not path:
                path = a
            j += 1
        if "/contents/" in path and method in {"POST", "PUT", "PATCH", "DELETE"}:
            if branch in (None, "", "main", "master"):
                verdict = "G4"
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
    G3)
      bypass_active EOS_BYPASS_MAINPUSH && exit 0
      echo "ERROR_FOR_AGENT: git-policy.md <safety> — direct push to main/master is blocked."
      echo "ACTION: push a feature branch and open a PR; merge only after CI, review, and explicit user approval."
      echo "BYPASS: EOS_BYPASS_MAINPUSH=1 (or EOS_BYPASS_GIT=1) — only for emergency owner-approved repairs."
      exit 1
      ;;
    G4)
      bypass_active EOS_BYPASS_CONTENTS_API && exit 0
      echo "ERROR_FOR_AGENT: git-policy.md <safety> — GitHub Contents API write to the default branch is blocked."
      echo "ACTION: include -f branch=<feature-branch> or use normal branch/PR workflow."
      echo "BYPASS: EOS_BYPASS_CONTENTS_API=1 (or EOS_BYPASS_GIT=1) — only with explicit owner approval."
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
