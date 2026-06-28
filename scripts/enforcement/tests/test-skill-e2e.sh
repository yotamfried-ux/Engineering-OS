#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ENFORCE_SKILL="$ROOT/scripts/enforcement/enforce-skill.sh"
PRECHECK="$ROOT/scripts/enforcement/pre-tool-use-runtime-evidence.sh"
READ_RECORDER="$ROOT/scripts/enforcement/post-tool-use-read-evidence.sh"
BOOTSTRAP="$ROOT/scripts/skill-bootstrap.sh"
USE_IN_PROJECT="$ROOT/scripts/use-in-project.sh"
REGISTRY="$ROOT/external-skills/README.md"
POLICY="$ROOT/core/skill-orchestration-policy.md"
chmod +x "$ENFORCE_SKILL" "$PRECHECK" "$READ_RECORDER" "$BOOTSTRAP" "$USE_IN_PROJECT"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

expect_pass() { local name="$1"; shift; if "$@" >/tmp/eos-skill-e2e.log 2>&1; then echo "  ✅ $name"; else echo "  ❌ expected pass: $name"; cat /tmp/eos-skill-e2e.log; exit 1; fi; }
expect_fail() { local name="$1"; shift; if "$@" >/tmp/eos-skill-e2e.log 2>&1; then echo "  ❌ expected fail: $name"; cat /tmp/eos-skill-e2e.log; exit 1; else echo "  ✅ $name"; fi; }
expect_contains() { grep -qF "$2" "$1" || { echo "  ❌ expected $1 to contain $2"; exit 1; }; echo "  ✅ contains: ${1#$TMP/} -> $2"; }

make_repo() {
  local repo="$1"
  mkdir -p "$repo"
  git init "$repo" >/dev/null
  git -C "$repo" config user.email test@example.com
  git -C "$repo" config user.name test
  cp -R "$ROOT/external-skills" "$repo/external-skills"
  mkdir -p "$repo/scripts/enforcement"
  cp "$ENFORCE_SKILL" "$repo/scripts/enforcement/enforce-skill.sh"
  cp -R "$ROOT/scripts/enforcement/lib" "$repo/scripts/enforcement/lib"
  (cd "$repo" && git add . && git commit -m init >/dev/null)
}

run_enforce_skill_in() { (cd "$1" && bash scripts/enforcement/enforce-skill.sh); }

run_precheck_in() {
  local repo="$1" file="$2"
  (cd "$repo" && printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$file" | "$PRECHECK")
}

record_read_in() {
  local repo="$1" file="$2"
  (cd "$repo" && printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$file" | "$READ_RECORDER" >/dev/null)
}

write_runtime_plan() {
  local repo="$1" skill_value="$2"
  mkdir -p "$repo/.claude/plans" "$repo/.claude/.evidence"
  cat > "$repo/.claude/plans/skill-runtime.md" <<PLAN
# Route Plan

| Field | Value |
|---|---|
| Task class | unclassified |
| Task-router evidence | task-router read |
| Workflow evidence | workflow read |
| Templates | none |
| Patterns | none |
| External systems/connectors | none |
| Skills | $skill_value |

## Capability Waiver

Reason: skill E2E simulation isolates runtime skill evidence behavior.

## Source of Truth Checks

| Source | Result |
|---|---|
| skill runtime evidence gate | required |
PLAN
}

seed_router_workflow_evidence() {
  local repo="$1"
  : > "$repo/.claude/.evidence/ledger"
  export EOS_EVIDENCE_DIR=".claude/.evidence"
  record_read_in "$repo" core/task-router.md
  record_read_in "$repo" core/workflow.md
}

echo "── Skill simulation 1: new skill contract is enforced ──"
SKILL_REPO="$TMP/skill-contract"
make_repo "$SKILL_REPO"
mkdir -p "$SKILL_REPO/external-skills/example-skill"
cat > "$SKILL_REPO/external-skills/example-skill/README.md" <<'EOF_SKILL'
# example-skill
EOF_SKILL
(cd "$SKILL_REPO" && git add external-skills/example-skill/README.md)
expect_fail "skill with missing contract files is blocked" run_enforce_skill_in "$SKILL_REPO"
cat > "$SKILL_REPO/external-skills/example-skill/integration.md" <<'EOF_SKILL'
# integration
EOF_SKILL
cat > "$SKILL_REPO/external-skills/example-skill/policy.md" <<'EOF_SKILL'
# policy
EOF_SKILL
cat > "$SKILL_REPO/external-skills/example-skill/activation.md" <<'EOF_SKILL'
# activation
EOF_SKILL
(cd "$SKILL_REPO" && git add external-skills/example-skill)
expect_fail "complete but unregistered skill is blocked" run_enforce_skill_in "$SKILL_REPO"
cat >> "$SKILL_REPO/external-skills/README.md" <<'EOF_REG'
| **[example-skill](./example-skill/)** | planning | L1 | fixture | fixture |
EOF_REG
(cd "$SKILL_REPO" && git add external-skills/README.md)
expect_pass "complete registered skill is allowed" run_enforce_skill_in "$SKILL_REPO"

echo "── Skill simulation 2: runtime declared skill needs evidence ──"
RUNTIME_REPO="$TMP/runtime-skill"
mkdir -p "$RUNTIME_REPO"
git init "$RUNTIME_REPO" >/dev/null
mkdir -p "$RUNTIME_REPO/.claude/.evidence"
write_runtime_plan "$RUNTIME_REPO" "superpowers"
(cd "$RUNTIME_REPO" && git config user.email test@example.com && git config user.name test)
seed_router_workflow_evidence "$RUNTIME_REPO"
export EOS_EVIDENCE_DIR=".claude/.evidence"
export EOS_PRETOOL_LEGACY_EXIT=1
expect_fail "write blocked when plan declares superpowers but no skill evidence exists" run_precheck_in "$RUNTIME_REPO" src/app.ts
printf 'now\tskill_used\tsuperpowers\n' >> "$RUNTIME_REPO/.claude/.evidence/ledger"
expect_pass "write allowed after declared skill evidence exists" run_precheck_in "$RUNTIME_REPO" src/app.ts

echo "── Skill simulation 3: target install keeps skill wiring and bootstrap reports missing defaults ──"
TARGET="$TMP/target-app"
mkdir -p "$TARGET"
git init "$TARGET" >/dev/null
git -C "$TARGET" config user.email test@example.com
git -C "$TARGET" config user.name test
(cd "$TARGET" && EOS_CONTRACT_TEST=1 ENGINEERING_OS_HOME="$ROOT" bash "$USE_IN_PROJECT" >/dev/null)
expect_contains "$TARGET/.claude/commands/superpowers-brainstorm.md" "brainstorm"
expect_contains "$TARGET/.claude/commands/superpowers-verify.md" "verify"
bootstrap_json="$(cd "$TARGET" && ENGINEERING_OS_HOME="$ROOT" CLAUDE_CONFIG_DIR="$TMP/empty-claude" bash "$BOOTSTRAP" --profile default --json)"
printf '%s' "$bootstrap_json" | grep -q '"name":"superpowers"' || { echo "  ❌ bootstrap JSON missing superpowers"; exit 1; }
printf '%s' "$bootstrap_json" | grep -q '"name":"security-review"' || { echo "  ❌ bootstrap JSON missing security-review"; exit 1; }
printf '%s' "$bootstrap_json" | grep -q '"name":"graphify"' || { echo "  ❌ bootstrap JSON missing graphify"; exit 1; }
printf '%s' "$bootstrap_json" | grep -q '"name":"rtk"' || { echo "  ❌ bootstrap JSON missing rtk"; exit 1; }
printf '%s' "$bootstrap_json" | grep -q '"name":"claude-mem"' || { echo "  ❌ bootstrap JSON missing claude-mem"; exit 1; }
echo "  ✅ default bootstrap profile lists every default L2 skill"

echo "── Skill simulation 4: deprecated skill and engine boundaries are enforced by docs/index ──"
grep -qF 'frontend-design](./frontend-design/)** ⚠️ **DEPRECATED' "$REGISTRY" || { echo "  ❌ frontend-design deprecation missing"; exit 1; }
grep -qF 'Nemotron is an engine, not a skill' "$REGISTRY" || { echo "  ❌ Nemotron engine boundary missing"; exit 1; }
grep -qF 'frontend-design' "$POLICY" && grep -qF 'DEPRECATED' "$POLICY" || { echo "  ❌ policy missing frontend-design deprecation"; exit 1; }
echo "  ✅ deprecated frontend-design and Nemotron engine boundary are documented"

echo "skill E2E simulations passed"
