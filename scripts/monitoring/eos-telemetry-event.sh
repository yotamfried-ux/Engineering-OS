#!/usr/bin/env bash
set -euo pipefail

# Privacy-safe local telemetry recorder for Engineering OS hook events.
# It intentionally records metadata only. It never stores prompts, file contents,
# raw bash commands, raw connector payloads, environment values, or secrets.

EVENT_NAME="${1:-unknown}"

if [ "${EOS_TELEMETRY_DISABLED:-0}" = "1" ]; then
  # Always consume stdin so hook behavior stays stable.
  cat >/dev/null 2>&1 || true
  exit 0
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUT="${EOS_TELEMETRY_FILE:-$ROOT/.engineering-os/telemetry/events.jsonl}"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
cat > "$TMP" || true
mkdir -p "$(dirname "$OUT")"

python3 - "$EVENT_NAME" "$OUT" "$TMP" <<'PY'
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

EVENT_NAME = sys.argv[1]
OUT = Path(sys.argv[2])
PAYLOAD = Path(sys.argv[3])

try:
    raw = PAYLOAD.read_text(encoding="utf-8", errors="replace")
except Exception:
    raw = ""

try:
    data = json.loads(raw) if raw.strip() else {}
except Exception:
    data = {}

if not isinstance(data, dict):
    data = {}

tool_name = str(data.get("tool_name") or data.get("tool") or "unknown")
tool_input = data.get("tool_input") if isinstance(data.get("tool_input"), dict) else {}
if not tool_input:
    tool_input = data.get("tool_input", {}) if isinstance(data.get("tool_input"), dict) else {}


def git_value(args):
    try:
        return subprocess.check_output(["git", *args], stderr=subprocess.DEVNULL, text=True).strip()
    except Exception:
        return "unknown"


def sha_text(value: str) -> str:
    if not value:
        return ""
    return hashlib.sha256(value.encode("utf-8", errors="ignore")).hexdigest()[:16]


def command_category(command: str) -> str:
    c = (command or "").lower()
    if not c:
        return "none"
    rules = [
        ("git", ["git "]),
        ("dependency-install", ["npm install", "yarn add", "pnpm add", "pip install", "uv add"]),
        ("test", ["npm test", "pytest", "vitest", "jest", "playwright", "maestro", "go test", "cargo test"]),
        ("build", ["npm run build", "next build", "vite build", "tsc", "cargo build"]),
        ("server-run", ["npm start", "npm run dev", "next dev", "uvicorn", "flask", "node "]),
        ("search", ["grep", "rg ", "ripgrep", "find ", "fd "]),
        ("database", ["prisma", "migrate", "supabase", "psql", "sql"]),
        ("cloud-deploy", ["vercel", "netlify", "flyctl", "gh workflow", "github actions"]),
    ]
    for name, needles in rules:
        if any(n in c for n in needles):
            return name
    return "other"


def path_meta(path_value: str) -> dict:
    p = str(path_value or "").replace("\\", "/")
    if not p:
        return {"present": False}
    parts = [x for x in p.split("/") if x]
    suffix = Path(p).suffix.lower()[:16]
    top = parts[0] if parts else ""
    if top.startswith("."):
        top = top[:32]
    else:
        top = re.sub(r"[^a-zA-Z0-9_.-]", "_", top)[:32]
    return {
        "present": True,
        "top_dir": top,
        "extension": suffix,
        "path_hash": sha_text(p),
    }


command = str(tool_input.get("command") or "") if isinstance(tool_input, dict) else ""
file_path = ""
if isinstance(tool_input, dict):
    file_path = str(tool_input.get("file_path") or tool_input.get("path") or tool_input.get("pattern") or "")

active_plan = os.environ.get("EOS_ACTIVE_PLAN", "")
if not active_plan:
    active = Path(".claude/plans/active.md")
    if active.exists():
        active_plan = str(active)

record = {
    "schema_version": 1,
    "timestamp_unix": int(time.time()),
    "event_name": EVENT_NAME,
    "tool_name": tool_name,
    "command_category": command_category(command),
    "command_hash": sha_text(command) if command else "",
    "target_path": path_meta(file_path),
    "repo_name": Path.cwd().name,
    "git_branch": git_value(["rev-parse", "--abbrev-ref", "HEAD"]),
    "git_head": git_value(["rev-parse", "--short", "HEAD"]),
    "active_plan": Path(active_plan).name if active_plan else "",
    "eos_context": {
        "telemetry_file": str(OUT),
        "engineering_os_home_set": bool(os.environ.get("ENGINEERING_OS_HOME")),
    },
}

# Explicitly do not include raw payload. A small hash helps correlate duplicate hook
# events without exposing command text, file names, prompts, or connector payloads.
record["payload_hash"] = sha_text(raw) if raw else ""

OUT.parent.mkdir(parents=True, exist_ok=True)
with OUT.open("a", encoding="utf-8") as fh:
    fh.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")
PY
