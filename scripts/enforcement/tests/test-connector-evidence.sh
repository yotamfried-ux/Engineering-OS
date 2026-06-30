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
mk(){ git checkout -q -B "$1" "$BASE"; rm -rf .claude src scripts; mkdir -p .claude/plans src scripts/enforcement; }
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
- action: checked GitHub repository files.
- result: GitHub showed the relevant source.
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
- action: checked GitHub src/app.py.
- result: GitHub confirmed src/app.py is the affected file.
- decision: changed only src/app.py based on GitHub evidence.
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
- action: checked GitHub docs/other.md.
- result: GitHub confirmed docs/other.md.
- decision: changed implementation based on GitHub evidence.
- target: docs/other.md.'
echo ok > src/app.py
ci connector-code-wrong-target
no connector-code-wrong-target-fails

mk no-connector-na-pass
put '# Task
| Field | Value |
|---|---|
| External systems/connectors | n/a |'
echo ok > src/app.py
ci no-connector-na-pass
ok no-connector-na-pass

mk connector-full-name-required
put '# Task
| Field | Value |
|---|---|
| External systems/connectors | GitHub REST API v3, GitHub GraphQL API |
## Connector Evidence
- connector: GitHub.
## Connector Usage Evidence
- source: GitHub repository files.
- action: checked GitHub repository files.
- result: GitHub showed the relevant source.
- decision: selected the implementation path from the GitHub result.'
ci connector-full-name-required
no connector-full-name-required

mk connector-unavailable-scoped-active-missing-usage
put '# Task
| Field | Value |
|---|---|
| External systems/connectors | GitHub, Notion |
## Connector Evidence
- GitHub: read the repository checker.
- Notion: unavailable; fallback plan file used.
## Connector Usage Evidence
- Notion: unavailable; fallback plan file used.'
ci connector-unavailable-scoped-active-missing-usage
no connector-unavailable-scoped-active-missing-usage

mk connector-unavailable-scoped-active-pass
put '# Task
| Field | Value |
|---|---|
| External systems/connectors | GitHub, Notion |
## Connector Evidence
- GitHub: read the repository checker.
- Notion: unavailable; fallback plan file used.
## Connector Usage Evidence
- source: GitHub scripts/enforcement/check-connector-evidence.sh.
- action: checked GitHub checker behavior.
- result: GitHub showed connector evidence validation code.
- decision: changed the checker based on GitHub evidence.
- target: scripts/enforcement/check-connector-evidence.sh.'
echo ok > scripts/enforcement/check-connector-evidence.sh
ci connector-unavailable-scoped-active-pass
ok connector-unavailable-scoped-active-pass

mk connector-empty-labels-fail
put '# Task
| Field | Value |
|---|---|
| External systems/connectors | GitHub |
## Connector Evidence
- connector: GitHub.
## Connector Usage Evidence
- source:
- action:
- result:
- decision:'
ci connector-empty-labels-fail
no connector-empty-labels-fail

mk connector-decision-label-only-fail
put '# Task
| Field | Value |
|---|---|
| External systems/connectors | GitHub |
## Connector Evidence
- connector: GitHub.
## Connector Usage Evidence
- source: GitHub repository files.
- action: checked GitHub repository files.
- result: GitHub showed the relevant source.
- decision: read GitHub data.'
ci connector-decision-label-only-fail
no connector-decision-label-only-fail

echo "connector route plan checker tests passed"
