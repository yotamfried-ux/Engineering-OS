#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECKER="$ROOT/scripts/enforcement/check-scaling-extension.py"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

python3 "$CHECKER" --root "$ROOT"

run_case() {
  local name="$1"
  local mutation="$2"
  local repo="$TMPDIR/$name"
  mkdir -p "$repo"
  tar --exclude='.git' -C "$ROOT" -cf - . | tar -C "$repo" -xf -
  python3 - "$repo" "$mutation" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
mutation = sys.argv[2]

def rewrite(rel, keep):
    path = root / rel
    lines = path.read_text().splitlines()
    path.write_text("\n".join(line for line in lines if keep(line)) + "\n")

if mutation == "template":
    (root / "templates" / "unregistered-app").mkdir(parents=True)
elif mutation == "roadmap":
    rewrite("scripts/enforcement/project-type-roadmaps.tsv", lambda line: not line.startswith("web-application\t"))
elif mutation == "docs":
    path = root / "scripts/enforcement/documentation-sources.tsv"
    out = []
    for line in path.read_text().splitlines():
        cells = line.split("\t")
        if cells and cells[0].startswith("web-"):
            cells[6] = "NONE"
        out.append("\t".join(cells))
    path.write_text("\n".join(out) + "\n")
elif mutation == "patterns":
    for rel in ["scripts/enforcement/pattern-requirements.tsv", "scripts/enforcement/skill-requirements.tsv"]:
        rewrite(rel, lambda line: "\tweb-application\t" not in line)
elif mutation == "game":
    path = root / "scripts/enforcement/project-type-roadmaps.tsv"
    out = []
    for line in path.read_text().splitlines():
        cells = line.split("\t")
        if cells and cells[0] == "game-development":
            cells[6] = "telemetry export"
        out.append("\t".join(cells))
    path.write_text("\n".join(out) + "\n")
else:
    raise SystemExit(f"unknown mutation: {mutation}")
PY
  if python3 "$repo/scripts/enforcement/check-scaling-extension.py" --root "$repo" >/tmp/scaling-$name.out 2>&1; then
    echo "ERROR_FOR_AGENT: scaling checker accepted incomplete fixture $name" >&2
    cat /tmp/scaling-$name.out >&2
    exit 1
  fi
  echo "rejected incomplete fixture: $name"
}

run_case missing-template template
run_case missing-roadmap roadmap
run_case missing-docs-metadata docs
run_case missing-pattern-skill patterns
run_case missing-game-evidence game

echo "scaling extension checker tests passed"
