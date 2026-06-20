#!/usr/bin/env bash
# enforce-skill.sh — deterministic enforcer for core/skill-orchestration-policy.md
#
# skill-orchestration-policy.md is mostly judgment (execution levels, composition,
# bootstrap, override). The deterministic rule is the SKILL CONTRACT: <skill_structure>
# + <integration_procedure> require every external-skills/<name>/ to carry the four
# contract files AND be listed in the registry. This enforces that:
#
#   S1 (BLOCK) — every staged external-skills/<name>/ has README.md, integration.md,
#                policy.md, activation.md (validated in the git index).
#   S2 (BLOCK) — <name> appears in the registry external-skills/README.md.
#
# Validation is INDEX-based (git cat-file -e :path / git show :path) so the gate
# judges what will actually commit, not unstaged working-tree edits.
#
# Invoked from scripts/hooks/pre-commit.sh. Master bypass: EOS_BYPASS_SKILL=1.
# Governing policy: core/skill-orchestration-policy.md.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/evidence.sh
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true
if ! declare -f bypass_active >/dev/null 2>&1; then
  bypass_active() {
    local name="${1:-}"; [ -z "$name" ] && return 1
    case "${!name:-}" in 1|true|TRUE|yes|YES) return 0 ;; *) return 1 ;; esac
  }
fi

bypass_active EOS_BYPASS_SKILL && exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
[ -z "$staged" ] && exit 0

REGISTRY="external-skills/README.md"
CONTRACT_FILES="README.md integration.md policy.md activation.md"

# Unique skill dirs among staged paths: external-skills/<name>/... (exclude the
# top-level external-skills/README.md, which is the registry, not a skill).
skills="$(printf '%s\n' "$staged" \
  | grep -E '^external-skills/[^/]+/' \
  | sed -E 's#^(external-skills/[^/]+)/.*#\1#' \
  | sort -u || true)"
[ -z "$skills" ] && exit 0

# in_index <path> — true if the path exists in the staged index (committed or staged).
in_index() { git cat-file -e ":$1" 2>/dev/null; }

fail=0
while IFS= read -r dir; do
  [ -z "$dir" ] && continue
  name="$(basename "$dir")"

  # S1 — four contract files present in the index.
  miss=""
  for f in $CONTRACT_FILES; do
    in_index "$dir/$f" || miss="$miss $f"
  done
  if [ -n "$miss" ]; then
    if ! bypass_active EOS_BYPASS_SKILLDOC; then
      echo "❌ COMMIT BLOCKED — skill-orchestration-policy.md <skill_structure>: skill '$name' is missing contract file(s):$miss"
      echo "  Every external-skills/<name>/ needs README.md, integration.md, policy.md, activation.md."
      echo "  BYPASS: EOS_BYPASS_SKILLDOC=1 (or EOS_BYPASS_SKILL=1)."
      fail=1
    fi
  fi

  # S2 — registered in external-skills/README.md (read from index).
  if ! git show ":$REGISTRY" 2>/dev/null | grep -q "$name"; then
    if ! bypass_active EOS_BYPASS_SKILLREG; then
      echo "❌ COMMIT BLOCKED — skill-orchestration-policy.md <integration_procedure>: skill '$name' is not registered in $REGISTRY."
      echo "  Add a registry row for '$name' (step 4 of the integration procedure)."
      echo "  BYPASS: EOS_BYPASS_SKILLREG=1 (or EOS_BYPASS_SKILL=1)."
      fail=1
    fi
  fi
done <<EOF
$skills
EOF

exit "$fail"
