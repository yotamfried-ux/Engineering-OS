#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
MANIFEST="$ROOT/scripts/enforcement/policy-gate-dependencies.tsv"
WORKFLOWS_DIR="$ROOT/.github/workflows"
INSTALLER="$ROOT/scripts/install-policy-gates.sh"

# The set of workflows install-policy-gates.sh actually installs downstream —
# derived from the installer's own `for name in ...` line so this test cannot
# drift from what is really shipped (enforcement-tests.yml, post-merge-validation.yml,
# etc. are Engineering-OS-repo-only CI and are never installed).
installed_workflows() {
  grep -oE '^for name in [^;]+' "$INSTALLER" | sed -E 's/^for name in //'
}

pass() { echo "ok: $1"; }
fail() { echo "fail: $1"; exit 1; }

[ -f "$MANIFEST" ] || fail "manifest_present"
pass manifest_present

# Every dependency row must point at a file that actually exists in this repo,
# so the manifest itself cannot silently go stale.
bad=0
while IFS=$'\t' read -r workflow dep; do
  case "${workflow:-}" in ''|'#'*) continue ;; esac
  [ -n "${dep:-}" ] || { echo "  fail: malformed row for $workflow (empty dependency)"; bad=1; continue; }
  [ -f "$ROOT/$dep" ] || { echo "  fail: $workflow declares missing dependency $dep"; bad=1; }
done < "$MANIFEST"
[ "$bad" -eq 0 ] && pass all_manifest_dependencies_exist || fail all_manifest_dependencies_exist

# Every real `bash scripts/enforcement/<name>.sh` (or .py) call site inside an
# installed policy workflow must have a matching manifest row for that workflow,
# so a newly added gate dependency cannot be silently forgotten (the PR D bug
# this manifest exists to prevent).
bad=0
INSTALLED="$(installed_workflows)"
[ -n "$INSTALLED" ] || fail "installed_workflows_list_non_empty"
for wf in "$WORKFLOWS_DIR"/*.yml; do
  name="$(basename "$wf")"
  case " $INSTALLED " in *" $name "*) ;; *) continue ;; esac
  while IFS= read -r called; do
    [ -n "$called" ] || continue
    grep -qE "^${name}	scripts/enforcement/${called}$" "$MANIFEST" \
      || { echo "  fail: $name calls scripts/enforcement/$called with no matching manifest row"; bad=1; }
  done < <(grep -oE 'scripts/enforcement/[A-Za-z0-9_.-]+\.(sh|py)' "$wf" | sed 's#scripts/enforcement/##' | sort -u)
done
[ "$bad" -eq 0 ] && pass every_real_call_site_has_a_manifest_row || fail every_real_call_site_has_a_manifest_row

# Negative: a workflow calling an undeclared script must be caught by the same
# cross-check logic used above (regression guard for the coverage check itself).
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/fake-policy.yml" <<'EOF'
name: fake-policy
jobs:
  x:
    steps:
      - run: bash scripts/enforcement/check-fake-thing.sh
EOF
if grep -oE 'scripts/enforcement/[A-Za-z0-9_.-]+\.(sh|py)' "$TMP/fake-policy.yml" \
     | sed 's#scripts/enforcement/##' \
     | xargs -I{} grep -qE "^fake-policy.yml	scripts/enforcement/{}$" "$MANIFEST"; then
  fail "undeclared_dependency_should_not_be_found_in_manifest"
fi
pass undeclared_dependency_correctly_absent_from_manifest

echo "install policy-gate coverage simulations passed"
