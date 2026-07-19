#!/usr/bin/env bash
set -euo pipefail

# Privacy-safe local telemetry recorder for Engineering OS hook events.
# Metadata-only by default: no prompts, file contents, raw commands, raw paths,
# connector payloads, model responses, environment values, or sensitive values are
# written to the event log. Correlation identifiers are stored as short hashes only.

EVENT_NAME="${1:-unknown}"

if [ "${EOS_TELEMETRY_DISABLED:-0}" = "1" ]; then
  cat >/dev/null 2>&1 || true
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
tool_response = data.get("tool_response")
tool_error = data.get("tool_error") if data.get("tool_error") is not None else data.get("error")


def git_value(args: list[str]) -> str:
    try:
        return subprocess.check_output(["git", *args], stderr=subprocess.DEVNULL, text=True).strip()
    except Exception:
        return "unknown"


def sha_text(value: str, size: int = 16) -> str:
    if not value:
        return ""
    return hashlib.sha256(value.encode("utf-8", errors="ignore")).hexdigest()[:size]


def safe_token(value: str, limit: int = 64) -> str:
    value = re.sub(r"[^a-zA-Z0-9_.:/@-]", "_", str(value or ""))
    return value[:limit]


def length_bucket(value: str) -> str:
    if not value:
        return "none"
    n = len(value)
    for upper in (32, 128, 512, 2048, 8192):
        if n <= upper:
            return f"1-{upper}"
    return "8193+"


def ensure_trace_id() -> str:
    # A SessionStart wrapper writes a fresh per-session run id. Prefer that file
    # over a process-level EOS_TELEMETRY_RUN_ID seed, otherwise every session in
    # the same environment would collapse into one trace.
    if RUN_ID_FILE.exists():
        value = RUN_ID_FILE.read_text(encoding="utf-8", errors="replace").strip()
        if value:
            return value
    env_run_id = os.environ.get("EOS_TELEMETRY_RUN_ID", "").strip()
    if env_run_id:
        value = sha_text(env_run_id, 32)
    else:
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
    return {"present": True, "top_dir": top, "extension": suffix, "path_hash": sha_text(p)}


def active_plan_name() -> str:
    active_plan = os.environ.get("EOS_ACTIVE_PLAN", "")
    if not active_plan:
        active = Path(".claude/plans/active.md")
        if active.exists():
            active_plan = str(active)
    return Path(active_plan).name if active_plan else ""


def common_hook_attributes() -> dict[str, Any]:
    session_id = str(data.get("session_id") or "")
    prompt_id = str(data.get("prompt_id") or "")
    transcript_path = str(data.get("transcript_path") or "")
    cwd = str(data.get("cwd") or "")
    prompt = str(data.get("prompt") or "") if "prompt" in data else ""
    effort = data.get("effort") if isinstance(data.get("effort"), dict) else {}
    agent_id = str(data.get("agent_id") or "")
    instruction_path = str(data.get("file_path") or data.get("trigger_file_path") or "")
    task_id = str(data.get("task_id") or "")
    task_subject = str(data.get("subject") or "")
    return {
        "eos.claude.hook_event_name": safe_token(data.get("hook_event_name") or EVENT_NAME),
        "eos.claude.session.hash": sha_text(session_id, 32),
        "eos.claude.session.present": bool(session_id),
        "eos.claude.prompt.hash": sha_text(prompt_id, 32),
        "eos.claude.prompt.present": bool(prompt_id),
        "eos.claude.transcript.hash": sha_text(transcript_path, 32),
        "eos.claude.transcript.present": bool(transcript_path),
        "eos.claude.cwd.hash": sha_text(cwd, 32),
        "eos.claude.cwd.present": bool(cwd),
        "eos.claude.permission_mode": safe_token(data.get("permission_mode") or ""),
        "eos.claude.effort.level": safe_token(effort.get("level") or ""),
        "eos.claude.agent_type": safe_token(data.get("agent_type") or ""),
        "eos.claude.agent.hash": sha_text(agent_id, 32),
        "eos.claude.agent.present": bool(agent_id),
        "eos.claude.source": safe_token(data.get("source") or data.get("trigger") or ""),
        "eos.claude.model": safe_token(data.get("model") or ""),
        "eos.claude.instruction.target": path_meta(instruction_path),
        "eos.claude.instruction.memory_type": safe_token(data.get("memory_type") or ""),
        "eos.claude.instruction.load_reason": safe_token(data.get("load_reason") or ""),
        "eos.task.id.hash": sha_text(task_id, 32),
        "eos.task.id.present": bool(task_id),
        "eos.task.subject.hash": sha_text(task_subject),
        "eos.task.subject.length_bucket": length_bucket(task_subject),
        "eos.prompt.present": "prompt" in data,
        "eos.prompt.hash": sha_text(prompt),
        "eos.prompt.length_bucket": length_bucket(prompt),
        "eos.privacy.raw_prompt_stored": False,
    }


def safe_tool_attributes() -> dict[str, Any]:
    command = str(tool_input.get("command") or "") if isinstance(tool_input, dict) else ""
    file_path = ""
    if isinstance(tool_input, dict):
        file_path = str(tool_input.get("file_path") or tool_input.get("path") or tool_input.get("pattern") or "")
    response_text = ""
    if tool_response is not None:
        try:
            response_text = json.dumps(tool_response, ensure_ascii=False, sort_keys=True)
        except Exception:
            response_text = str(tool_response)
    error_text = ""
    if tool_error is not None:
        try:
            error_text = json.dumps(tool_error, ensure_ascii=False, sort_keys=True)
        except Exception:
            error_text = str(tool_error)
    return {
        "eos.tool.name": tool_name,
        "eos.tool.command.category": command_category(command),
        "eos.tool.command.hash": sha_text(command) if command else "",
        "eos.tool.target_path": path_meta(file_path),
        "eos.tool.payload.hash": sha_text(raw) if raw else "",
        "eos.tool.response.present": tool_response is not None,
        "eos.tool.response.type": type(tool_response).__name__ if tool_response is not None else "",
        "eos.tool.response.hash": sha_text(response_text) if response_text else "",
        "eos.tool.error.present": tool_error is not None,
        "eos.tool.error.type": type(tool_error).__name__ if tool_error is not None else "",
        "eos.tool.error.hash": sha_text(error_text) if error_text else "",
    }


def genai_semconv_attributes() -> dict[str, Any]:
    # Additive OpenTelemetry GenAI semantic-convention aliases (experimental,
    # SIG-defined) alongside the existing eos.claude.* fields — not a
    # replacement. Existing consumers (eos-telemetry-summary.py, export/
    # import/sync, archive fixtures) read eos.claude.* unchanged.
    # gen_ai.usage.input_tokens/output_tokens are intentionally omitted: Claude
    # Code hook payloads do not expose per-call token counts, and this recorder
    # never fabricates a field it cannot populate from real hook data.
    tool_event = bool(tool_name and tool_name != "unknown")
    operation = "execute_tool" if tool_event else "invoke_agent"
    return {
        "gen_ai.system": "anthropic",
        "gen_ai.request.model": safe_token(data.get("model") or ""),
        "gen_ai.operation.name": operation,
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
        **common_hook_attributes(),
        **safe_tool_attributes(),
        **genai_semconv_attributes(),
    },
    "events": [{
        "name": f"eos.hook.{EVENT_NAME}",
        "time_unix_nano": now_ns,
        "attributes": {
            "eos.privacy.raw_payload_stored": False,
            "eos.privacy.raw_command_stored": False,
            "eos.privacy.raw_path_stored": False,
            "eos.privacy.raw_response_stored": False,
            "eos.privacy.sensitive_values_stored": False,
        },
    }],
}

OUT.parent.mkdir(parents=True, exist_ok=True)
with OUT.open("a", encoding="utf-8") as fh:
    fh.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")
PY

if [ "$EVENT_NAME" = "stop" ]; then
  SUMMARY="${EOS_TELEMETRY_SUMMARY_FILE:-$ROOT/.engineering-os/telemetry/latest-summary.md}"
  SUMMARY_TOOL="$SCRIPT_DIR/eos-telemetry-summary.py"
  if [ -f "$SUMMARY_TOOL" ] && [ -f "$OUT" ]; then
    python3 "$SUMMARY_TOOL" "$OUT" --output "$SUMMARY" >/dev/null 2>&1 || true
  fi
fi
