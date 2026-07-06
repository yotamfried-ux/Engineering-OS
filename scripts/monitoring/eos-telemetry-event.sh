#!/usr/bin/env bash
set -euo pipefail

# Privacy-safe local telemetry recorder for Engineering OS hook events.
# Industry alignment:
# - OpenTelemetry-style local JSONL with trace/span/event/resource/attributes.
# - Agent observability concepts from OpenAI Agents SDK, Google ADK, and Microsoft Foundry.
# - Metadata-only by default: no prompts, file contents, raw commands, connector payloads,
#   environment values, or secret values.

EVENT_NAME="${1:-unknown}"

if [ "${EOS_TELEMETRY_DISABLED:-0}" = "1" ]; then
  # Always consume stdin so hook behavior stays stable.
  cat >/dev/null 2>&1 || true
  exit 0
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OUT="${EOS_TELEMETRY_FILE:-$ROOT/.engineering-os/telemetry/events.jsonl}"
RUN_ID_FILE="${EOS_TELEMETRY_RUN_ID_FILE:-$ROOT/.engineering-os/telemetry/run_id}"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
cat > "$TMP" || true
mkdir -p "$(dirname "$OUT")"
mkdir -p "$(dirname "$RUN_ID_FILE")"

python3 - "$EVENT_NAME" "$OUT" "$TMP" "$RUN_ID_FILE" <<'PY'
from __future__ import annotations

import hashlib
import json
import os
import re
import secrets
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

EVENT_NAME = sys.argv[1]
OUT = Path(sys.argv[2])
PAYLOAD = Path(sys.argv[3])
RUN_ID_FILE = Path(sys.argv[4])

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


def git_value(args: list[str]) -> str:
    try:
        return subprocess.check_output(["git", *args], stderr=subprocess.DEVNULL, text=True).strip()
    except Exception:
        return "unknown"


def sha_text(value: str, size: int = 16) -> str:
    if not value:
        return ""
    return hashlib.sha256(value.encode("utf-8", errors="ignore")).hexdigest()[:size]


def ensure_trace_id() -> str:
    env_run_id = os.environ.get("EOS_TELEMETRY_RUN_ID", "").strip()
    if env_run_id:
        return sha_text(env_run_id, 32)
    if RUN_ID_FILE.exists():
        value = RUN_ID_FILE.read_text(encoding="utf-8", errors="replace").strip()
        if value:
            return value
    value = secrets.token_hex(16)
    RUN_ID_FILE.write_text(value + "\n", encoding="utf-8")
    return value


def command_category(command: str) -> str:
    c = (command or "").lower()
    if not c:
        return "none"
    rules = [
        ("vcs.git", ["git "]),
        ("dependency.install", ["npm install", "yarn add", "pnpm add", "pip install", "uv add"]),
        ("test", ["npm test", "pytest", "vitest", "jest", "playwright", "maestro", "go test", "cargo test"]),
        ("build", ["npm run build", "next build", "vite build", "tsc", "cargo build"]),
        ("server.run", ["npm start", "npm run dev", "next dev", "uvicorn", "flask", "node "]),
        ("search", ["grep", "rg ", "ripgrep", "find ", "fd "]),
        ("database", ["prisma", "migrate", "supabase", "psql", "sql"]),
        ("cloud.deploy", ["vercel", "netlify", "flyctl", "gh workflow", "github actions"]),
    ]
    for name, needles in rules:
        if any(n in c for n in needles):
            return name
    return "other"


def path_meta(path_value: str) -> dict[str, Any]:
    p = str(path_value or "").replace("\\", "/")
    if not p:
        return {"present": False}
    parts = [x for x in p.split("/") if x]
    suffix = Path(p).suffix.lower()[:16]
    top = parts[0] if parts else ""
    top = re.sub(r"[^a-zA-Z0-9_.-]", "_", top)[:32]
    return {
        "present": True,
        "top_dir": top,
        "extension": suffix,
        "path_hash": sha_text(p),
    }


def active_plan_name() -> str:
    active_plan = os.environ.get("EOS_ACTIVE_PLAN", "")
    if not active_plan:
        active = Path(".claude/plans/active.md")
        if active.exists():
            active_plan = str(active)
    return Path(active_plan).name if active_plan else ""


def safe_tool_attributes() -> dict[str, Any]:
    command = str(tool_input.get("command") or "") if isinstance(tool_input, dict) else ""
    file_path = ""
    if isinstance(tool_input, dict):
        file_path = str(tool_input.get("file_path") or tool_input.get("path") or tool_input.get("pattern") or "")
    return {
        "eos.tool.name": tool_name,
        "eos.tool.command.category": command_category(command),
        "eos.tool.command.hash": sha_text(command) if command else "",
        "eos.tool.target_path": path_meta(file_path),
        "eos.tool.payload.hash": sha_text(raw) if raw else "",
    }


trace_id = ensure_trace_id()
span_id = secrets.token_hex(8)
now_ns = time.time_ns()
now_iso = datetime.now(timezone.utc).isoformat()
repo_root = git_value(["rev-parse", "--show-toplevel"])
repo_name = Path(repo_root).name if repo_root != "unknown" else Path.cwd().name
branch = git_value(["rev-parse", "--abbrev-ref", "HEAD"])
head = git_value(["rev-parse", "--short", "HEAD"])

record = {
    "schema_version": "eos.telemetry.v1",
    "otel_signal": "span_event",
    "trace_id": trace_id,
    "span_id": span_id,
    "parent_span_id": os.environ.get("EOS_TELEMETRY_PARENT_SPAN_ID", ""),
    "name": f"eos.{EVENT_NAME}",
    "kind": "INTERNAL",
    "start_time_unix_nano": now_ns,
    "end_time_unix_nano": now_ns,
    "timestamp": now_iso,
    "status": {"code": "OK"},
    "resource": {
        "service.name": os.environ.get("OTEL_SERVICE_NAME", "engineering-os"),
        "service.namespace": "engineering-os",
        "service.instance.id": sha_text(str(Path.cwd())),
        "deployment.environment.name": os.environ.get("EOS_ENVIRONMENT", "local"),
    },
    "attributes": {
        "eos.event.name": EVENT_NAME,
        "eos.repo.name": repo_name,
        "eos.git.branch": branch,
        "eos.git.head.short": head,
        "eos.plan.active.basename": active_plan_name(),
        "eos.engineering_os_home.set": bool(os.environ.get("ENGINEERING_OS_HOME")),
        **safe_tool_attributes(),
    },
    "events": [
        {
            "name": f"eos.hook.{EVENT_NAME}",
            "time_unix_nano": now_ns,
            "attributes": {
                "eos.privacy.raw_payload_stored": False,
                "eos.privacy.raw_command_stored": False,
                "eos.privacy.raw_path_stored": False,
                "eos.privacy.secret_values_stored": False,
            },
        }
    ],
}

OUT.parent.mkdir(parents=True, exist_ok=True)
with OUT.open("a", encoding="utf-8") as fh:
    fh.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")
PY
