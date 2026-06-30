#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECKER="$ROOT/scripts/enforcement/check-connector-evidence.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
git init -q
git config user.email test@example.com
git config user.name test
mkdir -p .claude/plans src
echo base > README.md
git add README.md
git commit -qm base
BASE="$(git rev-parse HEAD)"
case_start(){ git checkout -q -B "$1" "$BASE"; rm -rf .claude src; mkdir -p .claude/plans src; }
pass(){ local n="$1"; if ! "$CHECKER" "$BASE" "$(git rev-parse HEAD)" >/dev/null; then echo "expected $n to pass"; exit 1; fi; echo "ok: $n"; }
fail(){ local n="$1"; if "$CHECKER" "$BASE" "$(git rev-parse HEAD)" >/dev/null 2>&1; then echo "expected $n to fail"; exit 1; fi; echo "ok: $n"; }
commit_all(){ git add .; git commit -qm "$1"; }

case_start connector-without-evidence
cat > .claude/plans/task.md <<'PLAN'
# Task
| Field | Value |
|---|---|
| External systems/connectors | GitHub |
PLAN
commit_all connector-without-evidence
fail connector-without-evidence

case_start connector-usage-too-vague
cat > .claude/plans/task.md <<'PLAN'
# Task
| Field | Value |
|---|---|
| External systems/connectors | GitHub |
## Connector Evidence
- connector: GitHub.
## Connector Usage Evidence
- GitHub.
PLAN
commit_all connector-usage-too-vague
fail connector-usage-too-vague

case_start connector-with-evidence
cat > .claude/plans/task.md <<'PLAN'
# Task
| Field | Value |
|---|---|
| External systems/connectors | GitHub |
## Connector Evidence
- connector: GitHub.
## Connector Usage Evidence
- source: GitHub repository files.
- action: checked repository files.
- result: found the relevant source.
- decision: selected the implementation path from the GitHub result.
PLAN
commit_all connector-with-evidence
pass connector-with-evidence

case_start connector-code-target-pass
cat > .claude/plans/task.md <<'PLAN'
# Task
| Field | Value |
|---|---|
| External systems/connectors | GitHub |
## Connector Evidence
- connector: GitHub.
## Connector Usage Evidence
- source: GitHub src/app.py file.
- action: checked src/app.py.
- result: confirmed src/app.py is the affected file.
- decision: changed only src/app.py.
- target: src/app.py.
PLAN
echo ok > src/app.py
commit_all connector-code-target-pass
pass connector-code-target-passes

case_start connector-code-wrong-target
cat > .claude/plans/task.md <<'PLAN'
# Task
| Field | Value |
|---|---|
| External systems/connectors | GitHub |
## Connector Evidence
- connector: GitHub.
## Connector Usage Evidence
- source: GitHub docs/other.md file.
- action: checked docs/other.md.
- result: confirmed docs/other.md.
- decision: changed implementation.
- target: docs/other.md.
PLAN
echo ok > src/app.py
commit_all connector-code-wrong-target
fail connector-code-wrong-target-fails

echo "connector route plan checker tests passed"
