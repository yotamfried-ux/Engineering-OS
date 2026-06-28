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

echo "skill selection checks passed"
