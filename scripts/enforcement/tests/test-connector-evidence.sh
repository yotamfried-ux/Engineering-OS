#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECKER="$ROOT/scripts/enforcement/check-connector-evidence.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
git init -q
git config user.email test@example.com
git config user.name test
echo base > README.md
git add README.md
git commit -qm base
BASE="$(git rev-parse HEAD)"
mk(){ git checkout -q -B "$1" "$BASE"; rm -rf .claude src; mkdir -p .claude/plans src; }
put(){ printf '%s
' "$1" > .claude/plans/task.md; }
ci(){ git add .; git commit -qm "$1"; }
ok(){ bash "$CHECKER" "$BASE" "$(git rev-parse HEAD)" >/dev/null || { echo "expected $1 to pass"; exit 1; }; echo "ok: $1"; }
no(){ if bash "$CHECKER" "$BASE" "$(git rev-parse HEAD)" >/dev/null 2>&1; then echo "expected $1 to fail"; exit 1; fi; echo "ok: $1"; }

mk connector-without-evidence
put '# Task
| Field | Value |
|---|---|
| External systems/connectors | GitHub |'
ci connector-without-evidence
no connector-without-evidence

mk connector-usage-too-vague
put '# Task
| Field | Value |
|---|---|
| External systems/connectors | GitHub |
## Connector Evidence
- connector: GitHub.
## Connector Usage Evidence
- GitHub.'
ci connector-usage-too-vague
no connector-usage-too-vague

mk connector-with-evidence
put '# Task
| Field | Value |
|---|---|
| External systems/connectors | GitHub |
## Connector Evidence
- connector: GitHub.
## Connector Usage Evidence
- source: GitHub repository files.
- action: checked repository files.
- result: found the relevant source.
- decision: selected the implementation path from the GitHub result.'
ci connector-with-evidence
ok connector-with-evidence

mk connector-code-target-pass
put '# Task
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
- target: src/app.py.'
echo ok > src/app.py
ci connector-code-target-pass
ok connector-code-target-passes

mk connector-code-wrong-target
put '# Task
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
- target: docs/other.md.'
echo ok > src/app.py
ci connector-code-wrong-target
no connector-code-wrong-target-fails

echo "connector route plan checker tests passed"
