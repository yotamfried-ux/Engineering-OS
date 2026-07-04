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

expect_file() { [ -f "$1" ] || { echo "FAIL missing file: $1"; exit 1; }; echo "OK file exists: ${1#$TARGET/}"; }
expect_executable() { [ -x "$1" ] || { echo "FAIL not executable: $1"; exit 1; }; echo "OK executable: ${1#$TARGET/}"; }
expect_contains() { grep -q "$2" "$1" || { echo "FAIL expected $1 to contain $2"; exit 1; }; echo "OK contains: ${1#$TARGET/} -> $2"; }
expect_pass() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "OK $name"; else echo "FAIL expected pass: $name"; exit 1; fi; }
expect_fail() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "FAIL expected fail: $name"; exit 1; else echo "OK $name"; fi; }

required_workflows() {
  awk -F'"' '/^REQUIRED_WORKFLOWS_DEFAULT=/ { print $2; exit }' "$MERGE_CHECK" | tr ' ' '\n' | sed '/^$/d'
}

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
| Task type | clean install usage simulation |
| Task class | unclassified |
| Domain tags | clean-install, runtime-hook, fixture |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | task router was read |
| Workflow evidence | workflow was read |
| Templates | not required |
| Architecture guides | Runtime hook behavior checked through the installed Engineering OS target. |
| Patterns | not required |
| External systems/connectors | not required |
| Skills | not required |
| Validation gates | pre-tool-use-runtime-evidence.sh and post-tool-use-read-evidence.sh |
| Evidence to check | local hook exit codes and evidence ledger entries |
| User decisions required | none |

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
  {
    printf '{"workflow_runs":[\n'
    local first=1
    while IFS= read -r wf; do
      [ -n "$wf" ] || continue
      [ "$first" -eq 1 ] || printf ',\n'
      first=0
      if [ "$wf" = "enforcement-tests" ]; then
        printf ' {"name":"%s","status":"%s","conclusion":"%s"}' "$wf" "$enforcement_status" "$enforcement_conclusion"
      else
        printf ' {"name":"%s","status":"completed","conclusion":"success"}' "$wf"
      fi
    done < <(required_workflows)
    printf '\n]}\n'
  } > "$file"
}

echo "Experiment 1: clean install into target repo"
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

while IFS= read -r wf; do
  case "$wf" in enforcement-tests) continue ;; esac
  expect_file "$TARGET/.github/workflows/$wf.yml"
done < <(required_workflows)

expect_contains "$TARGET/.claude/settings.json" "pre-tool-use-json-guard.sh"
expect_contains "$TARGET/.claude/settings.json" "pre-tool-use-runtime-evidence.sh"
expect_contains "$TARGET/.claude/settings.json" "check-plan-scope.sh"
expect_contains "$TARGET/.claude/settings.json" "rtk hook claude"
expect_contains "$TARGET/.claude/settings.json" "SessionStart"
expect_contains "$TARGET/.claude/settings.json" "scripts/session-setup.sh"
expect_contains "$ROOT/scripts/session-setup.sh" "rtk init -g"
expect_contains "$ROOT/scripts/session-setup.sh" "rtk --version"
expect_contains "$TARGET/.claude/settings.json" "$ROOT/scripts/enforcement"

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
expect_pass "installed check-connector-evidence.sh runs from the target project" \
  bash -c "cd '$TARGET/noplans-repo' && bash '$TARGET/scripts/enforcement/check-connector-evidence.sh' HEAD HEAD"
expect_pass "installed check-workflow-evidence.sh runs from the target project" \
  bash -c "cd '$TARGET/noplans-repo' && bash '$TARGET/scripts/enforcement/check-workflow-evidence.sh' HEAD HEAD"
expect_pass "installed check-documentation-asset-evidence.sh runs from the target project" \
  bash -c "cd '$TARGET/noplans-repo' && bash '$TARGET/scripts/enforcement/check-documentation-asset-evidence.sh' HEAD HEAD"
: > "$TMP/empty-files.txt"
expect_pass "installed check-capability-staged-changes.sh runs from the target project" \
  bash "$TARGET/scripts/enforcement/check-capability-staged-changes.sh" --files-from "$TMP/empty-files.txt"

run_install
managed_count="$(grep -c '<!-- BEGIN engineering-os (managed) -->' "$TARGET/CLAUDE.md")"
[ "$managed_count" = "1" ] || { echo "FAIL managed CLAUDE block duplicated: $managed_count"; exit 1; }
echo "OK install is idempotent: managed block count = 1"
settings_count="$(find "$TARGET/.claude" -name settings.json | wc -l | xargs)"
[ "$settings_count" = "1" ] || { echo "FAIL settings duplicated: $settings_count"; exit 1; }
echo "OK install is idempotent: one settings file"

echo "Experiment 2: actual usage gate simulation"
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

echo "Experiment 3: RTK/graphify PATH-absence fallback"
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
NO_RTK_GRAPHIFY_PATH="/usr/bin:/bin"
rtk_cmd="$(extract_hook_cmds 'rtk hook claude' | head -1)"
[ -n "$rtk_cmd" ] || { echo "FAIL no rtk hook command found in installed settings.json"; exit 1; }
expect_pass "rtk-absent PreToolUse hook does not crash" \
  env -i PATH="$NO_RTK_GRAPHIFY_PATH" HOME="$HOME" bash -c "cd '$TARGET' && $rtk_cmd" </dev/null
graphify_cmd="$(extract_hook_cmds 'graphify-out/graph.json' | head -1)"
[ -n "$graphify_cmd" ] || { echo "FAIL no graphify hook command found in installed settings.json"; exit 1; }
expect_pass "graphify-absent PreToolUse hook does not crash" \
  env -i PATH="$NO_RTK_GRAPHIFY_PATH" HOME="$HOME" bash -c "cd '$TARGET' && $graphify_cmd" </dev/null

echo "Experiment 4: installed slash commands exist and parse"
for cmd_file in use-engineering-os.md superpowers-brainstorm.md superpowers-verify.md superpowers-plan.md; do
  f="$TARGET/.claude/commands/$cmd_file"
  expect_file "$f"
  [ -s "$f" ] || { echo "FAIL $cmd_file is empty"; exit 1; }
  head -1 "$f" | grep -qE '^(#|---)' || { echo "FAIL $cmd_file does not start with a markdown heading or frontmatter"; exit 1; }
  echo "OK $cmd_file is non-empty and starts with a heading or frontmatter"
done

echo "Experiment 5: templates/patterns reachable from installed target"
expect_contains "$TARGET/CLAUDE.md" "$ROOT/templates/"
expect_contains "$TARGET/CLAUDE.md" "$ROOT/patterns/"
[ -d "$ROOT/templates" ] || { echo "FAIL referenced templates directory does not exist"; exit 1; }
[ -d "$ROOT/patterns" ] || { echo "FAIL referenced patterns directory does not exist"; exit 1; }
echo "OK templates and patterns exist at the reference path"

echo "Experiment 6: enforce-tests.sh missing-tool contract inside the installed target"
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
expect_fail "declared python stack with missing ruff fails locally without a waiver" \
  env -i PATH="$ISOLATED_BIN" HOME="$HOME" bash -c "cd '$STACK_REPO' && bash '$ROOT/scripts/enforcement/enforce-tests.sh'"
expect_pass "declared python stack with missing ruff waives locally via EOS_ALLOW_MISSING_TOOLS" \
  env -i PATH="$ISOLATED_BIN" HOME="$HOME" EOS_ALLOW_MISSING_TOOLS=ruff,pytest bash -c "cd '$STACK_REPO' && bash '$ROOT/scripts/enforcement/enforce-tests.sh'"

echo "Experiment 7: learning-loop fix-needs-test gate fires inside the installed target"
expect_file "$TARGET/.git/hooks/commit-msg"
expect_executable "$TARGET/.git/hooks/commit-msg"
printf 'def broken():\n    return 1\n' > "$TARGET/fix.py"
git -C "$TARGET" add fix.py
FIX_MSG_NO_TEST="$TMP/fix-msg-no-test.txt"
cat > "$FIX_MSG_NO_TEST" <<'EOF'
fix: correct a broken calculation

works: calculation now returns the right value.
not working: none known.
changed: fix.py.
tests: manually verified.
EOF
expect_fail "installed commit-msg hook blocks a fix commit with no regression test" \
  bash -c "cd '$TARGET' && '$TARGET/.git/hooks/commit-msg' '$FIX_MSG_NO_TEST'"
git -C "$TARGET" reset -q fix.py
rm -f "$TARGET/fix.py"

echo "clean install and usage experiments passed"
