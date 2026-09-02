#!/usr/bin/env bash
# plan-time.sh — canonical, clone-safe resolution of "when was this plan last current?".
#
# Why this exists: filesystem mtime describes the *checkout*, not the plan. A fresh
# `git clone` stamps every tracked plan with the clone time, so `ls -t` degenerates to an
# arbitrary tie-break and a plan committed months ago reports an age of 0h. Both the
# freshness gate and plan selection then act on a plan unrelated to the current task.
# This is the temporal counterpart of KG7 in core/hooks-policy.md: KG7 covers a plan that
# is genuinely fresh but semantically irrelevant; this library covers a plan that is stale
# yet reported fresh.
#
# Resolution order for a single plan:
#   1. tracked in git and clean in the working tree → last-commit time of that path.
#      Committed history survives cloning and is not rewritten by a checkout.
#   2. untracked, or tracked with uncommitted modifications → the plan's own declared
#      `| Plan Timestamp | <ISO-8601 UTC> |` field. A plan being written right now has no
#      useful git time, so it must state when it was made current.
#   3. otherwise → failure, with a machine-readable reason on stdout. Callers that gate
#      writes must treat failure as a block, never as "fresh".
#
# A declared timestamp is rejected when it is absent, unparseable, or in the future
# (beyond EOS_PLAN_CLOCK_SKEW_S, default 300s) — a future stamp would make a plan
# permanently fresh, which is the failure mode this library exists to prevent.

# Guard against double-sourcing (several hooks source both this and evidence.sh).
[ -n "${_EOS_PLAN_TIME_SH:-}" ] && return 0
_EOS_PLAN_TIME_SH=1

EOS_PLAN_DIR_DEFAULT=".claude/plans"

# ─────────────────────────────────────────────────────────────────────────────
# eos_plan_declared_timestamp <plan_file>
#   Echoes epoch seconds for the plan's declared `Plan Timestamp`.
#   Returns non-zero and echoes nothing when absent or unparseable.
#
#   Accepts the route-plan table form and a plain field form:
#     | Plan Timestamp | 2026-09-02T00:41:02Z |
#     Plan Timestamp: 2026-09-02T00:41:02Z
# ─────────────────────────────────────────────────────────────────────────────
eos_plan_declared_timestamp() {
  local pf="$1" raw epoch
  [ -f "$pf" ] || return 1

  raw="$(sed -n -E '
    s/^[[:space:]]*\|[[:space:]]*[Pp]lan[[:space:]]+[Tt]imestamp[[:space:]]*\|[[:space:]]*([^|[:space:]]+)[[:space:]]*\|.*$/\1/p
    s/^[[:space:]]*[-*]?[[:space:]]*[Pp]lan[[:space:]]+[Tt]imestamp[[:space:]]*:[[:space:]]*([^[:space:]]+).*$/\1/p
  ' "$pf" 2>/dev/null | head -1)"
  [ -n "$raw" ] || return 1

  # Require an explicit UTC ISO-8601 instant. A bare date or a local-time string would
  # make the parsed value depend on the reader's timezone.
  printf '%s' "$raw" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' || return 1

  epoch="$(date -u -d "$raw" +%s 2>/dev/null \
        || date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$raw" +%s 2>/dev/null)" || return 1
  [ -n "$epoch" ] || return 1
  printf '%s' "$epoch"
}

# ─────────────────────────────────────────────────────────────────────────────
# eos_plan_git_timestamp <plan_file>
#   Echoes epoch seconds of the last commit that touched the path, but only when the
#   path is tracked AND has no uncommitted modifications. A locally edited plan is
#   deliberately excluded: its committed time understates how current it is.
# ─────────────────────────────────────────────────────────────────────────────
eos_plan_git_timestamp() {
  local pf="$1" epoch
  [ -f "$pf" ] || return 1
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  git ls-files --error-unmatch -- "$pf" >/dev/null 2>&1 || return 1
  # Non-empty diff output means the working copy differs from HEAD.
  [ -z "$(git diff --name-only HEAD -- "$pf" 2>/dev/null)" ] || return 1
  epoch="$(git log -1 --format=%ct -- "$pf" 2>/dev/null)"
  [ -n "$epoch" ] || return 1
  printf '%s' "$epoch"
}

# ─────────────────────────────────────────────────────────────────────────────
# eos_plan_timestamp <plan_file>
#   Echoes epoch seconds on success (exit 0).
#   On failure echoes a stable reason token (exit 1):
#     missing-file | missing-timestamp | invalid-timestamp | future-timestamp
#   Never falls back to filesystem mtime and never falls back to "now" — either would
#   silently report a stale plan as fresh.
# ─────────────────────────────────────────────────────────────────────────────
eos_plan_timestamp() {
  local pf="$1" epoch now skew
  if [ -z "$pf" ] || [ ! -f "$pf" ]; then printf 'missing-file'; return 1; fi

  if epoch="$(eos_plan_git_timestamp "$pf")"; then
    printf '%s' "$epoch"; return 0
  fi

  if ! epoch="$(eos_plan_declared_timestamp "$pf")"; then
    # Distinguish "no field at all" from "field present but unusable" so the operator is
    # told what to fix.
    if grep -qiE '^[[:space:]]*[|[:space:]-]*plan[[:space:]]+timestamp[[:space:]]*[|:]' "$pf" 2>/dev/null; then
      printf 'invalid-timestamp'
    else
      printf 'missing-timestamp'
    fi
    return 1
  fi

  now="$(date -u +%s 2>/dev/null || echo 0)"
  skew="${EOS_PLAN_CLOCK_SKEW_S:-300}"
  printf '%s' "$skew" | grep -qE '^[0-9]+$' || skew=300
  if [ "$epoch" -gt "$(( now + skew ))" ]; then
    printf 'future-timestamp'; return 1
  fi

  printf '%s' "$epoch"
}

# ─────────────────────────────────────────────────────────────────────────────
# eos_plan_time_reason <plan_file>
#   Human-facing sentence for a failed resolution; empty when resolution succeeds.
# ─────────────────────────────────────────────────────────────────────────────
eos_plan_time_reason() {
  local out
  out="$(eos_plan_timestamp "$1")" && return 0
  case "$out" in
    missing-file)      printf 'plan file not found' ;;
    missing-timestamp) printf "plan is not committed and declares no '| Plan Timestamp | <ISO-8601 UTC> |' field" ;;
    invalid-timestamp) printf "plan declares a 'Plan Timestamp' that is not an ISO-8601 UTC instant (expected e.g. 2026-09-02T00:41:02Z)" ;;
    future-timestamp)  printf "plan declares a 'Plan Timestamp' in the future" ;;
    *)                 printf 'plan timestamp could not be resolved' ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# eos_plans_by_recency [plan_dir]
#   Echoes plan paths, most-recent first. Ordering is fully deterministic: resolved
#   timestamp descending, then path ascending, so an mtime tie can never decide which
#   plan is "the" plan. README.md and _TEMPLATE.md are not plans and are excluded.
#   Plans whose time cannot be resolved sort last (weight 0) rather than disappearing —
#   they stay reachable so the freshness gate can report the real reason.
# ─────────────────────────────────────────────────────────────────────────────
eos_plans_by_recency() {
  local dir="${1:-$EOS_PLAN_DIR_DEFAULT}" candidate ts
  for candidate in "$dir"/*.md; do
    [ -f "$candidate" ] || continue
    case "$(basename "$candidate")" in README.md|_TEMPLATE.md) continue ;; esac
    if ! ts="$(eos_plan_timestamp "$candidate")"; then ts=0; fi
    printf '%s\t%s\n' "$ts" "$candidate"
  done | sort -k1,1nr -k2,2 | cut -f2-
}

# ─────────────────────────────────────────────────────────────────────────────
# eos_newest_plan [plan_dir] — the most recent plan by the ordering above.
# ─────────────────────────────────────────────────────────────────────────────
eos_newest_plan() {
  eos_plans_by_recency "${1:-$EOS_PLAN_DIR_DEFAULT}" | head -1
}

# ─────────────────────────────────────────────────────────────────────────────
# eos_plan_age_hours <plan_file> — whole hours since the plan was last current.
#   Echoes the age on success; on failure echoes the reason token and returns 1.
# ─────────────────────────────────────────────────────────────────────────────
eos_plan_age_hours() {
  local ts now
  ts="$(eos_plan_timestamp "$1")" || { printf '%s' "$ts"; return 1; }
  now="$(date -u +%s 2>/dev/null || echo 0)"
  printf '%s' "$(( (now - ts) / 3600 ))"
}
