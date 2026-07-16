#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

POLICY_SCHEMA = "eos.telemetry.policy.v1"
HANDOFF_SCHEMA = "eos.telemetry.handoff.v1"
DEFAULT_REMOTE = "origin"
DEFAULT_BRANCH = "engineering-os-telemetry"
VALID_MODES = {"disabled", "best_effort", "required"}
BOUNDARY_EVENTS = {
    "eos.session_start",
    "eos.stop",
    "eos.stop_failure",
    "eos.session_end",
}
BANNED_KEYS = {
    "prompt", "user_prompt", "model_text", "user_text", "raw_model_text",
    "raw_user_text", "command", "raw_command", "raw_shell_command", "file_path",
    "raw_file_path", "path", "transcript_path", "private_transcript_path",
    "content", "contents", "file_contents", "raw_connector_payload",
    "connector_payload", "tool_input", "tool_response", "raw_tool_response",
    "environment", "env", "environment_values", "credential", "credentials",
    "secret", "secrets", "api_key", "access_token", "refresh_token", "password",
}
BANNED_PATTERNS = [
    re.compile("-" * 5 + r"BEGIN [A-Z ]*" + "PRIVATE KEY" + "-" * 5),
    re.compile(r"\bgh[pousr]_[A-Za-z0-9_]{20,}\b"),
    re.compile(r"\bsk-[A-Za-z0-9][A-Za-z0-9_-]{16,}\b"),
    re.compile("VALUE_SHOULD_NOT_APPEAR"),
]


class HandoffError(ValueError):
    pass


def stable_hash(value: str, size: int = 32) -> str:
    return hashlib.sha256(str(value or "").encode("utf-8", errors="replace")).hexdigest()[:size]


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def repo_root(start: Path | None = None) -> Path:
    import subprocess

    cwd = start or Path.cwd()
    try:
        out = subprocess.check_output(
            ["git", "-C", str(cwd), "rev-parse", "--show-toplevel"],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
        return Path(out)
    except Exception:
        return cwd.resolve()


def validate_ref_name(value: str) -> str:
    value = str(value or "").strip()
    if (
        not value
        or value.startswith(("/", "."))
        or value.endswith(("/", ".", ".lock"))
        or ".." in value
        or "@{" in value
        or "\\" in value
        or any(ch.isspace() for ch in value)
        or not re.fullmatch(r"[A-Za-z0-9._/-]+", value)
    ):
        raise HandoffError("remote telemetry branch name is invalid")
    return value


def load_policy(root: Path, explicit_path: Path | None = None) -> dict[str, Any]:
    path = explicit_path or Path(
        os.environ.get(
            "EOS_TELEMETRY_POLICY_FILE",
            str(root / ".engineering-os" / "telemetry-policy.json"),
        )
    )
    raw: dict[str, Any] = {}
    if path.is_file():
        try:
            loaded = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise HandoffError(f"invalid telemetry policy JSON: {exc}") from exc
        if not isinstance(loaded, dict):
            raise HandoffError("telemetry policy root must be an object")
        raw = loaded
        schema = str(raw.get("schema_version") or "")
        if schema and schema != POLICY_SCHEMA:
            raise HandoffError(f"telemetry policy schema_version must be {POLICY_SCHEMA}")

    remote_cfg = raw.get("remote_handoff")
    if not isinstance(remote_cfg, dict):
        remote_cfg = {}

    mode = str(
        os.environ.get("EOS_TELEMETRY_HANDOFF_MODE")
        or remote_cfg.get("mode")
        or "disabled"
    ).strip().lower()
    if mode not in VALID_MODES:
        raise HandoffError(
            f"telemetry remote_handoff.mode must be one of {sorted(VALID_MODES)}"
        )

    remote = str(
        os.environ.get("EOS_TELEMETRY_HANDOFF_REMOTE")
        or remote_cfg.get("remote")
        or DEFAULT_REMOTE
    ).strip()
    if not re.fullmatch(r"[A-Za-z0-9._-]+", remote):
        raise HandoffError("telemetry remote name is invalid")

    branch = validate_ref_name(
        str(
            os.environ.get("EOS_TELEMETRY_HANDOFF_BRANCH")
            or remote_cfg.get("branch")
            or DEFAULT_BRANCH
        )
    )
    return {
        "schema_version": POLICY_SCHEMA,
        "mode": mode,
        "remote": remote,
        "branch": branch,
        "policy_path": str(path),
    }


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    if not path.is_file():
        return rows
    for raw in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if not raw.strip():
            continue
        try:
            item = json.loads(raw)
        except Exception:
            continue
        if isinstance(item, dict):
            rows.append(item)
    return rows


def read_run_id(path: Path) -> str:
    if not path.is_file():
        return ""
    value = path.read_text(encoding="utf-8", errors="replace").splitlines()
    return re.sub(r"[^a-zA-Z0-9_.:-]", "", value[0].strip()) if value else ""


def latest_boundary_position(events: list[dict[str, Any]]) -> int:
    latest = 0
    for index, event in enumerate(events, start=1):
        name = str(event.get("name") or "")
        attrs = event.get("attributes") if isinstance(event.get("attributes"), dict) else {}
        attr_name = str(attrs.get("eos.event.name") or "")
        canonical = name if name.startswith("eos.") else f"eos.{attr_name}"
        if canonical in BOUNDARY_EVENTS:
            latest = index
    return latest


def iter_paths(value: Any, prefix: str = ""):
    if isinstance(value, dict):
        for key, child in value.items():
            path = f"{prefix}.{key}" if prefix else str(key)
            yield path, child
            yield from iter_paths(child, path)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            path = f"{prefix}[{index}]"
            yield path, child
            yield from iter_paths(child, path)


def validate_metadata_only(value: Any) -> None:
    for path, child in iter_paths(value):
        key = re.sub(r"\[\d+\]", "", path.split(".")[-1]).lower().replace("-", "_")
        if key in BANNED_KEYS or (key.startswith("raw_") and not key.endswith("_stored")):
            raise HandoffError(f"banned raw field present: {path}")
        if isinstance(child, str) and any(pattern.search(child) for pattern in BANNED_PATTERNS):
            raise HandoffError(f"banned sensitive value pattern present at: {path}")


def count_nonempty_lines(path: Path) -> int:
    if not path.is_file():
        return 0
    return sum(1 for line in path.read_text(encoding="utf-8", errors="replace").splitlines() if line.strip())


def file_digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def atomic_write_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    tmp.replace(path)
