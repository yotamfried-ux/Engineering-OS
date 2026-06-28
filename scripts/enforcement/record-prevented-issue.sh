#!/usr/bin/env bash
set -euo pipefail

FILE="${1:-}"
[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "usage: $0 <lesson-file.md>" >&2; exit 2; }

python3 - "$FILE" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
pattern = re.compile(r"(?m)^(##\s+Prevented Future Issues:\s*)(\d+)\s*$")
match = pattern.search(text)
if match:
    text = pattern.sub(lambda m: f"{m.group(1)}{int(m.group(2)) + 1}", text, count=1)
else:
    if not text.endswith("\n"):
        text += "\n"
    text += "\n## Prevented Future Issues: 1\n"
path.write_text(text, encoding="utf-8")
PY
