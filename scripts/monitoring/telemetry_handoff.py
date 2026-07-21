#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import os
import re
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

POLICY_SCHEMA = "eos.telemetry.policy.v1"
RUN_SCHEMA = "eos.telemetry.run.v1"
HANDOFF_SCHEMA = "eos.telemetry.handoff.v1"
DEFAULT_REMOTE = "origin"
DEFAULT_BRANCH = "engineering-os-telemetry"
VALID_MODES = {"disabled", "best_effort", "required"}
REPO_SLUG_RE = re.compile(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+")
BOUNDARY_EVENTS = {
    "eos.session_start",
    "eos.stop",
    "eos.stop_failure",
    "eos.session_end",
}
REQUIRED_BUNDLE_FILES = ("manifest.json", "events.jsonl", "latest-summary.md")
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


def validate_repo_slug(value: str) -> str:
    value = str(value or "").strip()
    if not REPO_SLUG_RE.fullmatch(value):
        raise HandoffError(
            "canonical repository identity must be owner/repo; provide --repo, "
            "configure a GitHub origin, or set GITHUB_REPOSITORY"
        )
    return value


def parse_repo_slug_from_remote(value: str) -> str | None:
    raw = str(value or "").strip()
    if not raw:
        return None
    take_last_two = False
    if "://" in raw:
        parsed = urlparse(raw)
        if not parsed.scheme or not parsed.netloc:
            return None
        raw = parsed.path
        take_last_two = True
    elif ":" in raw and not raw.startswith("/"):
        # scp-style shorthand per git-clone(1): [<user>@]<host>:<path-to-git-repo>
        # (e.g. "git@github.com:owner/repo.git" or "github.com:owner/repo.git").
        host, _, path = raw.partition(":")
        if not host or not path:
            return None
        raw = path
        take_last_two = True
    raw = raw.strip().strip("/")
    if raw.endswith(".git"):
        raw = raw[:-4]
    parts = [part for part in raw.split("/") if part]
    if take_last_two:
        if len(parts) < 2:
            return None
        candidate = f"{parts[-2]}/{parts[-1]}"
    else:
        if len(parts) != 2:
            return None
        candidate = f"{parts[0]}/{parts[1]}"
    return candidate if REPO_SLUG_RE.fullmatch(candidate) else None


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
    env_policy = os.environ.get("EOS_TELEMETRY_POLICY_FILE", "").strip()
    path = explicit_path or Path(env_policy or root / ".engineering-os" / "telemetry-policy.json")
    trusted_explicit = explicit_path is not None or bool(env_policy)
    if trusted_explicit and (path.is_symlink() or not path.is_file()):
        raise HandoffError(f"trusted telemetry policy file is missing or not regular: {path}")

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

    allow_env_overrides = not trusted_explicit
    mode = str(
        (os.environ.get("EOS_TELEMETRY_HANDOFF_MODE") if allow_env_overrides else "")
        or remote_cfg.get("mode")
        or "disabled"
    ).strip().lower()
    if mode not in VALID_MODES:
        raise HandoffError(
            f"telemetry remote_handoff.mode must be one of {sorted(VALID_MODES)}"
        )

    remote = str(
        (os.environ.get("EOS_TELEMETRY_HANDOFF_REMOTE") if allow_env_overrides else "")
        or remote_cfg.get("remote")
        or DEFAULT_REMOTE
    ).strip()
    if not re.fullmatch(r"[A-Za-z0-9._-]+", remote):
        raise HandoffError("telemetry remote name is invalid")

    branch = validate_ref_name(
        str(
            (os.environ.get("EOS_TELEMETRY_HANDOFF_BRANCH") if allow_env_overrides else "")
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


def load_json_object(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        raise HandoffError(f"invalid JSON in {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise HandoffError(f"{path} must contain a JSON object")
    return value


def read_text_strict(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError as exc:
        raise HandoffError(f"invalid UTF-8 in {path}: {exc}") from exc


def load_jsonl_strict(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for line_number, raw in enumerate(read_text_strict(path).splitlines(), start=1):
        if not raw.strip():
            continue
        try:
            row = json.loads(raw)
        except Exception as exc:
            raise HandoffError(f"invalid JSONL at {path}:{line_number}: {exc}") from exc
        if not isinstance(row, dict):
            raise HandoffError(f"telemetry event must be an object at {path}:{line_number}")
        rows.append(row)
    return rows


def validate_bundle(
    bundle: Path,
    *,
    expected_repo: str = "",
    expected_branch_hash: str = "",
    expected_head_sha: str = "",
    expected_run_id: str = "",
) -> dict[str, Any]:
    required_paths = {name: bundle / name for name in REQUIRED_BUNDLE_FILES}
    for name, path in required_paths.items():
        if path.is_symlink() or not path.is_file():
            raise HandoffError(
                f"telemetry bundle required file is missing or not regular: {name}: {bundle}"
            )
    manifest_path = required_paths["manifest.json"]
    events_path = required_paths["events.jsonl"]
    summary_path = required_paths["latest-summary.md"]

    manifest = load_json_object(manifest_path)
    if manifest.get("schema_version") != RUN_SCHEMA:
        raise HandoffError(f"unsupported telemetry manifest schema in {bundle}")
    if manifest.get("privacy_contract") != "metadata-only":
        raise HandoffError(f"telemetry bundle privacy contract is not metadata-only: {bundle}")

    handoff = manifest.get("handoff")
    if not isinstance(handoff, dict) or handoff.get("schema_version") != HANDOFF_SCHEMA:
        raise HandoffError(f"telemetry bundle has no valid handoff metadata: {bundle}")

    manifest_repo = validate_repo_slug(str(manifest.get("repo") or ""))
    handoff_repo = validate_repo_slug(str(handoff.get("repo") or ""))
    if manifest_repo != handoff_repo:
        raise HandoffError(f"telemetry bundle repository identity is inconsistent: {bundle}")

    manifest_head = str(manifest.get("head_sha") or "")
    handoff_head = str(handoff.get("head_sha") or "")
    if not re.fullmatch(r"[0-9a-f]{40}", manifest_head) or manifest_head != handoff_head:
        raise HandoffError(f"telemetry bundle head identity is invalid: {bundle}")

    branch_hash = str(handoff.get("source_branch_hash") or "")
    if not re.fullmatch(r"[0-9a-f]{32}", branch_hash):
        raise HandoffError(f"telemetry bundle branch hash is invalid: {bundle}")

    pr_number = int(handoff.get("pr_number") or 0)
    binding = str(handoff.get("pr_binding") or ("exact" if pr_number > 0 else "provisional"))
    if binding not in {"exact", "provisional"} or (binding == "exact") != (pr_number > 0):
        raise HandoffError(f"telemetry handoff PR binding is invalid: {bundle}")
    handoff["pr_binding"] = binding
    manifest["handoff"] = handoff

    checksums = manifest.get("checksums") if isinstance(manifest.get("checksums"), dict) else {}
    if checksums.get("events_sha256") != file_digest(events_path):
        raise HandoffError(f"telemetry events checksum mismatch: {bundle}")
    if checksums.get("summary_sha256") != file_digest(summary_path):
        raise HandoffError(f"telemetry summary checksum mismatch: {bundle}")

    rows = load_jsonl_strict(events_path)
    if len(rows) != int(manifest.get("event_count") or -1):
        raise HandoffError(f"telemetry event_count mismatch: {bundle}")
    if not rows:
        raise HandoffError(f"zero-event telemetry bundle is not valid for a required experiment: {bundle}")

    run_id = str(manifest.get("run_id") or "")
    if not run_id or any(str(row.get("trace_id") or "") != run_id for row in rows):
        raise HandoffError(f"telemetry bundle run correlation is invalid: {bundle}")
    if str(handoff.get("run_id_hash") or "") != stable_hash(run_id):
        raise HandoffError(f"telemetry bundle run hash is invalid: {bundle}")
    if int(handoff.get("event_count") or -1) != len(rows):
        raise HandoffError(f"telemetry handoff event count mismatch: {bundle}")
    boundary = int(handoff.get("boundary_position") or 0)
    recomputed_boundary = latest_boundary_position(rows)
    if boundary <= 0 or boundary > len(rows) or boundary != recomputed_boundary:
        raise HandoffError(f"telemetry handoff boundary position is invalid: {bundle}")

    validate_metadata_only(manifest)
    validate_metadata_only(rows)
    validate_metadata_only({"summary_text": read_text_strict(summary_path)})

    if expected_repo and manifest_repo != validate_repo_slug(expected_repo):
        raise HandoffError(f"telemetry bundle repository does not match current repository: {bundle}")
    if expected_branch_hash and branch_hash != expected_branch_hash:
        raise HandoffError(f"telemetry bundle branch hash does not match current branch: {bundle}")
    if expected_head_sha and manifest_head != expected_head_sha:
        raise HandoffError(f"telemetry bundle head does not match current head: {bundle}")
    if expected_run_id and run_id != expected_run_id:
        raise HandoffError(f"telemetry bundle run id does not match current run: {bundle}")
    return manifest


def atomic_write_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=path.parent,
            prefix=f".{path.name}.",
            suffix=".tmp",
            delete=False,
        ) as tmp:
            json.dump(value, tmp, ensure_ascii=False, indent=2, sort_keys=True)
            tmp.write("\n")
            temp_path = Path(tmp.name)
        temp_path.replace(path)
    finally:
        if temp_path is not None and temp_path.exists():
            temp_path.unlink()
