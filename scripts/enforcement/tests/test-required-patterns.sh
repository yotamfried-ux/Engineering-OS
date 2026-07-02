#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-required-patterns.sh"
chmod +x "$CHECK"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG_FILE="$TMP/required-patterns.log"

pass() { local name="$1"; shift; "$@" >"$LOG_FILE" 2>&1 || { echo "fail: $name"; cat "$LOG_FILE"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$LOG_FILE" 2>&1; then echo "unexpected pass: $name"; cat "$LOG_FILE"; exit 1; else echo "ok: $name"; fi; }

write_plan() {
  local tags="$1" patterns="$2"
  cat > "$TMP/plan.md" <<EOF
# Route Plan

| Field | Decision |
|---|---|
| Task class | feature |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | $tags |
| Templates | not required |
| Patterns | $patterns |
| External systems/connectors | none |
| Skills | none |
EOF
}

append_pattern_waiver() {
  cat >> "$TMP/plan.md" <<EOF

## Pattern Selection Waiver

$1
EOF
}

run_check() { bash "$CHECK" --plan "$TMP/plan.md" --target "$1"; }

pass checker_present test -f "$CHECK"

# positive: billing-tagged plan consulting patterns/billing passes.
write_plan "billing, payments" "patterns/billing/README.md"
pass billing_tag_with_billing_pattern_passes run_check src/billing/invoice.ts

# negative: billing-tagged plan with no billing pattern fails.
write_plan "billing, payments" "none"
failcase billing_tag_without_pattern_fails run_check src/billing/invoice.ts

# negative: auth-tagged plan consulting only an unrelated domain fails.
write_plan "auth, login" "patterns/billing/README.md"
failcase auth_tag_with_wrong_domain_pattern_fails run_check src/auth/session.ts

# waiver: domain-named waiver passes.
write_plan "billing, payments" "none"
append_pattern_waiver "Reason: billing patterns do not apply to this fixture because the change is config-only."
pass billing_waiver_naming_domain_passes run_check src/billing/invoice.ts

# waiver precision: waiver naming a different domain does not cover billing.
write_plan "billing, payments" "none"
append_pattern_waiver "Reason: auth patterns are out of scope for this fixture."
failcase waiver_for_other_domain_does_not_cover_billing run_check src/billing/invoice.ts

# precision: tags that are not registry domains are never forced (substrings do not match).
write_plan "authoring, billingual" "none"
pass non_domain_tags_are_not_forced run_check src/docs/guide.md

# precision: governance-style tags with no registry domain pass with no patterns.
write_plan "readiness, enforcement" "not required"
pass governance_tags_do_not_force_patterns run_check scripts/enforcement/foo.sh

# invalid: registry with no domain entries fails closed.
printf 'patterns: []\n' > "$TMP/empty-registry.yaml"
write_plan "billing" "none"
failcase malformed_registry_fails_closed bash "$CHECK" --plan "$TMP/plan.md" --target src/x.ts --registry "$TMP/empty-registry.yaml"

echo "required pattern simulations passed"
