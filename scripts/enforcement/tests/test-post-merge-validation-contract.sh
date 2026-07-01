#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-post-merge-validation-contract.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

expect_pass() { local name="$1"; shift; if "$@" >"$TMP/$name.out" 2>&1; then echo "ok: $name"; else echo "expected pass: $name"; cat "$TMP/$name.out"; exit 1; fi; }
expect_fail() { local name="$1"; shift; if "$@" >"$TMP/$name.out" 2>&1; then echo "unexpected pass: $name"; cat "$TMP/$name.out"; exit 1; else echo "ok: $name"; fi; }

cat > "$TMP/good.yml" <<'YAML'
name: post-merge-validation
on:
  push:
    branches: [main]
  workflow_dispatch:
permissions:
  contents: read
  issues: write
jobs:
  validate-main:
    steps:
      - name: Run full post-merge main validation suite
        run: bash scripts/enforcement/run-post-merge-validation-suite.sh
      - name: Verify post-merge repair-loop contract
        run: bash scripts/enforcement/check-post-merge-validation-contract.sh --workflow .github/workflows/post-merge-validation.yml
      - name: Open repair loop issue
        if: failure()
        run: gh api --method POST "repos/${GITHUB_REPOSITORY}/issues" -f title="repair" -f body="issue repair loop"
YAML

cat > "$TMP/missing-push.yml" <<'YAML'
name: post-merge-validation
on:
  workflow_dispatch:
permissions:
  contents: read
  issues: write
jobs:
  validate-main:
    steps:
      - run: echo repair issue
YAML

cat > "$TMP/missing-repair.yml" <<'YAML'
name: post-merge-validation
on:
  push:
    branches: [main]
  workflow_dispatch:
permissions:
  contents: read
  issues: write
jobs:
  validate-main:
    steps:
      - run: bash scripts/enforcement/run-post-merge-validation-suite.sh
      - run: bash scripts/enforcement/check-post-merge-validation-contract.sh --workflow .github/workflows/post-merge-validation.yml
YAML

cat > "$TMP/waiver.yml" <<'YAML'
name: post-merge-validation
# EOS_POST_MERGE_REPAIR_WAIVER: temporary fixture waiver for an environment where issue creation is unavailable but explicit review evidence is required.
on:
  workflow_dispatch:
YAML

expect_pass current_workflow_passes bash "$CHECK" --workflow "$ROOT/.github/workflows/post-merge-validation.yml"
expect_pass good_workflow_passes bash "$CHECK" --workflow "$TMP/good.yml"
expect_fail missing_push_main_fails bash "$CHECK" --workflow "$TMP/missing-push.yml"
expect_fail missing_repair_issue_fails bash "$CHECK" --workflow "$TMP/missing-repair.yml"
expect_fail waiver_requires_allow_flag bash "$CHECK" --workflow "$TMP/waiver.yml"
expect_pass explicit_waiver_passes bash "$CHECK" --workflow "$TMP/waiver.yml" --allow-waiver

fakebin="$TMP/fakebin"
mkdir -p "$fakebin"
cat > "$fakebin/gh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" > "$GH_CAPTURE"
SH
chmod +x "$fakebin/gh"
GH_CAPTURE="$TMP/gh-call.txt" \
PATH="$fakebin:$PATH" \
GITHUB_REPOSITORY="owner/repo" \
REPAIR_SHA="abc123" \
REPAIR_RUN_URL="https://example.invalid/run/1" \
bash -c 'body="Post-merge validation failed on main. Repair loop required. Commit: ${REPAIR_SHA}. Run: ${REPAIR_RUN_URL}."; gh api --method POST "repos/${GITHUB_REPOSITORY}/issues" -f title="Post-merge validation failed on main: ${REPAIR_SHA}" -f body="$body"'

grep -q -- '--method POST' "$TMP/gh-call.txt"
grep -q 'repos/owner/repo/issues' "$TMP/gh-call.txt"
grep -q 'abc123' "$TMP/gh-call.txt"
grep -q 'https://example.invalid/run/1' "$TMP/gh-call.txt"
echo "ok: simulated_repair_issue_path"

echo "post-merge validation contract tests passed"
