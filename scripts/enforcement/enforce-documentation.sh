#!/usr/bin/env bash
# enforce-documentation.sh — deterministic enforcer for core/documentation-policy.md
#
# documentation-policy.md is mostly judgment (README content quality, style, "docs
# in the same commit"). Three rules are deterministic and enforced here:
#
#   D1 (BLOCK) — a staged file under patterns/<domain>/ or external-systems/<service>/
#                requires a README.md in that directory (lines 34-36). external-skills
#                is already covered by enforce-skill.sh.
#   D2 (BLOCK) — the repo root must have a README.md (line 20).
#   D3 (BLOCK) — no standalone placeholder ("TBD"/"FIXME"/"XXX"/"???") in staged .md
#                added lines (line 45: "אל תשאיר TBD"). Prose mentioning the word
#                mid-sentence is NOT matched — only empty-section markers.
#
# Validation is INDEX-based (git cat-file -e :path / git diff --cached) so the gate
# judges what will actually commit. Invoked from scripts/hooks/pre-commit.sh.
# Master bypass: EOS_BYPASS_DOC=1. Governing policy: core/documentation-policy.md.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/evidence.sh
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true
if ! declare -f bypass_active >/dev/null 2>&1; then
  bypass_active() {
    local name="${1:-}"; [ -z "$name" ] && return 1
    case "${!name:-}" in 1|true|TRUE|yes|YES) return 0 ;; *) return 1 ;; esac
  }
fi

bypass_active EOS_BYPASS_DOC && exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
[ -z "$staged" ] && exit 0

in_index() { git cat-file -e ":$1" 2>/dev/null; }

fail=0

# ── D1 — content directories need a README.md ────────────────────────────────
# Unique patterns/<domain> and external-systems/<service> dirs among staged paths.
dirs="$(printf '%s\n' "$staged" \
  | grep -E '^(patterns|external-systems)/[^/]+/' \
  | sed -E 's#^((patterns|external-systems)/[^/]+)/.*#\1#' \
  | sort -u || true)"
if [ -n "$dirs" ]; then
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    if ! in_index "$dir/README.md"; then
      if ! bypass_active EOS_BYPASS_DOCREADME; then
        echo "❌ COMMIT BLOCKED — documentation-policy.md <documentation>: '$dir/' has no README.md."
        echo "  Every significant directory needs a README explaining what it is and when to use it."
        echo "  BYPASS: EOS_BYPASS_DOCREADME=1 (or EOS_BYPASS_DOC=1)."
        fail=1
      fi
    fi
  done <<EOF
$dirs
EOF
fi

# ── D2 — repo root README.md must exist ──────────────────────────────────────
if ! in_index "README.md"; then
  if ! bypass_active EOS_BYPASS_ROOTREADME; then
    echo "❌ COMMIT BLOCKED — documentation-policy.md <documentation>: the repo has no root README.md."
    echo "  Every project needs a README.md (what it is, install/run, key commands, env, structure)."
    echo "  BYPASS: EOS_BYPASS_ROOTREADME=1 (or EOS_BYPASS_DOC=1)."
    fail=1
  fi
fi

# ── D3 — no standalone placeholder markers in staged .md added lines ──────────
added="$(git diff --cached --diff-filter=ACMR -U0 -- '*.md' 2>/dev/null \
  | grep -E '^\+' | grep -vE '^\+\+\+' || true)"
if [ -n "$added" ]; then
  # A placeholder line is one whose entire content is just TBD/FIXME/XXX/??? —
  # bare, or wrapped as a list item ("- "/"* "), blockquote ("> "), heading ("## "),
  # or a "key: value" body. Mid-sentence mentions don't match (marker must end the line).
  tbd_hits="$(printf '%s\n' "$added" \
    | grep -nE '^\+[[:space:]]*([*-][[:space:]]+|>[[:space:]]+)?(#+[[:space:]]*)?(TBD|FIXME|XXX|\?\?\?)[[:space:]]*$|^\+[[:space:]]*[^:]+:[[:space:]]*(TBD|FIXME|XXX|\?\?\?)[[:space:]]*$' \
    || true)"
  if [ -n "$tbd_hits" ]; then
    if ! bypass_active EOS_BYPASS_TBD; then
      echo "❌ COMMIT BLOCKED — documentation-policy.md <documentation>: placeholder markers in staged docs (no fake completeness)."
      printf '%s\n' "$tbd_hits" | sed 's/^/    /'
      echo "  Write real content or remove the section. BYPASS: EOS_BYPASS_TBD=1 (or EOS_BYPASS_DOC=1)."
      fail=1
    fi
  fi
fi

exit "$fail"
