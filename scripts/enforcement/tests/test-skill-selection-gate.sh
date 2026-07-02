#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-required-skills.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

make_plan() {
  local path="$1" task="$2" tags="$3" skills="$4"
  cat > "$path" <<EOF
# Route Plan

| Field | Decision |
|---|---|
| Task class | $task |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | $tags |
| Skills | $skills |

## Capability Waiver

Reason: fixture.

## Source of Truth Checks

| Source | Status |
|---|---|
| fixture | checked |
EOF
}

make_plan "$TMP/ui.md" unclassified "frontend, react" "ui-ux-pro-max"
(cd "$TMP" && bash "$CHECK" --plan "$TMP/ui.md" --target app/components/Button.tsx)
make_plan "$TMP/ui-miss.md" unclassified "frontend, react" "None"
(cd "$TMP" && ! bash "$CHECK" --plan "$TMP/ui-miss.md" --target app/components/Button.tsx)

make_plan "$TMP/pay.md" unclassified "stripe, payments" "superpowers, security-review"
(cd "$TMP" && bash "$CHECK" --plan "$TMP/pay.md" --target src/payments/stripe.ts)
make_plan "$TMP/pay-miss.md" unclassified "stripe, payments" "superpowers"
(cd "$TMP" && ! bash "$CHECK" --plan "$TMP/pay-miss.md" --target src/payments/stripe.ts)

make_plan "$TMP/large.md" unclassified "architecture, large-change, refactor" "superpowers, graphify"
(cd "$TMP" && bash "$CHECK" --plan "$TMP/large.md" --target src/modules/index.ts)
make_plan "$TMP/large-miss.md" unclassified "architecture, large-change, refactor" "superpowers"
(cd "$TMP" && ! bash "$CHECK" --plan "$TMP/large-miss.md" --target src/modules/index.ts)

make_plan "$TMP/code.md" code_change "backend" "superpowers"
(cd "$TMP" && bash "$CHECK" --plan "$TMP/code.md" --target src/app.ts)
make_plan "$TMP/code-miss.md" code_change "backend" "None"
(cd "$TMP" && ! bash "$CHECK" --plan "$TMP/code-miss.md" --target src/app.ts)

make_plan "$TMP/dep.md" unclassified "frontend" "frontend-design"
(cd "$TMP" && ! bash "$CHECK" --plan "$TMP/dep.md" --target app/page.tsx)

# claude-mem: multi-session/context-carryover work requires the memory skill.
make_plan "$TMP/mem.md" unclassified "multi-session, context-carryover" "claude-mem"
(cd "$TMP" && bash "$CHECK" --plan "$TMP/mem.md" --target scripts/session.sh)
make_plan "$TMP/mem-miss.md" unclassified "multi-session, context-carryover" "None"
(cd "$TMP" && ! bash "$CHECK" --plan "$TMP/mem-miss.md" --target scripts/session.sh)

# unavailable-environment waiver covers claude-mem.
make_plan "$TMP/mem-waiver.md" unclassified "multi-session, context-carryover" "None"
cat >> "$TMP/mem-waiver.md" <<'EOF'

## Skill Selection Waiver

- claude-mem: environment lacks claude-mem in this remote session; manual context record is used instead.
EOF
(cd "$TMP" && bash "$CHECK" --plan "$TMP/mem-waiver.md" --target scripts/session.sh)

# claude-code-workflows: large-refactor work requires the review workflow skill.
make_plan "$TMP/lr-miss.md" unclassified "large-refactor" "superpowers, graphify"
(cd "$TMP" && ! bash "$CHECK" --plan "$TMP/lr-miss.md" --target src/modules/index.ts)
make_plan "$TMP/lr.md" unclassified "large-refactor" "superpowers, graphify, claude-code-workflows"
(cd "$TMP" && bash "$CHECK" --plan "$TMP/lr.md" --target src/modules/index.ts)

# precision: a plain memory-leak bug does not force claude-mem.
make_plan "$TMP/leak.md" unclassified "memory leak, debugging" "superpowers"
(cd "$TMP" && bash "$CHECK" --plan "$TMP/leak.md" --target src/leak.ts)

# inventory coverage: every external-skills/<name>/ has a rule or documented entry.
bash "$CHECK" --check-coverage
mkdir -p "$TMP/skills-extra/new-unmapped-skill"
! bash "$CHECK" --check-coverage --skills-dir "$TMP/skills-extra"

echo "skill selection checks passed"
