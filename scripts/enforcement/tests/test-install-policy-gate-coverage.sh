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
if [ "$bad" -eq 0 ]; then pass all_manifest_dependencies_exist; else fail all_manifest_dependencies_exist; fi

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
if [ "$bad" -eq 0 ]; then pass every_real_call_site_has_a_manifest_row; else fail every_real_call_site_has_a_manifest_row; fi

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

# Installer behavior: the dependency manifest is a hard requirement of
# install-policy-gates.sh (PR #184's CodeRabbit Major finding — a missing
# manifest must fail closed, never silently skip the dependency-copy loop).
# Run the REAL installer from $ROOT against a hermetic fake Engineering OS
# home built entirely inside $TMP from repo-relative sources, so both paths
# are deterministic on any machine: no ~/.engineering-os, no network, and the
# repo under test is never mutated.
FAKE_HOME="$TMP/fake-eos-home"
mkdir -p "$FAKE_HOME/.github/workflows" "$FAKE_HOME/scripts/enforcement"
for wf in $INSTALLED; do
  cp "$WORKFLOWS_DIR/$wf" "$FAKE_HOME/.github/workflows/$wf"
done
while IFS=$'\t' read -r workflow dep; do
  case "${workflow:-}" in ''|'#'*) continue ;; esac
  [ -n "${dep:-}" ] || continue
  mkdir -p "$FAKE_HOME/$(dirname "$dep")"
  cp "$ROOT/$dep" "$FAKE_HOME/$dep"
done < "$MANIFEST"
cp "$MANIFEST" "$FAKE_HOME/scripts/enforcement/policy-gate-dependencies.tsv"

TARGET_OK="$TMP/install-target-ok"
mkdir -p "$TARGET_OK"
if EOS_SKIP_SETTINGS_PATCH=1 ENGINEERING_OS_HOME="$FAKE_HOME" \
     bash "$INSTALLER" "$TARGET_OK" >/dev/null 2>&1; then
  pass installer_succeeds_with_manifest_present
else
  fail installer_succeeds_with_manifest_present
fi
bad=0
while IFS=$'\t' read -r workflow dep; do
  case "${workflow:-}" in ''|'#'*) continue ;; esac
  [ -n "${dep:-}" ] || continue
  if [ ! -f "$TARGET_OK/$dep" ]; then
    echo "  fail: $dep missing from installed target"; bad=1
  fi
  case "$dep" in
    *.sh)
      if [ ! -x "$TARGET_OK/$dep" ]; then
        echo "  fail: $dep installed without executable bit"; bad=1
      fi
      ;;
  esac
done < "$MANIFEST"
if [ "$bad" -eq 0 ]; then pass installer_copies_every_manifest_dependency; else fail installer_copies_every_manifest_dependency; fi

# Negative: with the manifest absent from the fake home, the installer must
# exit non-zero with the explicit missing-manifest error and must not copy
# any dependency into the target (the workflow YAMLs above the manifest check
# may already be copied — that ordering is the documented contract).
rm "$FAKE_HOME/scripts/enforcement/policy-gate-dependencies.tsv"
TARGET_MISSING="$TMP/install-target-missing"
mkdir -p "$TARGET_MISSING"
rc=0
install_err="$(EOS_SKIP_SETTINGS_PATCH=1 ENGINEERING_OS_HOME="$FAKE_HOME" \
  bash "$INSTALLER" "$TARGET_MISSING" 2>&1 >/dev/null)" || rc=$?
if [ "$rc" -ne 0 ]; then
  pass installer_fails_closed_when_manifest_missing
else
  fail installer_fails_closed_when_manifest_missing
fi
case "$install_err" in
  *"missing policy-gate dependency manifest:"*)
    pass missing_manifest_error_is_explicit
    ;;
  *)
    echo "  stderr was: $install_err"
    fail missing_manifest_error_is_explicit
    ;;
esac
if find "$TARGET_MISSING/scripts" -type f 2>/dev/null | grep -q .; then
  fail no_dependency_copied_after_missing_manifest_failure
else
  pass no_dependency_copied_after_missing_manifest_failure
fi

echo "install policy-gate coverage simulations passed"
