#!/usr/bin/env bash
# enforce-tests.sh — comprehensive pre-commit lint/test gate.
#
# quality-gates.md <pre_commit_review> + <definition_of_done> require the project's
# checks to run before a commit. The previous pre-commit used an if/elif chain, so
# only ONE stack ran (and a bash/md repo ran nothing). This runs EVERY detected
# stack whose source files are staged, aggregates failures, and:
#   - a check that RUNS and fails        → blocks the commit (exit 1)
#   - a declared stack whose tool is MISSING → environment contract below
#
# Missing-tool environment contract (no silent skip anywhere):
#   - CI (CI=true or EOS_ENV=ci): a declared stack with a missing tool HARD-FAILS.
#   - local: a missing tool fails unless EOS_ALLOW_MISSING_TOOLS names it
#     (comma-separated tool names, e.g. EOS_ALLOW_MISSING_TOOLS=shellcheck),
#     in which case it warns loudly and proceeds.
#   - repos with no declared stack are untouched, so clean installs stay possible.
#
# Invoked from scripts/hooks/pre-commit.sh. Master bypass: EOS_BYPASS_TESTS=1.
# Governing policy: core/quality-gates.md <pre_commit_review>.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/evidence.sh
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true
if ! declare -f bypass_active >/dev/null 2>&1; then
  bypass_active() {
    local name="${1:-}"; [ -z "$name" ] && return 1
    case "${!name:-}" in 1|true|TRUE|yes|YES) return 0 ;; *) return 1 ;; esac
  }
fi

bypass_active EOS_BYPASS_TESTS && exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
staged="$(git diff --cached --name-only --diff-filter=ACMRD 2>/dev/null || true)"
[ -z "$staged" ] && exit 0

fail=0          # set when a check runs and fails → blocks
# have <cmd> — true if cmd is on PATH.
have() { command -v "$1" >/dev/null 2>&1; }
# staged_match <pattern> — true if any staged file matches the ERE pattern.
staged_match() { printf '%s\n' "$staged" | grep -qE "$1"; }

# run <label> <cmd...> — run a check, echo result, set fail on non-zero.
run() {
  local label="$1"; shift
  echo "── $label ──"
  if "$@"; then
    echo "  ✅ $label"
  else
    echo "  ❌ $label FAILED"
    fail=1
  fi
}
# missing_tool <stack> <tool> — declared stack but tool absent: environment contract.
# CI hard-fails; local fails unless EOS_ALLOW_MISSING_TOOLS names the tool.
in_ci() { [ "${CI:-}" = "true" ] || [ "${EOS_ENV:-}" = "ci" ]; }
tool_waived() {
  local tool="$1" entry
  IFS=',' read -r -a waived_tools <<< "${EOS_ALLOW_MISSING_TOOLS:-}"
  for entry in ${waived_tools[@]+"${waived_tools[@]}"}; do
    entry="${entry#"${entry%%[![:space:]]*}"}"
    entry="${entry%"${entry##*[![:space:]]}"}"
    [ "$entry" = "$tool" ] && return 0
  done
  return 1
}
missing_tool() {
  local stack="$1" tool="$2"
  if in_ci; then
    echo "❌ ${stack}: '${tool}' not installed in CI — a declared stack must have its tools in CI."
    fail=1
  elif tool_waived "$tool"; then
    echo "⚠️  ${stack}: '${tool}' not installed — waived via EOS_ALLOW_MISSING_TOOLS (install it so this gate can run)."
  else
    echo "❌ ${stack}: '${tool}' not installed — install it, or waive explicitly with EOS_ALLOW_MISSING_TOOLS=${tool}."
    fail=1
  fi
}

# has_npm_script <name> — true if package.json defines the given script.
# Prefers node (accurate JSON parsing); falls back to grep when node is absent
# (sufficient for standard names like lint/test/build; avoids python3 dependency).
has_npm_script() {
  if have node; then
    node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync(process.argv[1],'utf8'));process.exit((p.scripts&&Object.prototype.hasOwnProperty.call(p.scripts,process.argv[2]))?0:1)" "$ROOT/package.json" "$1" 2>/dev/null
  else
    grep -qE "\"$1\"[[:space:]]*:" "$ROOT/package.json" 2>/dev/null
  fi
}
# make_target <name> — true if the Makefile defines the target.
make_target() { grep -qE "^$1[[:space:]]*:" "$ROOT/Makefile" 2>/dev/null; }

# ── node ─────────────────────────────────────────────────────────────────────
if [ -f "$ROOT/package.json" ] && staged_match '\.(js|jsx|ts|tsx|mjs|cjs|vue|svelte)$|(^|/)package(-lock)?\.json$'; then
  pm=npm
  [ -f "$ROOT/pnpm-lock.yaml" ] && pm=pnpm
  [ -f "$ROOT/yarn.lock" ] && pm=yarn
  if have "$pm"; then
    has_npm_script lint && run "node lint ($pm)" "$pm" run lint
    has_npm_script test && run "node test ($pm)" "$pm" test
  else
    missing_tool node "$pm"
  fi
fi

# ── python ───────────────────────────────────────────────────────────────────
if { [ -f "$ROOT/pyproject.toml" ] || [ -f "$ROOT/setup.py" ] || [ -f "$ROOT/requirements.txt" ]; } \
   && staged_match '\.py$'; then
  if have ruff; then run "python lint (ruff)" ruff check "$ROOT"; else missing_tool python ruff; fi
  if have pytest; then
    echo "── python test (pytest) ──"
    pytest -q "$ROOT"; prc=$?
    # exit 5 = "no tests collected" → not a failure (the test-file gate lives in commit-msg).
    if [ "$prc" -eq 0 ] || [ "$prc" -eq 5 ]; then echo "  ✅ python test (pytest)"; else echo "  ❌ python test (pytest) FAILED"; fail=1; fi
  else
    missing_tool python pytest
  fi
fi

# ── go ───────────────────────────────────────────────────────────────────────
if [ -f "$ROOT/go.mod" ] && staged_match '\.go$'; then
  if have go; then
    run "go vet" go vet ./...
    run "go test" go test ./...
  else
    missing_tool go go
  fi
fi

# ── rust ─────────────────────────────────────────────────────────────────────
if [ -f "$ROOT/Cargo.toml" ] && staged_match '\.rs$'; then
  if have cargo; then
    have rustup && cargo clippy --version >/dev/null 2>&1 && run "rust clippy" cargo clippy --quiet
    run "rust test" cargo test --quiet
  else
    missing_tool rust cargo
  fi
fi

# ── make ─────────────────────────────────────────────────────────────────────
if [ -f "$ROOT/Makefile" ] && staged_match '(^|/)Makefile$|\.mk$'; then
  if have make; then
    make_target lint && run "make lint" make -C "$ROOT" lint
    make_target test && run "make test" make -C "$ROOT" test
  else
    missing_tool make make
  fi
fi

# ── shell: syntax-check every staged shell script ────────────────────────────
shells="$(printf '%s\n' "$staged" | grep -E '\.(sh|bash|zsh)$' || true)"
if [ -n "$shells" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ -f "$ROOT/$f" ] || continue
    case "$f" in
      *.zsh)
        have zsh && run "zsh syntax: $f" zsh -n "$ROOT/$f"
        continue
        ;;
    esac
    run "shell syntax: $f" bash -n "$ROOT/$f"
    # -e SC2148: don't force a shebang (sourced libs legitimately omit one); still
    # catch real error-severity issues.
    if have shellcheck; then run "shellcheck: $f" shellcheck -S error -e SC2148 "$ROOT/$f"; fi
  done <<EOF
$shells
EOF
  have shellcheck || missing_tool shell shellcheck
fi

if [ "$fail" -ne 0 ]; then
  echo "❌ COMMIT BLOCKED — quality-gates.md <pre_commit_review>: a lint/test check failed above."
  echo "  Fix it, or bypass only with explicit justification: EOS_BYPASS_TESTS=1."
  exit 1
fi
exit 0
