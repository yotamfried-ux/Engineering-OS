#!/usr/bin/env bash
# test-plan-freshness-clone-safety.sh — plan recency and freshness must survive a clone.
#
# Every case here is built so that the pre-fix implementation (`ls -t` for selection,
# `stat %Y` for age) gets it wrong: the fixtures give plans identical or deliberately
# inverted mtimes relative to their real git history. The final scenario asserts the
# old behaviour explicitly, so this suite cannot silently start passing if someone
# reintroduces an mtime-based path.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
LIB="$ROOT/scripts/enforcement/lib/plan-time.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fails=0
ok()   { echo "ok: $1"; }
bad()  { echo "fail: $1"; fails=$((fails + 1)); }
check(){ # check <name> <expected> <actual>
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$2', got '$3')"; fi
}

HOUR=3600
NOW="$(date -u +%s)"

iso() { date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ; }

write_plan() { # write_plan <path> <timestamp-line-or-empty> <targets>
  mkdir -p "$(dirname "$1")"
  {
    echo "# Route Plan — $(basename "$1" .md)"
    echo
    echo "Plan Scope: standard"
    [ -n "$2" ] && echo "$2"
    echo
    echo "| Field | Value |"
    echo "|---|---|"
    echo "| Target paths | ${3:-scripts} |"
  } > "$1"
}

commit_plan() { # commit_plan <repo> <path> <epoch>
  ( cd "$1"
    git add -A >/dev/null 2>&1
    GIT_AUTHOR_DATE="@$3 +0000" GIT_COMMITTER_DATE="@$3 +0000" \
      git commit -q -m "add $2" >/dev/null 2>&1
  )
}

new_repo() { # new_repo <dir>
  mkdir -p "$1"
  ( cd "$1"
    git init -q .
    git config user.email t@example.com
    git config user.name  Test
    git config commit.gpgsign false
  )
}

# Simulate what `git clone` does to a checkout: every tracked file gets the same,
# brand-new mtime regardless of when it was actually last changed.
flatten_mtimes() { find "$1/.claude/plans" -name '*.md' -exec touch -m {} + ; }

run_in() { ( cd "$1" && . "$LIB" && shift && "$@" ); }

# ─────────────────────────────────────────────────────────────────────────────
# 1. Clone flattening: identical mtimes must not decide which plan is newest.
#    'aaa-old' sorts first alphabetically and is 30 days older in git; the fix must
#    still pick 'zzz-new'. Pre-fix, `ls -t` tie-breaks arbitrarily on the flat mtimes.
# ─────────────────────────────────────────────────────────────────────────────
R1="$TMP/clone"
new_repo "$R1"
write_plan "$R1/.claude/plans/aaa-old.md" "" "scripts"
commit_plan "$R1" "aaa-old.md" "$(( NOW - 30*24*HOUR ))"
write_plan "$R1/.claude/plans/zzz-new.md" "" "scripts"
commit_plan "$R1" "zzz-new.md" "$(( NOW - 1*HOUR ))"
flatten_mtimes "$R1"

check "clone with flattened mtimes still selects the git-newest plan" \
  ".claude/plans/zzz-new.md" "$(run_in "$R1" eos_newest_plan)"

check "clone-flattened old plan reports its real age, not 0h" \
  "720" "$(run_in "$R1" eos_plan_age_hours .claude/plans/aaa-old.md)"

# The pre-fix path, asserted directly: with flattened mtimes every plan looks 0h old.
pre_fix_age="$( cd "$R1" && echo $(( ( $(date +%s) - $(stat -c %Y .claude/plans/aaa-old.md) ) / 3600 )) )"
check "pre-fix mtime age on the same fixture is wrong (proves the regression bites)" \
  "0" "$pre_fix_age"

# ─────────────────────────────────────────────────────────────────────────────
# 2. Inverted order: the git-older plan is given the NEWER mtime. Selection must
#    follow git history, not the filesystem.
# ─────────────────────────────────────────────────────────────────────────────
R2="$TMP/inverted"
new_repo "$R2"
write_plan "$R2/.claude/plans/git-newer.md" "" "scripts"
commit_plan "$R2" "git-newer.md" "$(( NOW - 2*HOUR ))"
write_plan "$R2/.claude/plans/git-older.md" "" "scripts"
commit_plan "$R2" "git-older.md" "$(( NOW - 20*24*HOUR ))"
touch -m -d "@$(( NOW - 60 ))" "$R2/.claude/plans/git-older.md"
touch -m -d "@$(( NOW - 8*HOUR ))" "$R2/.claude/plans/git-newer.md"

check "mtime newer but git older does not win selection" \
  ".claude/plans/git-newer.md" "$(run_in "$R2" eos_newest_plan)"
check "pre-fix ls -t on the same fixture picks the wrong plan" \
  ".claude/plans/git-older.md" "$( cd "$R2" && ls -t .claude/plans/*.md | head -1 )"

# ─────────────────────────────────────────────────────────────────────────────
# 3. Declared timestamp governs a plan that git cannot date.
# ─────────────────────────────────────────────────────────────────────────────
R3="$TMP/declared"
new_repo "$R3"

write_plan "$R3/.claude/plans/untracked.md" "Plan Timestamp: $(iso $(( NOW - 5*HOUR )))" "scripts"
check "untracked plan uses its declared timestamp" \
  "5" "$(run_in "$R3" eos_plan_age_hours .claude/plans/untracked.md)"

write_plan "$R3/.claude/plans/table-form.md" "" "scripts"
printf '| Plan Timestamp | %s |\n' "$(iso $(( NOW - 9*HOUR )))" >> "$R3/.claude/plans/table-form.md"
check "declared timestamp is accepted in route-plan table form" \
  "9" "$(run_in "$R3" eos_plan_age_hours .claude/plans/table-form.md)"

# A tracked plan edited in the working tree is newer than its last commit, so the
# declared timestamp — not the stale commit time — must govern.
write_plan "$R3/.claude/plans/edited.md" "Plan Timestamp: $(iso $(( NOW - 300*HOUR )))" "scripts"
commit_plan "$R3" "edited.md" "$(( NOW - 300*HOUR ))"
sed -i "s#^Plan Timestamp: .*#Plan Timestamp: $(iso $(( NOW - 1*HOUR )))#" "$R3/.claude/plans/edited.md"
check "locally modified tracked plan uses its refreshed declared timestamp" \
  "1" "$(run_in "$R3" eos_plan_age_hours .claude/plans/edited.md)"

# ─────────────────────────────────────────────────────────────────────────────
# 4. Fail closed: an undatable plan must never resolve as fresh.
# ─────────────────────────────────────────────────────────────────────────────
R4="$TMP/invalid"
new_repo "$R4"

expect_reason() { # expect_reason <name> <plan> <token>
  local got
  got="$(run_in "$R4" eos_plan_timestamp "$2" 2>/dev/null || true)"
  check "$1" "$3" "$got"
}

write_plan "$R4/.claude/plans/no-stamp.md" "" "scripts"
expect_reason "untracked plan with no timestamp is refused" .claude/plans/no-stamp.md missing-timestamp

write_plan "$R4/.claude/plans/bad-stamp.md" "Plan Timestamp: last Tuesday" "scripts"
expect_reason "unparseable timestamp is refused" .claude/plans/bad-stamp.md invalid-timestamp

write_plan "$R4/.claude/plans/date-only.md" "Plan Timestamp: 2026-09-02" "scripts"
expect_reason "date without a UTC instant is refused" .claude/plans/date-only.md invalid-timestamp

write_plan "$R4/.claude/plans/future.md" "Plan Timestamp: $(iso $(( NOW + 48*HOUR )))" "scripts"
expect_reason "future timestamp is refused (would be fresh forever)" .claude/plans/future.md future-timestamp

expect_reason "missing plan file is refused" .claude/plans/does-not-exist.md missing-file

# An undatable plan must not be silently dropped from the corpus either: it still has
# to be reachable so the gate can name the real reason instead of "no plan exists".
check "every undatable plan remains listed (sorted last)" \
  "4" "$(run_in "$R4" eos_plans_by_recency | wc -l | tr -d ' ')"

# ─────────────────────────────────────────────────────────────────────────────
# 5. Ordering is total: equal timestamps fall back to path, never to mtime.
# ─────────────────────────────────────────────────────────────────────────────
R5="$TMP/tie"
new_repo "$R5"
SAME="$(iso $(( NOW - 3*HOUR )))"
for n in b-plan a-plan c-plan; do
  write_plan "$R5/.claude/plans/$n.md" "Plan Timestamp: $SAME" "scripts"
done
touch -m -d "@$(( NOW - 30 ))" "$R5/.claude/plans/c-plan.md"   # newest mtime, must not win
check "equal timestamps tie-break on path, not mtime" \
  ".claude/plans/a-plan.md" "$(run_in "$R5" eos_newest_plan)"
check "repeated calls are stable" \
  "$(run_in "$R5" eos_newest_plan)" "$(run_in "$R5" eos_newest_plan)"

# ─────────────────────────────────────────────────────────────────────────────
# 6. The live repository itself must be datable — no plan may be undatable on main.
# ─────────────────────────────────────────────────────────────────────────────
for plan in "$ROOT"/.claude/plans/*.md; do
  [ -f "$plan" ] || continue
  name="$(basename "$plan")"
  case "$name" in README.md|_TEMPLATE.md) continue ;; esac
  if ( cd "$ROOT" && . "$LIB" && eos_plan_timestamp ".claude/plans/$name" >/dev/null ); then
    ok "live plan $name is datable"
  else
    bad "live plan $name is not datable: $( cd "$ROOT" && . "$LIB" && eos_plan_time_reason ".claude/plans/$name" )"
  fi
done

mtime_violations="$(ROOT="$ROOT" python3 - <<'PY'
import ast
import os
import re
from pathlib import Path

root = Path(os.environ["ROOT"])
production_roots = (".github", "scripts", "templates")
extensions = {".bash", ".js", ".mjs", ".py", ".ps1", ".sh", ".ts", ".yaml", ".yml"}
plan_reference = re.compile(r"(?:\.claude[/\\]plans|\bplans?\b)", re.IGNORECASE)
mtime_read = re.compile(
    r"(?:\bls\b[^#\n]*(?:\s-[A-Za-z]*t[A-Za-z]*\b|--sort(?:=|\s+)time\b)|"
    r"\bstat\b[^#\n]*(?:%Y|%m)|\bos\.path\.getmtime\b|\bst_mtime(?:_ns)?\b|"
    r"\bmtimeMs\b|\bLastWriteTime\b|\bfind\b[^#\n]*-printf[^#\n]*%T)",
    re.IGNORECASE,
)

for relative_root in production_roots:
    base = root / relative_root
    if not base.exists():
        continue
    for path in sorted(base.rglob("*")):
        if not path.is_file() or path.suffix not in extensions or "tests" in path.parts:
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        ignored_lines = set()
        if path.suffix == ".py":
            try:
                tree = ast.parse(text)
                for node in (tree, *ast.walk(tree)):
                    body = getattr(node, "body", ())
                    if isinstance(body, (list, tuple)) and body and isinstance(body[0], ast.Expr) and isinstance(body[0].value, ast.Constant) and isinstance(body[0].value.value, str):
                        ignored_lines.update(range(body[0].lineno, body[0].end_lineno + 1))
            except SyntaxError:
                pass
        for line_number, line in enumerate(text.splitlines(), 1):
            stripped = line.lstrip()
            if line_number in ignored_lines or stripped.startswith(("#", "//")):
                continue
            if plan_reference.search(line) and mtime_read.search(line):
                print(f"{path.relative_to(root)}:{line_number}:{line.strip()}")
PY
)"
if [ -z "$mtime_violations" ]; then
  ok "production plan readers never use filesystem mtime"
else
  bad "production plan reader bypasses canonical resolver"
  printf '%s\n' "$mtime_violations"
fi

if [ "$fails" -ne 0 ]; then
  echo "FAILED: $fails check(s)"
  exit 1
fi
echo "PASSED: plan freshness clone-safety"
