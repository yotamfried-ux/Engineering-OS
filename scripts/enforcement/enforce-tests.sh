#!/usr/bin/env bash
# enforce-tests.sh — comprehensive pre-commit lint/test gate.
#
# quality-gates.md <pre_commit_review> + <definition_of_done> require the project's
# checks to run before a commit. The previous pre-commit used an if/elif chain, so
# only ONE stack ran (and a bash/md repo ran nothing). This runs EVERY detected
# stack whose source files are staged, aggregates failures, and:
#   - a check that RUNS and fails        → blocks the commit (exit 1)
#   - a declared stack whose tool is MISSING → loud warning, does NOT block
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
staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
[ -z "$staged" ] && exit 0

fail=0          # set when a check runs and fails → blocks
have() { command -v "$1" >/dev/null 2>&1; }
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
# warn_missing <stack> <tool> — declared stack but tool absent: warn, never block.
warn_missing() { echo "⚠️  ${1}: '${2}' not installed — skipping (install it so this gate can run)."; }

# has_npm_script <name> — true if package.json defines the given script.
has_npm_script() {
  python3 -c "import json,sys;d=json.load(open('$ROOT/package.json'));sys.exit(0 if '$1' in d.get('scripts',{}) else 1)" 2>/dev/null
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
    warn_missing node "$pm"
  fi
fi

# ── python ───────────────────────────────────────────────────────────────────
if { [ -f "$ROOT/pyproject.toml" ] || [ -f "$ROOT/setup.py" ] || [ -f "$ROOT/requirements.txt" ]; } \
   && staged_match '\.py$'; then
  if have ruff; then run "python lint (ruff)" ruff check "$ROOT"; else warn_missing python ruff; fi
  if have pytest; then run "python test (pytest)" pytest -q "$ROOT"; else warn_missing python pytest; fi
fi

# ── go ───────────────────────────────────────────────────────────────────────
if [ -f "$ROOT/go.mod" ] && staged_match '\.go$'; then
  if have go; then
    run "go vet" go vet ./...
    run "go test" go test ./...
  else
    warn_missing go go
  fi
fi

# ── rust ─────────────────────────────────────────────────────────────────────
if [ -f "$ROOT/Cargo.toml" ] && staged_match '\.rs$'; then
  if have cargo; then
    have rustup && cargo clippy --version >/dev/null 2>&1 && run "rust clippy" cargo clippy --quiet
    run "rust test" cargo test --quiet
  else
    warn_missing rust cargo
  fi
fi

# ── make ─────────────────────────────────────────────────────────────────────
if [ -f "$ROOT/Makefile" ]; then
  if have make; then
    make_target lint && run "make lint" make -C "$ROOT" lint
    make_target test && run "make test" make -C "$ROOT" test
  else
    warn_missing make make
  fi
fi

# ── shell: syntax-check every staged shell script ────────────────────────────
shells="$(printf '%s\n' "$staged" | grep -E '\.(sh|bash|zsh)$' || true)"
if [ -n "$shells" ]; then
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ -f "$ROOT/$f" ] || continue
    run "shell syntax: $f" bash -n "$ROOT/$f"
    if have shellcheck; then run "shellcheck: $f" shellcheck -S error "$ROOT/$f"; fi
  done <<EOF
$shells
EOF
  have shellcheck || warn_missing shell shellcheck
fi

if [ "$fail" -ne 0 ]; then
  echo "❌ COMMIT BLOCKED — quality-gates.md <pre_commit_review>: a lint/test check failed above."
  echo "  Fix it, or bypass only with explicit justification: EOS_BYPASS_TESTS=1."
  exit 1
fi
exit 0
