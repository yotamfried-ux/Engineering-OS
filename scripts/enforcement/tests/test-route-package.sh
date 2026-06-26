#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PACKAGES_DIR="$ROOT/.claude/skills"
PACKAGE="$PACKAGES_DIR/engineering-route/SKILL.md"

test -f "$PACKAGE"

count="$(find "$PACKAGES_DIR" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')"
if [ "$count" != "1" ]; then
  echo "ERROR: exactly one project package is allowed in this rollout"
  exit 1
fi

python3 - "$PACKAGE" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
lines = text.splitlines()

if len(lines) < 5 or lines[0] != "---":
    raise SystemExit("package must start with YAML frontmatter")
try:
    end = lines[1:].index("---") + 1
except ValueError as exc:
    raise SystemExit("frontmatter must close") from exc

frontmatter = "\n".join(lines[1:end])
body = "\n".join(lines[end + 1:])
route_safety_rule = "Do not write code before " + "route planning."

required_frontmatter = [
    "name: engineering-route",
    "description:",
    "allowed-tools:",
    "  - Read",
    "  - Glob",
    "  - Grep",
]
for item in required_frontmatter:
    if item not in frontmatter:
        raise SystemExit(f"missing frontmatter item: {item}")

required_body = [
    "core/task-router.md",
    "core/workflow.md",
    "docs/research/official-patterns-adoption-audit.md",
    ".claude/plans/",
    "Route Plan",
    "Source of Truth Checks",
    "Connector Evidence",
    "Skill Evidence",
    route_safety_rule,
]
for item in required_body:
    if item not in body:
        raise SystemExit(f"missing body item: {item}")

blocked_terms = ["Write", "Edit", "MultiEdit", "Bash"]
for term in blocked_terms:
    if f"  - {term}" in frontmatter:
        raise SystemExit(f"package should not allow tool: {term}")

print("✅ engineering-route package is valid")
PY
