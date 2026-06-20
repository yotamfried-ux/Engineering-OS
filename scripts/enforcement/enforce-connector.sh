#!/usr/bin/env bash
# enforce-connector.sh — deterministic enforcer for core/connector-policy.md
#
# connector-policy.md is mostly judgment (information-source order, pattern-gap,
# connector selection, fallback, skills-vs-connectors). The one deterministic rule
# is <environment> (lines 381-384): ".env stays out of git" + "no secrets in
# commits". That rule is referenced as "enforced in a hook" across connector-policy,
# git-policy <safety>, and hooks-policy — but was never actually implemented. This
# script implements it:
#
#   C1 (BLOCK) — a staged .env file (except .env.example/.sample/.template/.dist).
#   C2 (BLOCK) — high-confidence secret VALUES in staged added lines: PEM private
#                keys, AWS access-key ids, GitHub/Slack/OpenAI tokens. Keyword-only
#                mentions ("api_key", "secret") are intentionally NOT matched, to
#                stay false-positive-free in this docs-heavy repo.
#
# Invoked from scripts/hooks/pre-commit.sh. Master bypass: EOS_BYPASS_CONNECTOR=1.
# Governing policy: core/connector-policy.md <environment>.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/evidence.sh
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true
if ! declare -f bypass_active >/dev/null 2>&1; then
  bypass_active() {
    local name="${1:-}"; [ -z "$name" ] && return 1
    case "${!name:-}" in 1|true|TRUE|yes|YES) return 0 ;; *) return 1 ;; esac
  }
fi

bypass_active EOS_BYPASS_CONNECTOR && exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
[ -z "$staged" ] && exit 0

# ── C1: block committing a .env file ─────────────────────────────────────────
env_hits="$(printf '%s\n' "$staged" \
  | grep -E '(^|/)\.env($|\.)' \
  | grep -vE '\.env\.(example|sample|template|dist)$' || true)"
if [ -n "$env_hits" ]; then
  if ! bypass_active EOS_BYPASS_ENVFILE; then
    echo "❌ COMMIT BLOCKED — connector-policy.md <environment>: a .env file is staged. Secrets must never enter git."
    echo "  Staged:"; printf '%s\n' "$env_hits" | sed 's/^/    /'
    echo "  Add it to .gitignore and run 'git rm --cached <file>'. Commit only .env.example (names + dummy values)."
    echo "  BYPASS: EOS_BYPASS_ENVFILE=1 (or EOS_BYPASS_CONNECTOR=1)."
    exit 1
  fi
fi

# ── C2: block high-confidence secret values in staged added lines ────────────
# Exclude this enforcer's own test dir: its fixtures hold synthetic secrets by design.
added="$(git diff --cached --diff-filter=ACMR -U0 -- . ':(exclude)scripts/enforcement/tests/*' 2>/dev/null \
  | grep -E '^\+' | grep -vE '^\+\+\+' || true)"
if [ -n "$added" ]; then
  # -e terminates option parsing — the PEM pattern starts with '-' and would
  # otherwise be misread by grep as a flag.
  secret_hits="$(printf '%s\n' "$added" | grep -nE \
    -e '-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|xox[baprs]-[A-Za-z0-9-]{10,}|sk-[A-Za-z0-9]{32,}' \
    || true)"
  if [ -n "$secret_hits" ]; then
    if ! bypass_active EOS_BYPASS_SECRETS; then
      echo "❌ COMMIT BLOCKED — connector-policy.md <environment>: a hardcoded secret appears in the staged diff."
      echo "  Matches (PEM key / AWS / GitHub / Slack / OpenAI token):"
      printf '%s\n' "$secret_hits" | sed 's/^/    /'
      echo "  Move it to .env (git-ignored) and read it from an env var at runtime."
      echo "  BYPASS: EOS_BYPASS_SECRETS=1 (or EOS_BYPASS_CONNECTOR=1) — only for a genuine false positive."
      exit 1
    fi
  fi
fi

exit 0
