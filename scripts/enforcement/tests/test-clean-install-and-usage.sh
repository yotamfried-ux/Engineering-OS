#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
USE_IN_PROJECT="$ROOT/scripts/use-in-project.sh"
PRECHECK="$ROOT/scripts/enforcement/pre-tool-use-runtime-evidence.sh"
READ_RECORDER="$ROOT/scripts/enforcement/post-tool-use-read-evidence.sh"
MERGE_CHECK="$ROOT/scripts/enforcement/check-merge-readiness.sh"
JSON_GUARD="$ROOT/scripts/enforcement/pre-tool-use-json-guard.sh"
chmod +x "$USE_IN_PROJECT" "$PRECHECK" "$READ_RECORDER" "$MERGE_CHECK" "$JSON_GUARD"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
TARGET="$TMP/target-app"
mkdir -p "$TARGET"

git init "$TARGET" >/dev/null
git -C "$TARGET" config user.email test@example.com
git -C "$TARGET" config user.name test

expect_file() { [ -f "$1" ] || { echo "  ❌ missing file: $1"; exit 1; }; echo "  ✅ file exists: ${1#$TARGET/}"; }
expect_executable() { [ -x "$1" ] || { echo "  ❌ not executable: $1"; exit 1; }; echo "  ✅ executable: ${1#$TARGET/}"; }
expect_contains() { grep -q "$2" "$1" || { echo "  ❌ expected $1 to contain $2"; exit 1; }; echo "  ✅ contains: ${1#$TARGET/} -> $2"; }
expect_pass() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "  ✅ $name"; else echo "  ❌ expected pass: $name"; exit 1; fi; }
expect_fail() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "  ❌ expected fail: $name"; exit 1; else echo "  ✅ $name"; fi; }

run_install() {
  (cd "$TARGET" && EOS_CONTRACT_TEST=1 ENGINEERING_OS_HOME="$ROOT" bash "$USE_IN_PROJECT" >/dev/null)
}

run_precheck() {
  local file="$1"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$file" | "$PRECHECK" >/dev/null 2>&1
}

record_read() {
  local file="$1"
  printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$file" | "$READ_RECORDER" >/dev/null 2>&1
}

write_usage_plan() {
  mkdir -p "$TARGET/.claude/plans"
  cat > "$TARGET/.claude/plans/usage.md" <<'PLAN'
# Route Plan

| Field | Value |
|---|---|
| Task class | unclassified |
| Task-router evidence | task router was read |
| Workflow evidence | workflow was read |
| Templates | none |
| Patterns | none |
| External systems/connectors | none |
| Skills | none |

## Capability Waiver

Reason: clean install usage simulation uses an unclassified fixture to isolate runtime hook behavior.

## Source of Truth Checks

| Need | Source checked | Result |
|---|---|---|
| Runtime gate behavior | local hook simulation | required |
PLAN
}

make_runs_json() {
  local file="$1" enforcement_status="$2" enforcement_conclusion="$3"
  cat > "$file" <<JSON
{"workflow_runs":[
 {"name":"enforcement-tests","status":"$enforcement_status","conclusion":"$enforcement_conclusion"},
 {"name":"pr-policy","status":"completed","conclusion":"success"},
 {"name":"connector-evidence-policy","status":"completed","conclusion":"success"},
 {"name":"workflow-evidence-policy","status":"completed","conclusion":"success"},
 {"name":"capability-evidence-policy","status":"completed","conclusion":"success"},
 {"name":"plan-policy","status":"completed","conclusion":"success"},
 {"name":"documentation-asset-policy","status":"completed","conclusion":"success"}
]}
JSON
}

echo "── Experiment 1: clean install into target repo ──"
run_install
expect_file "$TARGET/CLAUDE.md"
expect_file "$TARGET/.engineering-os/REFERENCE.md"
expect_file "$TARGET/ENGINEERING_OS_SETUP.md"
expect_file "$TARGET/ENGINEERING_OS_CAPABILITIES.md"
expect_file "$TARGET/.claude/settings.json"
expect_file "$TARGET/.claude/commands/use-engineering-os.md"
expect_file "$TARGET/.claude/commands/superpowers-brainstorm.md"
expect_file "$TARGET/.claude/commands/superpowers-verify.md"
expect_file "$TARGET/.claude/commands/superpowers-plan.md"
expect_executable "$TARGET/.git/hooks/pre-commit"
expect_executable "$TARGET/.git/hooks/commit-msg"
expect_executable "$TARGET/.git/hooks/post-commit"
expect_file "$TARGET/.github/workflows/pr-policy.yml"
expect_file "$TARGET/.github/workflows/plan-policy.yml"
expect_file "$TARGET/.github/workflows/connector-evidence-policy.yml"
expect_file "$TARGET/.github/workflows/workflow-evidence-policy.yml"
expect_file "$TARGET/.github/workflows/capability-evidence-policy.yml"
expect_file "$TARGET/.github/workflows/documentation-asset-policy.yml"
expect_contains "$TARGET/.claude/settings.json" "pre-tool-use-json-guard.sh"
expect_contains "$TARGET/.claude/settings.json" "pre-tool-use-runtime-evidence.sh"
expect_contains "$TARGET/.claude/settings.json" "check-plan-scope.sh"
expect_contains "$TARGET/.claude/settings.json" "rtk hook claude"
expect_contains "$TARGET/.claude/settings.json" "SessionStart"
expect_contains "$TARGET/.claude/settings.json" "scripts/session-setup.sh"
expect_contains "$ROOT/scripts/session-setup.sh" "rtk init -g"
expect_contains "$ROOT/scripts/session-setup.sh" "rtk --version"
expect_contains "$TARGET/.claude/settings.json" "$ROOT/scripts/enforcement"

# Manifest-driven policy-gate dependencies: every workflow that calls a
# scripts/enforcement/* script must have that script (and any data files it
# needs) actually present in the installed target, or the workflow step exits
# 127 before validating anything (the class of bug found in PR D's review).
MANIFEST="$ROOT/scripts/enforcement/policy-gate-dependencies.tsv"
while IFS=$'\t' read -r workflow dep; do
  case "${workflow:-}" in ''|'#'*) continue ;; esac
  [ -n "${dep:-}" ] || continue
  expect_file "$TARGET/$dep"
  case "$dep" in *.sh) expect_executable "$TARGET/$dep" ;; esac
done < "$MANIFEST"

write_body() { printf '%s\n' "$2" > "$1"; }
write_body "$TMP/installed-body.md" "
## Review Fallback Evidence

- reviewer: installed-target smoke check.
- scope: check-pr-review-evidence.sh.
- checks: enforcement-tests all green.
- risks: extraction could change behavior.
- decision: safe to merge after CI is green.
- evidence: scripts/enforcement/tests/test-clean-install-and-usage.sh.

## Merge Readiness

- base: main
- expected-head-sha: 0000000000000000000000000000000000000f
- ci: enforcement-tests all green.
- threads: no unresolved review threads remain on the PR.
- approval: owner explicit go-ahead recorded in chat.
"
expect_pass "installed check-pr-review-evidence.sh runs from the target project" \
  bash "$TARGET/scripts/enforcement/check-pr-review-evidence.sh" --body "$TMP/installed-body.md"

bash -c "cd '$TARGET' && rm -rf noplans-repo && git init -q noplans-repo && cd noplans-repo && git config user.email t@t && git config user.name t && git commit --allow-empty -q -m base"
expect_pass "installed check-connector-evidence.sh runs from the target project (no changed plans)" \
  bash -c "cd '$TARGET/noplans-repo' && bash '$TARGET/scripts/enforcement/check-connector-evidence.sh' HEAD HEAD"
expect_pass "installed check-workflow-evidence.sh runs from the target project (no changed plans)" \
  bash -c "cd '$TARGET/noplans-repo' && bash '$TARGET/scripts/enforcement/check-workflow-evidence.sh' HEAD HEAD"
expect_pass "installed check-documentation-asset-evidence.sh runs from the target project (no changed plans)" \
  bash -c "cd '$TARGET/noplans-repo' && bash '$TARGET/scripts/enforcement/check-documentation-asset-evidence.sh' HEAD HEAD"
: > "$TMP/empty-files.txt"
expect_pass "installed check-capability-staged-changes.sh runs from the target project" \
  bash "$TARGET/scripts/enforcement/check-capability-staged-changes.sh" --files-from "$TMP/empty-files.txt"

run_install
managed_count="$(grep -c '<!-- BEGIN engineering-os (managed) -->' "$TARGET/CLAUDE.md")"
[ "$managed_count" = "1" ] || { echo "  ❌ managed CLAUDE block duplicated: $managed_count"; exit 1; }
echo "  ✅ install is idempotent: managed block count = 1"

settings_count="$(find "$TARGET/.claude" -name settings.json | wc -l | xargs)"
[ "$settings_count" = "1" ] || { echo "  ❌ settings duplicated: $settings_count"; exit 1; }
echo "  ✅ install is idempotent: one settings file"

echo "── Experiment 2: actual usage gate simulation ──"
cd "$TARGET"
mkdir -p .claude/.evidence
export EOS_EVIDENCE_DIR=".claude/.evidence"
export EOS_PRETOOL_LEGACY_EXIT=1
: > .claude/.evidence/ledger

expect_fail "JSON guard blocks malformed event" bash -c "printf '%s' '{bad json' | '$JSON_GUARD'"
expect_fail "write blocked before any Route Plan exists" run_precheck src/app.ts
write_usage_plan
expect_fail "write still blocked until task-router/workflow are read" run_precheck src/app.ts
record_read core/task-router.md
expect_fail "write still blocked until workflow is read" run_precheck src/app.ts
record_read core/workflow.md
expect_pass "write allowed after plan plus router/workflow evidence" run_precheck src/app.ts

make_runs_json "$TMP/pending.json" in_progress null
expect_fail "merge readiness blocks pending workflow" "$MERGE_CHECK" --runs-json "$TMP/pending.json"
make_runs_json "$TMP/green.json" completed success
expect_pass "merge readiness allows all green workflows" "$MERGE_CHECK" --runs-json "$TMP/green.json"

echo "── Experiment 3: RTK/graphify PATH-absence fallback ──"
extract_hook_cmds() {
  python3 - "$TARGET/.claude/settings.json" "$1" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
needle = sys.argv[2]
def walk(o):
    if isinstance(o, dict):
        for v in o.values():
            yield from walk(v)
    elif isinstance(o, list):
        for v in o:
            yield from walk(v)
    elif isinstance(o, str):
        if needle in o:
            print(o)
list(walk(data.get('hooks', {})))
PY
}
# A minimal PATH that keeps bash/coreutils but excludes wherever this
# container's real rtk/graphify binaries live, so `command -v rtk` genuinely
# fails without breaking the ability to run bash/python3 themselves.
NO_RTK_GRAPHIFY_PATH="/usr/bin:/bin"
rtk_cmd="$(extract_hook_cmds 'rtk hook claude' | head -1)"
[ -n "$rtk_cmd" ] || { echo "  ❌ no rtk hook command found in installed settings.json"; exit 1; }
expect_pass "rtk-absent PreToolUse hook does not crash (warns/no-ops per contract)" \
  env -i PATH="$NO_RTK_GRAPHIFY_PATH" bash -c "cd '$TARGET' && $rtk_cmd" </dev/null
graphify_cmd="$(extract_hook_cmds 'graphify-out/graph.json' | head -1)"
[ -n "$graphify_cmd" ] || { echo "  ❌ no graphify hook command found in installed settings.json"; exit 1; }
expect_pass "graphify-absent PreToolUse hook does not crash (file-existence check, no binary call)" \
  env -i PATH="$NO_RTK_GRAPHIFY_PATH" bash -c "cd '$TARGET' && $graphify_cmd" </dev/null

echo "── Experiment 4: installed slash commands exist and parse ──"
for cmd_file in use-engineering-os.md superpowers-brainstorm.md superpowers-verify.md superpowers-plan.md; do
  f="$TARGET/.claude/commands/$cmd_file"
  expect_file "$f"
  [ -s "$f" ] || { echo "  ❌ $cmd_file is empty"; exit 1; }
  head -1 "$f" | grep -qE '^(#|---)' || { echo "  ❌ $cmd_file does not start with a markdown heading or frontmatter"; exit 1; }
  echo "  ✅ $cmd_file is non-empty and starts with a heading or frontmatter"
done

echo "── Experiment 5: templates/patterns reachable from installed target ──"
expect_contains "$TARGET/CLAUDE.md" "$ROOT/templates/"
expect_contains "$TARGET/CLAUDE.md" "$ROOT/patterns/"
[ -d "$ROOT/templates" ] || { echo "  ❌ referenced templates/ directory does not exist at the reference path"; exit 1; }
[ -d "$ROOT/patterns" ] || { echo "  ❌ referenced patterns/ directory does not exist at the reference path"; exit 1; }
echo "  ✅ templates/ and patterns/ exist at the reference path CLAUDE.md points to"

echo "── Experiment 6: enforce-tests.sh missing-tool contract inside the installed target ──"
# Build a hermetic PATH: only the specific tools enforce-tests.sh needs to run
# at all (bash, git, coreutils), deliberately excluding ruff/pytest. A plain
# "/usr/bin:/bin" guess is not reliable — a CI runner's base image can (and did)
# have ruff/pytest preinstalled there, making the "missing" premise false and
# the fixture fail for an unrelated reason (see
# lessons-learned/bugs/ci-environment-dependent-fixture-premise.md).
ISOLATED_BIN="$TMP/isolated-bin"
mkdir -p "$ISOLATED_BIN"
for tool in bash sh git grep sed awk cat cut tr wc head tail mkdir rm cp mv printf xargs find sort uniq dirname basename pwd env true false expr; do
  src="$(command -v "$tool" 2>/dev/null || true)"
  [ -n "$src" ] && ln -sf "$src" "$ISOLATED_BIN/$tool"
done
STACK_REPO="$TMP/stack-repo"
rm -rf "$STACK_REPO"
git init -q "$STACK_REPO"
git -C "$STACK_REPO" config user.email t@t
git -C "$STACK_REPO" config user.name t
printf 'requests\n' > "$STACK_REPO/requirements.txt"
printf 'print(1)\n' > "$STACK_REPO/app.py"
git -C "$STACK_REPO" add requirements.txt app.py
expect_fail "declared python stack with missing ruff hard-fails under CI=true" \
  env -i PATH="$ISOLATED_BIN" HOME="$HOME" CI=true bash -c "cd '$STACK_REPO' && bash '$ROOT/scripts/enforcement/enforce-tests.sh'"
expect_pass "declared python stack with missing ruff waives locally via EOS_ALLOW_MISSING_TOOLS" \
  env -i PATH="$ISOLATED_BIN" HOME="$HOME" EOS_ALLOW_MISSING_TOOLS=ruff,pytest bash -c "cd '$STACK_REPO' && bash '$ROOT/scripts/enforcement/enforce-tests.sh'"

echo "── Experiment 7: learning-loop fix-needs-test gate fires inside the installed target ──"
# Exercise the ACTUAL installed hook file at $TARGET/.git/hooks/commit-msg (the
# one use-in-project.sh copied), not the source scripts/hooks/commit-msg.sh —
# otherwise this fixture would stay green even if the installer stopped
# copying/updating the hook or the installed path drifted (Codex review finding
# on PR #184).
expect_file "$TARGET/.git/hooks/commit-msg"
expect_executable "$TARGET/.git/hooks/commit-msg"
printf 'def broken():\n    return 1\n' > "$TARGET/fix.py"
git -C "$TARGET" add fix.py
FIX_MSG_NO_TEST="$TMP/fix-msg-no-test.txt"
cat > "$FIX_MSG_NO_TEST" <<'EOF'
fix: correct a broken calculation

✅ עובד: the calculation now returns the right value.
❌ לא עובד: none known.
🔄 השתנה: fix.py.
🧪 בדיקות: manually verified.
EOF
expect_fail "installed commit-msg hook blocks a fix: commit with no regression test (learning-loop gate fires downstream)" \
  bash -c "cd '$TARGET' && '$TARGET/.git/hooks/commit-msg' '$FIX_MSG_NO_TEST'"
git -C "$TARGET" reset -q fix.py
rm -f "$TARGET/fix.py"

echo "clean install and usage experiments passed"
