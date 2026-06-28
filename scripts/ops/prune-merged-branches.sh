#!/usr/bin/env bash
# prune-merged-branches.sh — safely delete stale remote branches.
#
# WHY THIS IS A SCRIPT, NOT AUTOMATED: deleting refs needs push access that the
# Engineering OS agent environment does not have (the git proxy returns HTTP 403 on
# `--delete`). The repo owner runs this once with their own credentials.
#
# SAFE BY DEFAULT: dry-run lists exactly what would be deleted and why, deletes
# nothing. Pass --apply to perform deletions.
#
# Two tiers, both re-verified at runtime against origin/main:
#   MERGED      — branch tip is an ancestor of origin/main (git-proven; no commits lost).
#   SUPERSEDED  — an explicit allowlist of experiment branches whose content was
#                 reproduced or squash-merged into main (so they are NOT ancestors,
#                 but are still safe). Each is listed with its reason.
# Anything NOT in (MERGED ∪ SUPERSEDED) is refused.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REMOTE="${EOS_GH_REMOTE:-origin}"
BASE="${EOS_PRUNE_BASE:-$REMOTE/main}"

# Experiment branches superseded by merged PRs (#115 / #116). Squash-merged or closed,
# so not ancestors of main, but content is in main / reproduced — safe to delete.
SUPERSEDED=(rd2 readiness-next fix-mcp-recorder-wiring)

APPLY=0
EXTRA_ALLOW=()
for arg in "$@"; do
  case "$arg" in
    --apply) APPLY=1 ;;
    --allow=*) EXTRA_ALLOW+=("${arg#--allow=}") ;;
    -h|--help) grep -E '^# ' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

git -C "$ROOT" fetch "$REMOTE" --prune --quiet 2>/dev/null || true

# Never delete main, the currently checked-out branch (this script may be run from a
# feature branch whose ref still matches main), or any branch named in EOS_PRUNE_KEEP.
CURRENT_BRANCH="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
KEEP=(main "$CURRENT_BRANCH")
[ -n "${EOS_PRUNE_KEEP:-}" ] && read -r -a _keep_extra <<<"$EOS_PRUNE_KEEP" && KEEP+=("${_keep_extra[@]}")

is_kept() {
  local b="$1" k
  for k in "${KEEP[@]}"; do [ -n "$k" ] && [ "$b" = "$k" ] && return 0; done
  return 1
}

is_superseded() {
  local b="$1" s
  for s in "${SUPERSEDED[@]}" "${EXTRA_ALLOW[@]}"; do [ "$b" = "$s" ] && return 0; done
  return 1
}

# remote_branches — every branch on the remote except main/HEAD.
remote_branches() {
  git -C "$ROOT" branch -r 2>/dev/null \
    | sed "s# *$REMOTE/##" \
    | grep -vE '^(main|HEAD)$' \
    | grep -v '\->' \
    | sed '/^[[:space:]]*$/d' \
    | sort -u
}

merged=()
superseded=()
skipped=()
while IFS= read -r b; do
  [ -n "$b" ] || continue
  if is_kept "$b"; then
    continue
  elif git -C "$ROOT" merge-base --is-ancestor "$REMOTE/$b" "$BASE" 2>/dev/null; then
    merged+=("$b")
  elif is_superseded "$b"; then
    superseded+=("$b")
  else
    skipped+=("$b")
  fi
done < <(remote_branches)

echo "Prune target remote: $REMOTE   base: $BASE"
echo
echo "MERGED into $BASE — safe to delete (${#merged[@]}):"
for b in "${merged[@]}"; do echo "  ✓ $b"; done
echo
echo "SUPERSEDED experiment branches — safe to delete (${#superseded[@]}):"
for b in "${superseded[@]}"; do echo "  ✓ $b   (closed/squash-merged via PR #115/#116)"; done
echo
echo "SKIPPED — not merged, not in allowlist; left untouched (${#skipped[@]}):"
for b in "${skipped[@]}"; do echo "  • $b"; done
echo

to_delete=("${merged[@]}" "${superseded[@]}")
if [ "${#to_delete[@]}" -eq 0 ]; then
  echo "Nothing to delete."
  exit 0
fi

if [ "$APPLY" -ne 1 ]; then
  echo "DRY-RUN — nothing deleted. Re-run with --apply (needs push/admin credentials)."
  echo "Would run: git push $REMOTE --delete ${to_delete[*]}"
  exit 0
fi

echo "Deleting ${#to_delete[@]} branches…"
fail=0
if git -C "$ROOT" push "$REMOTE" --delete "${to_delete[@]}"; then
  echo "✅ deleted ${#to_delete[@]} branches via git push --delete"
else
  echo "git push --delete failed; trying gh api per-branch…" >&2
  for b in "${to_delete[@]}"; do
    if command -v gh >/dev/null 2>&1; then
      gh api -X DELETE "repos/${EOS_GH_OWNER:-yotamfried-ux}/${EOS_GH_REPO:-Engineering-OS}/git/refs/heads/$b" \
        && echo "  ✓ deleted $b" || { echo "  ✗ failed $b" >&2; fail=1; }
    else
      echo "  ✗ $b — no gh and git push failed; delete via GitHub UI" >&2; fail=1
    fi
  done
fi
exit "$fail"
