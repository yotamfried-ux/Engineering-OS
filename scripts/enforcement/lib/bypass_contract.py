#!/usr/bin/env python3
"""Canonical contracts for provider-verified Engineering OS bypass approvals."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
import csv
import hashlib
import json
from pathlib import Path
import re
from typing import Any, Iterable, Mapping

APPROVAL_SCHEMA = "eos-bypass-approval/v1"
CLAIM_SCHEMA = "eos-bypass-consumption/v1"
MARKER_SCHEMA = "eos-bypass-marker/v1"
CONTROL_SCHEMA = "eos-bypass-control-plane/v1"
GITHUB_ACTIONS_BOT_ID = 41898282
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
LOGIN_RE = re.compile(r"^[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})$")
ENV_RE = re.compile(r"^EOS_BYPASS_[A-Z0-9_]+$")
ALLOWED_CLASSIFICATIONS = {"master-disabled", "action-specific"}
ALLOWED_ROLES = {"maintain", "admin"}
MAX_APPROVAL_LIFETIME = timedelta(hours=4)
GENERIC_REASONS = {"approved", "ok", "okay", "bypass", "needed", "test", "temporary"}

APPROVAL_FIELDS = (
    "schema", "protected_repository", "protected_repository_id",
    "control_repository", "control_repository_id", "approval_issue_id",
    "approval_comment_id", "approval_created_at", "issuer_login",
    "issuer_user_id", "issuer_type", "issuer_role", "reason", "expires_at",
    "gate", "bypass", "action", "surface", "target", "target_fingerprint",
    "target_commit", "nonce", "policy_sha256", "consumer_workflow_id",
    "consumer_workflow_path", "finalizer_workflow_id", "finalizer_workflow_path",
    "control_default_branch_sha",
)

PROVIDER_BOUND_APPROVAL_FIELDS = ("approval_comment_id", "approval_created_at")
AUTHORED_APPROVAL_FIELDS = tuple(
    field for field in APPROVAL_FIELDS if field not in PROVIDER_BOUND_APPROVAL_FIELDS
)

CLAIM_FIELDS = (
    "schema", "approval_digest", "protected_repository", "protected_repository_id",
    "control_repository", "control_repository_id", "approval_issue_id",
    "approval_comment_id", "consumption_issue_id", "gate", "bypass", "action",
    "surface", "target", "target_fingerprint", "target_commit", "nonce",
    "policy_sha256", "consumer_workflow_id", "consumer_workflow_path",
    "consumer_default_branch_sha", "run_id", "run_attempt", "actor",
    "triggering_actor", "event",
)

MARKER_FIELDS = (
    "schema", "approval_digest", "claim_digest", "claim_comment_id",
    "claim_created_at", "protected_repository", "protected_repository_id",
    "control_repository", "control_repository_id", "approval_issue_id",
    "approval_comment_id", "consumption_issue_id", "gate", "bypass", "action",
    "surface", "target", "target_fingerprint", "target_commit", "nonce",
    "policy_sha256", "consumer_workflow_id", "consumer_workflow_path",
    "consumer_default_branch_sha", "consumer_run_id", "finalizer_workflow_id",
    "finalizer_workflow_path", "finalizer_default_branch_sha", "finalizer_run_id",
    "finalizer_run_attempt", "finalizer_actor", "finalizer_triggering_actor",
    "finalizer_event",
)


class ContractError(ValueError):
    """Contract or provider evidence is malformed or does not match."""


@dataclass(frozen=True)
class PolicyEntry:
    bypass: str
    gate: str
    action: str
    surface: str
    target_type: str
    fingerprint_contract: str
    target_commit_contract: str
    classification: str

    @property
    def is_master(self) -> bool:
        return self.classification == "master-disabled"


def canonical_json(value: Any) -> bytes:
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")


def digest_json(value: Any) -> str:
    return hashlib.sha256(canonical_json(value)).hexdigest()


def require_object(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ContractError(f"{label} must be one JSON object")
    return value


def require_exact_fields(value: Mapping[str, Any], fields: Iterable[str], label: str) -> None:
    expected, actual = set(fields), set(value)
    missing, extra = sorted(expected - actual), sorted(actual - expected)
    if missing or extra:
        raise ContractError(f"{label} fields mismatch: missing={missing}, extra={extra}")


def nonempty_string(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ContractError(f"{label} must be a non-empty string")
    return value.strip()


def positive_int(value: Any, label: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        raise ContractError(f"{label} must be a positive integer")
    return value


def parse_timestamp(value: Any, label: str) -> datetime:
    text = nonempty_string(value, label)
    if not text.endswith("Z"):
        raise ContractError(f"{label} must use UTC Z form")
    try:
        parsed = datetime.fromisoformat(text[:-1] + "+00:00")
    except ValueError as exc:
        raise ContractError(f"{label} is not an RFC3339 timestamp") from exc
    if parsed.utcoffset() != timezone.utc.utcoffset(parsed):
        raise ContractError(f"{label} must be UTC")
    return parsed


def format_timestamp(value: datetime) -> str:
    return value.astimezone(timezone.utc).replace(microsecond=0).strftime("%Y-%m-%dT%H:%M:%SZ")


def validate_sha(value: Any, label: str) -> str:
    text = nonempty_string(value, label)
    if not SHA_RE.fullmatch(text) or text == "0" * 40:
        raise ContractError(f"{label} must be a non-zero lowercase 40-character commit SHA")
    return text


def validate_digest(value: Any, label: str) -> str:
    text = nonempty_string(value, label)
    if not SHA256_RE.fullmatch(text):
        raise ContractError(f"{label} must be a lowercase SHA-256 digest")
    return text


def load_json(path: Path) -> dict[str, Any]:
    try:
        return require_object(json.loads(path.read_text(encoding="utf-8")), str(path))
    except (OSError, json.JSONDecodeError) as exc:
        raise ContractError(f"cannot load {path}: {exc}") from exc


def load_policy(path: Path) -> dict[str, PolicyEntry]:
    expected = [
        "bypass", "gate", "action", "surface", "target_type",
        "fingerprint_contract", "target_commit_contract", "classification",
    ]
    try:
        with path.open(encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle, delimiter="\t")
            if reader.fieldnames != expected:
                raise ContractError(f"{path} header mismatch: {reader.fieldnames!r}")
            entries: dict[str, PolicyEntry] = {}
            for line_no, raw in enumerate(reader, 2):
                if not all(isinstance(raw.get(name), str) and raw[name].strip() for name in expected):
                    raise ContractError(f"{path}:{line_no}: blank policy field")
                entry = PolicyEntry(**{name: raw[name].strip() for name in expected})
                if not ENV_RE.fullmatch(entry.bypass):
                    raise ContractError(f"{path}:{line_no}: invalid bypass name {entry.bypass!r}")
                if entry.classification not in ALLOWED_CLASSIFICATIONS:
                    raise ContractError(f"{path}:{line_no}: invalid classification {entry.classification!r}")
                if entry.bypass in entries:
                    raise ContractError(f"{path}:{line_no}: duplicate bypass {entry.bypass}")
                entries[entry.bypass] = entry
    except OSError as exc:
        raise ContractError(f"cannot load {path}: {exc}") from exc
    if not entries:
        raise ContractError(f"{path} has no policy entries")
    return entries


def _validate_workflow(value: Any, label: str, *, qualified: bool) -> dict[str, Any]:
    obj = require_object(value, label)
    expected = {"workflow_id", "workflow_path", "reusable_workflow_path", "writer_login", "writer_user_id"}
    if set(obj) != expected:
        raise ContractError(f"{label} fields mismatch")
    if qualified:
        positive_int(obj["workflow_id"], f"{label}.workflow_id")
    elif not isinstance(obj["workflow_id"], int) or obj["workflow_id"] < 0:
        raise ContractError(f"{label}.workflow_id must be a non-negative integer")
    for key in ("workflow_path", "reusable_workflow_path"):
        path = nonempty_string(obj[key], f"{label}.{key}")
        if not path.startswith(".github/workflows/") or ".." in Path(path).parts:
            raise ContractError(f"{label}.{key} is not a pinned workflow path")
    if obj["writer_login"] != "github-actions[bot]" or obj["writer_user_id"] != GITHUB_ACTIONS_BOT_ID:
        raise ContractError(f"{label} writer identity must be the pinned GitHub Actions bot")
    return obj


def validate_control_config(config: Mapping[str, Any], *, require_qualified: bool = True) -> None:
    required = {
        "schema", "qualification", "protected_repository", "control_repository",
        "issues", "consumer", "finalizer", "provider", "contracts", "forbidden",
    }
    if set(config) != required:
        raise ContractError("control-plane top-level fields mismatch")
    if config["schema"] != CONTROL_SCHEMA:
        raise ContractError("unsupported control-plane schema")
    qualification = require_object(config["qualification"], "qualification")
    if set(qualification) != {"status", "live_control_repository_qualification"}:
        raise ContractError("qualification fields mismatch")
    qualified = qualification == {"status": "qualified", "live_control_repository_qualification": True}
    if require_qualified and not qualified:
        raise ContractError("control plane is not live-qualified")

    protected = require_object(config["protected_repository"], "protected_repository")
    if set(protected) != {"full_name", "id"}:
        raise ContractError("protected_repository fields mismatch")
    nonempty_string(protected["full_name"], "protected_repository.full_name")
    positive_int(protected["id"], "protected_repository.id")

    control = require_object(config["control_repository"], "control_repository")
    if set(control) != {"full_name", "id", "private_required", "default_branch", "trusted_default_branch_sha"}:
        raise ContractError("control_repository fields mismatch")
    if control["private_required"] is not True:
        raise ContractError("control repository must be private")
    nonempty_string(control["default_branch"], "control_repository.default_branch")
    trusted_sha = control["trusted_default_branch_sha"]
    if qualified:
        nonempty_string(control["full_name"], "control_repository.full_name")
        positive_int(control["id"], "control_repository.id")
        validate_sha(trusted_sha, "control_repository.trusted_default_branch_sha")
    else:
        if not isinstance(control["full_name"], str) or not isinstance(control["id"], int) or control["id"] < 0:
            raise ContractError("unqualified control repository placeholders are invalid")
        if not isinstance(trusted_sha, str):
            raise ContractError("unqualified trusted default-branch SHA placeholder is invalid")
        if trusted_sha:
            validate_sha(trusted_sha, "control_repository.trusted_default_branch_sha")

    issues = require_object(config["issues"], "issues")
    if set(issues) != {"approval", "consumption"}:
        raise ContractError("issues fields mismatch")
    for name in ("approval", "consumption"):
        if qualified:
            positive_int(issues[name], f"issues.{name}")
        elif not isinstance(issues[name], int) or issues[name] < 0:
            raise ContractError(f"issues.{name} must be a non-negative integer")
    if qualified and issues["approval"] == issues["consumption"]:
        raise ContractError("approval and consumption issues must be separate")

    _validate_workflow(config["consumer"], "consumer", qualified=qualified)
    _validate_workflow(config["finalizer"], "finalizer", qualified=qualified)

    provider = require_object(config["provider"], "provider")
    if provider != {
        "api_base": "https://api.github.com",
        "canonical_time_field": "created_at",
        "accepted_issuer_roles": ["maintain", "admin"],
        "fail_closed": True,
    }:
        raise ContractError("provider fail-closed/time/permission contract mismatch")

    contracts = require_object(config["contracts"], "contracts")
    if contracts != {
        "approval_schema": APPROVAL_SCHEMA,
        "claim_schema": CLAIM_SCHEMA,
        "marker_schema": MARKER_SCHEMA,
        "digest": "sha256-canonical-json",
        "run_attempt": 1,
        "claim_uniqueness": "exactly-one",
        "marker_uniqueness": "exactly-one",
    }:
        raise ContractError("contracts mismatch")

    forbidden = require_object(config["forbidden"], "forbidden")
    if forbidden != {
        "environment_path_overrides": True,
        "git_tag_consumption": True,
        "master_authorization": True,
        "runtime_marker_write": True,
    }:
        raise ContractError("forbidden controls mismatch")


def _validate_common_binding(value: Mapping[str, Any], policy: Mapping[str, PolicyEntry]) -> PolicyEntry:
    bypass = nonempty_string(value["bypass"], "bypass")
    entry = policy.get(bypass)
    if entry is None:
        raise ContractError("bypass is not present in canonical policy")
    if entry.is_master:
        raise ContractError("master bypass requests are disabled authorization surfaces")
    for field in ("gate", "action", "surface"):
        if value[field] != getattr(entry, field):
            raise ContractError(f"{field} does not match canonical policy")
    target = nonempty_string(value["target"], "target")
    if target != entry.target_type and not target.startswith(f"{entry.target_type}:"):
        raise ContractError("target does not match the canonical policy target_type")
    if not entry.fingerprint_contract.startswith("sha256:") or entry.fingerprint_contract == "sha256:":
        raise ContractError("canonical policy declares an unsupported fingerprint_contract")
    if entry.target_commit_contract != "exact-protected-head":
        raise ContractError("canonical policy declares an unsupported target_commit_contract")
    validate_digest(value["target_fingerprint"], "target_fingerprint")
    validate_sha(value["target_commit"], "target_commit")
    nonce = nonempty_string(value["nonce"], "nonce")
    if len(nonce) < 32 or len(nonce) > 128:
        raise ContractError("nonce length must be between 32 and 128 characters")
    validate_digest(value["policy_sha256"], "policy_sha256")
    return entry


def bind_provider_approval(
    authored: Mapping[str, Any], comment_id: Any, created_at: Any
) -> dict[str, Any]:
    positive_int(comment_id, "approval_comment_id")
    parse_timestamp(created_at, "approval_created_at")
    bound = dict(authored)
    bound["approval_comment_id"] = comment_id
    bound["approval_created_at"] = created_at
    return bound


def validate_approval_shape(
    value: Mapping[str, Any], policy: Mapping[str, PolicyEntry], *, authored: bool = False
) -> None:
    require_exact_fields(
        value,
        AUTHORED_APPROVAL_FIELDS if authored else APPROVAL_FIELDS,
        "authored approval" if authored else "approval",
    )
    if value["schema"] != APPROVAL_SCHEMA:
        raise ContractError("unsupported approval schema")
    positive_int(value["protected_repository_id"], "protected_repository_id")
    positive_int(value["control_repository_id"], "control_repository_id")
    positive_int(value["approval_issue_id"], "approval_issue_id")
    if not authored:
        positive_int(value["approval_comment_id"], "approval_comment_id")
    positive_int(value["issuer_user_id"], "issuer_user_id")
    positive_int(value["consumer_workflow_id"], "consumer_workflow_id")
    positive_int(value["finalizer_workflow_id"], "finalizer_workflow_id")
    for field in ("protected_repository", "control_repository", "consumer_workflow_path", "finalizer_workflow_path"):
        nonempty_string(value[field], field)
    login = nonempty_string(value["issuer_login"], "issuer_login")
    if not LOGIN_RE.fullmatch(login):
        raise ContractError("issuer_login is invalid")
    if value["issuer_type"] != "User":
        raise ContractError("approval issuer must be a human User")
    if value["issuer_role"] not in ALLOWED_ROLES:
        raise ContractError("approval issuer role must be maintain or admin")
    reason = nonempty_string(value["reason"], "reason")
    if len(reason) < 20 or reason.casefold() in GENERIC_REASONS:
        raise ContractError("approval reason is blank, generic, or too short")
    expires = parse_timestamp(value["expires_at"], "expires_at")
    if not authored:
        created = parse_timestamp(value["approval_created_at"], "approval_created_at")
        if expires <= created or expires - created > MAX_APPROVAL_LIFETIME:
            raise ContractError("approval expiry must be after provider created_at and within four hours")
    validate_sha(value["control_default_branch_sha"], "control_default_branch_sha")
    _validate_common_binding(value, policy)


def validate_claim_shape(value: Mapping[str, Any], policy: Mapping[str, PolicyEntry]) -> None:
    require_exact_fields(value, CLAIM_FIELDS, "claim")
    if value["schema"] != CLAIM_SCHEMA:
        raise ContractError("unsupported claim schema")
    validate_digest(value["approval_digest"], "approval_digest")
    for field in ("protected_repository_id", "control_repository_id", "approval_issue_id", "approval_comment_id", "consumption_issue_id", "consumer_workflow_id", "run_id"):
        positive_int(value[field], field)
    validate_sha(value["consumer_default_branch_sha"], "consumer_default_branch_sha")
    if value["run_attempt"] != 1:
        raise ContractError("claim run_attempt must equal 1")
    if value["event"] != "deployment":
        raise ContractError("claim event must be deployment")
    for field in ("actor", "triggering_actor", "consumer_workflow_path"):
        nonempty_string(value[field], field)
    _validate_common_binding(value, policy)


def validate_marker_shape(value: Mapping[str, Any], policy: Mapping[str, PolicyEntry]) -> None:
    require_exact_fields(value, MARKER_FIELDS, "marker")
    if value["schema"] != MARKER_SCHEMA:
        raise ContractError("unsupported marker schema")
    for field in ("approval_digest", "claim_digest"):
        validate_digest(value[field], field)
    for field in (
        "claim_comment_id", "protected_repository_id", "control_repository_id",
        "approval_issue_id", "approval_comment_id", "consumption_issue_id",
        "consumer_workflow_id", "consumer_run_id", "finalizer_workflow_id",
        "finalizer_run_id",
    ):
        positive_int(value[field], field)
    parse_timestamp(value["claim_created_at"], "claim_created_at")
    validate_sha(value["consumer_default_branch_sha"], "consumer_default_branch_sha")
    validate_sha(value["finalizer_default_branch_sha"], "finalizer_default_branch_sha")
    if value["finalizer_run_attempt"] != 1:
        raise ContractError("finalizer run_attempt must equal 1")
    if value["finalizer_event"] != "workflow_run":
        raise ContractError("finalizer event must be workflow_run")
    for field in (
        "consumer_workflow_path", "finalizer_workflow_path", "finalizer_actor",
        "finalizer_triggering_actor",
    ):
        nonempty_string(value[field], field)
    _validate_common_binding(value, policy)


def claim_from_approval(
    approval: Mapping[str, Any], *, consumption_issue_id: int,
    consumer_default_branch_sha: str, run_id: int, run_attempt: int,
    actor: str, triggering_actor: str, event: str,
) -> dict[str, Any]:
    return {
        "schema": CLAIM_SCHEMA,
        "approval_digest": digest_json(dict(approval)),
        "protected_repository": approval["protected_repository"],
        "protected_repository_id": approval["protected_repository_id"],
        "control_repository": approval["control_repository"],
        "control_repository_id": approval["control_repository_id"],
        "approval_issue_id": approval["approval_issue_id"],
        "approval_comment_id": approval["approval_comment_id"],
        "consumption_issue_id": consumption_issue_id,
        "gate": approval["gate"], "bypass": approval["bypass"],
        "action": approval["action"], "surface": approval["surface"],
        "target": approval["target"], "target_fingerprint": approval["target_fingerprint"],
        "target_commit": approval["target_commit"], "nonce": approval["nonce"],
        "policy_sha256": approval["policy_sha256"],
        "consumer_workflow_id": approval["consumer_workflow_id"],
        "consumer_workflow_path": approval["consumer_workflow_path"],
        "consumer_default_branch_sha": consumer_default_branch_sha,
        "run_id": run_id, "run_attempt": run_attempt,
        "actor": actor, "triggering_actor": triggering_actor, "event": event,
    }


def marker_from_claim(
    approval: Mapping[str, Any], claim: Mapping[str, Any], *, claim_comment_id: int,
    claim_created_at: str, finalizer_default_branch_sha: str,
    finalizer_run_id: int, finalizer_run_attempt: int,
    finalizer_actor: str, finalizer_triggering_actor: str, finalizer_event: str,
) -> dict[str, Any]:
    return {
        "schema": MARKER_SCHEMA,
        "approval_digest": digest_json(dict(approval)),
        "claim_digest": digest_json(dict(claim)),
        "claim_comment_id": claim_comment_id,
        "claim_created_at": claim_created_at,
        "protected_repository": approval["protected_repository"],
        "protected_repository_id": approval["protected_repository_id"],
        "control_repository": approval["control_repository"],
        "control_repository_id": approval["control_repository_id"],
        "approval_issue_id": approval["approval_issue_id"],
        "approval_comment_id": approval["approval_comment_id"],
        "consumption_issue_id": claim["consumption_issue_id"],
        "gate": approval["gate"], "bypass": approval["bypass"],
        "action": approval["action"], "surface": approval["surface"],
        "target": approval["target"], "target_fingerprint": approval["target_fingerprint"],
        "target_commit": approval["target_commit"], "nonce": approval["nonce"],
        "policy_sha256": approval["policy_sha256"],
        "consumer_workflow_id": claim["consumer_workflow_id"],
        "consumer_workflow_path": claim["consumer_workflow_path"],
        "consumer_default_branch_sha": claim["consumer_default_branch_sha"],
        "consumer_run_id": claim["run_id"],
        "finalizer_workflow_id": approval["finalizer_workflow_id"],
        "finalizer_workflow_path": approval["finalizer_workflow_path"],
        "finalizer_default_branch_sha": finalizer_default_branch_sha,
        "finalizer_run_id": finalizer_run_id,
        "finalizer_run_attempt": finalizer_run_attempt,
        "finalizer_actor": finalizer_actor,
        "finalizer_triggering_actor": finalizer_triggering_actor,
        "finalizer_event": finalizer_event,
    }
