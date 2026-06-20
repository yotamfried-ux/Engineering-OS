#!/usr/bin/env bash
# enforce-resource.sh — deterministic enforcer for core/resource-management.md
#
# One enforcer per md file (Engineering OS convention). resource-management.md is
# mostly judgment (model selection, sub-agents, token-output, nemotron-routing).
# Only two rules are deterministically checkable; this enforces exactly those:
#
#   R1 (precommit, BLOCK)  — every project must have a .claudeignore (line 126).
#   R2 (commit-msg, BLOCK) — no Claude model identifier in commit messages
#                            (line 30 + the model-identity rule). Scoped to commit
#                            messages only: code legitimately references model IDs
#                            (AI apps), so source is NOT scanned.
#
# Invocations:
#   enforce-resource.sh precommit          # checks .claudeignore exists
#   enforce-resource.sh commit-msg <file>  # checks the commit message
#
# Wired from scripts/hooks/pre-commit.sh and scripts/hooks/commit-msg.sh.
# Master bypass: EOS_BYPASS_RESOURCE=1. Governing policy: core/resource-management.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/evidence.sh
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true
if ! declare -f bypass_active >/dev/null 2>&1; then
  bypass_active() {
    local name="${1:-}"; [ -z "$name" ] && return 1
    case "${!name:-}" in 1|true|TRUE|yes|YES) return 0 ;; *) return 1 ;; esac
  }
fi

bypass_active EOS_BYPASS_RESOURCE && exit 0

# Narrow model-ID pattern: hyphenated, lowercase tier + a digit. Matches
# claude-opus-4-8 / claude-sonnet-4-6 / claude-haiku-4-5-20251001 / claude-fable-5,
# but NOT the standard "Co-Authored-By: Claude Opus 4.8" trailer (spaces, no hyphens).
MODEL_ID_RE='claude-(opus|sonnet|haiku|fable)-[0-9]'

# ── R1 — .claudeignore must exist ────────────────────────────────────────────
do_precommit() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
  local root; root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  [ -f "$root/.claudeignore" ] && exit 0
  bypass_active EOS_BYPASS_CLAUDEIGNORE && exit 0
  echo "❌ COMMIT BLOCKED — resource-management.md <claudeignore>: this project has no .claudeignore."
  echo "   Every project must define what Claude does not read (node_modules, .env, lock files, build outputs...)."
  echo "   Create .claudeignore at the repo root (baseline: Engineering OS /.claudeignore), then commit."
  echo "   BYPASS: EOS_BYPASS_CLAUDEIGNORE=1 (or EOS_BYPASS_RESOURCE=1)."
  exit 1
}

# ── R2 — no model identifier in the commit message ───────────────────────────
do_commit_msg() {
  local msg_file="$1"
  if [ -z "$msg_file" ] || [ ! -f "$msg_file" ]; then
    exit 0
  fi
  grep -qiE "$MODEL_ID_RE" "$msg_file" || exit 0
  bypass_active EOS_BYPASS_MODELID && exit 0
  echo "❌ COMMIT BLOCKED — resource-management.md <model-selection>: commit message contains a model identifier."
  echo "   Never put model IDs (claude-<tier>-N) in commit messages, PR bodies, or code comments."
  echo "   Offending line(s):"
  grep -niE "$MODEL_ID_RE" "$msg_file" | sed 's/^/     /'
  echo "   BYPASS: EOS_BYPASS_MODELID=1 (or EOS_BYPASS_RESOURCE=1)."
  exit 1
}

# ── Route by subcommand ──────────────────────────────────────────────────────
MODE="${1:-precommit}"
case "$MODE" in
  precommit)  do_precommit ;;
  commit-msg) do_commit_msg "${2:-}" ;;
  *) exit 0 ;;
esac
exit 0
