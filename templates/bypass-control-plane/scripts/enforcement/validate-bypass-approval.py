#!/usr/bin/env python3
"""Validate bounded, provider-backed, one-shot bypass approval provenance."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import sys
from typing import Any, Mapping

BASE = Path(__file__).resolve().parent
LIB = BASE / "lib"
sys.path.insert(0, str(LIB))
from bypass_contract import (  # noqa: E402
    APPROVAL_SCHEMA,
    CLAIM_SCHEMA,
    MARKER_SCHEMA,
    ContractError,
    digest_json,
    load_json,
    load_policy,
    parse_timestamp,
    validate_approval_shape,
    validate_claim_shape,
    validate_control_config,
    validate_marker_shape,
)
from github_provider import FixtureProvider, GitHubProvider, ProviderError  # noqa: E402

SCHEMA_HINT_RE = re.compile(r'"schema"\s*:\s*"(eos-bypass-(?:approval|consumption|marker)/v1)"')


def issue_number_from_url(value: Any) -> int | None:
    if not isinstance(value, str):
        return None
    match = re.search(r"/issues/(\d+)$", value)
    return int(match.group(1)) if match else None


def repo_name_from_api_url(value: Any) -> str | None:
    if not isinstance(value, str):
        return None
    match = re.search(r"/repos/([^/]+/[^/]+)(?:/|$)", value)
    return match.group(1) if match else None


def parse_json_comment(body: Any, schema: str, label: str) -> dict[str, Any]:
    if not isinstance(body, str) or not body.strip():
        raise ContractError(f"{label} has no JSON body")
    try:
        parsed = json.loads(body)
    except json.JSONDecodeError as exc:
        raise ContractError(f"{label} contains malformed JSON") from exc
    if not isinstance(parsed, dict) or parsed.get("schema") != schema:
        raise ContractError(f"{label} schema mismatch")
    return parsed


def iter_schema_comments(comments: list[Any], schema: str, label: str):
    for comment in comments:
        if not isinstance(comment, dict):
            raise ContractError(f"ambiguous provider result in {label} comments")
        body = comment.get("body")
        hint = SCHEMA_HINT_RE.search(body) if isinstance(body, str) else None
        if hint is None:
            continue
        if hint.group(1) != schema:
            continue
        yield parse_json_comment(body, schema, label), comment


def require_test_overrides(args: argparse.Namespace) -> None:
    if (getattr(args, "provider_fixture", None) or getattr(args, "now", None)) and os.environ.get("ENGINEERING_OS_BYPASS_TEST_MODE") != "1":
        raise ContractError("test-only provider/time overrides are disabled outside explicit test mode")


def make_provider(args: argparse.Namespace, config: Mapping[str, Any]):
    if args.provider_fixture:
        return FixtureProvider.from_path(args.provider_fixture)
    runtime_token = os.environ.get("EOS_BYPASS_PROVIDER_TOKEN", "")
    control_token = os.environ.get("GITHUB_TOKEN", "") or runtime_token
    protected_token = os.environ.get("GITHUB_TOKEN_READ_ONLY", "")
    return GitHubProvider(
        control_token,
        protected_token,
        control_repository=config["control_repository"]["full_name"],
        protected_repository=config["protected_repository"]["full_name"],
        api_base=config["provider"]["api_base"],
        timeout=args.timeout,
    )


def _verify_repository_identities(provider: Any, config: Mapping[str, Any]) -> None:
    protected_name = config["protected_repository"]["full_name"]
    control_name = config["control_repository"]["full_name"]
    protected = provider.repository(protected_name)
    control = provider.repository(control_name)
    if protected.get("id") != config["protected_repository"]["id"] or protected.get("full_name") != protected_name:
        raise ContractError("protected repository provider identity mismatch")
    if control.get("id") != config["control_repository"]["id"] or control.get("full_name") != control_name:
        raise ContractError("control repository provider identity mismatch")
    if control.get("private") is not True:
        raise ContractError("control repository is not private")


def _verify_workflow(provider: Any, config: Mapping[str, Any], kind: str) -> None:
    expected = config[kind]
    workflow = provider.workflow(config["control_repository"]["full_name"], expected["workflow_id"])
    if workflow.get("id") != expected["workflow_id"] or workflow.get("path") != expected["workflow_path"]:
        raise ContractError(f"wrong {kind} workflow ID/path")


def _nested(value: Mapping[str, Any], key: str) -> Any:
    current: Any = value
    for part in key.split("."):
        current = current.get(part) if isinstance(current, dict) else None
    return current


def _verify_run(
    run: Mapping[str, Any], *, config: Mapping[str, Any], kind: str,
    run_id: int, run_attempt: int, head_sha: str, event: str,
    actor: str, triggering_actor: str,
) -> None:
    expected_workflow = config[kind]
    checks = {
        "id": run_id,
        "run_attempt": run_attempt,
        "head_sha": head_sha,
        "head_branch": config["control_repository"]["default_branch"],
        "event": event,
        "status": "completed",
        "conclusion": "success",
        "workflow_id": expected_workflow["workflow_id"],
        "path": expected_workflow["workflow_path"],
        "actor.login": actor,
        "triggering_actor.login": triggering_actor,
        "repository.id": config["control_repository"]["id"],
    }
    for key, wanted in checks.items():
        if _nested(run, key) != wanted:
            raise ContractError(f"{kind} run binding mismatch for {key}")
    if run_attempt != 1:
        raise ContractError(f"{kind} run must be first attempt")


def verify_approval(
    provider: Any,
    config: Mapping[str, Any],
    policy: Mapping[str, Any],
    *,
    approval_comment_id: int,
    expected: Mapping[str, Any],
    now: datetime,
) -> dict[str, Any]:
    protected_name = config["protected_repository"]["full_name"]
    control_name = config["control_repository"]["full_name"]
    comment = provider.issue_comment(control_name, approval_comment_id)
    if comment.get("id") != approval_comment_id:
        raise ContractError("provider returned the wrong approval comment")
    if issue_number_from_url(comment.get("issue_url")) != config["issues"]["approval"]:
        raise ContractError("approval comment belongs to wrong issue")
    if repo_name_from_api_url(comment.get("repository_url")) != control_name:
        raise ContractError("approval comment belongs to wrong control repository")
    created_at = comment.get("created_at")
    if comment.get("updated_at") != created_at:
        raise ContractError("edited approval comments are forbidden")
    approval = parse_json_comment(comment.get("body"), APPROVAL_SCHEMA, "approval comment")
    validate_approval_shape(approval, policy)
    if approval["approval_comment_id"] != approval_comment_id:
        raise ContractError("approval payload comment ID mismatch")
    if approval["approval_created_at"] != created_at:
        raise ContractError("approval time must equal provider created_at")
    if approval["approval_issue_id"] != config["issues"]["approval"]:
        raise ContractError("approval payload issue mismatch")
    if approval["protected_repository"] != protected_name or approval["control_repository"] != control_name:
        raise ContractError("approval repository binding mismatch")
    if approval["protected_repository_id"] != config["protected_repository"]["id"] or approval["control_repository_id"] != config["control_repository"]["id"]:
        raise ContractError("approval repository ID binding mismatch")
    if approval["consumer_workflow_id"] != config["consumer"]["workflow_id"] or approval["consumer_workflow_path"] != config["consumer"]["workflow_path"]:
        raise ContractError("approval consumer workflow binding mismatch")
    if approval["finalizer_workflow_id"] != config["finalizer"]["workflow_id"] or approval["finalizer_workflow_path"] != config["finalizer"]["workflow_path"]:
        raise ContractError("approval finalizer workflow binding mismatch")
    user = comment.get("user")
    if not isinstance(user, dict):
        raise ContractError("provider comment has no issuer object")
    actual_identity = (user.get("login"), user.get("id"), user.get("type"))
    approved_identity = (approval["issuer_login"], approval["issuer_user_id"], approval["issuer_type"])
    if approved_identity != actual_identity:
        raise ContractError("issuer identity does not match provider")
    if user.get("type") != "User":
        raise ContractError("Bot issuers are forbidden")
    permission = provider.collaborator_permission(protected_name, approval["issuer_login"])
    role = permission.get("role_name") or permission.get("permission")
    if role not in {"maintain", "admin"} or approval["issuer_role"] != role:
        raise ContractError("issuer permission is not maintain/admin")
    _verify_repository_identities(provider, config)
    _verify_workflow(provider, config, "consumer")
    _verify_workflow(provider, config, "finalizer")
    policy_digest = hashlib.sha256((BASE / "bypass-policy.tsv").read_bytes()).hexdigest()
    if approval["policy_sha256"] != policy_digest:
        raise ContractError("policy SHA mismatch")
    for key in ("bypass", "gate", "action", "surface", "target", "target_fingerprint", "target_commit"):
        if approval[key] != expected[key]:
            raise ContractError(f"approval {key} does not match requested context")
    created = parse_timestamp(approval["approval_created_at"], "approval_created_at")
    expires = parse_timestamp(approval["expires_at"], "expires_at")
    if now < created:
        raise ContractError("approval is future-dated")
    if now >= expires:
        raise ContractError("approval is expired")
    return approval


def _verify_machine_comment(
    comment: Mapping[str, Any], *, config: Mapping[str, Any], issue_number: int,
    writer_login: str, label: str,
) -> str:
    if issue_number_from_url(comment.get("issue_url")) != issue_number:
        raise ContractError(f"{label} belongs to wrong issue")
    if repo_name_from_api_url(comment.get("repository_url")) != config["control_repository"]["full_name"]:
        raise ContractError(f"{label} belongs to wrong repository")
    created_at = comment.get("created_at")
    if not isinstance(created_at, str) or comment.get("updated_at") != created_at:
        raise ContractError(f"edited or malformed {label}")
    user = comment.get("user")
    if not isinstance(user, dict) or user.get("login") != writer_login or user.get("type") != "Bot":
        raise ContractError(f"{label} was not written by the pinned GitHub Actions identity")
    parse_timestamp(created_at, f"{label}.created_at")
    return created_at


def verify_claim(
    provider: Any,
    config: Mapping[str, Any],
    policy: Mapping[str, Any],
    approval: Mapping[str, Any],
    claim: Mapping[str, Any],
    comment: Mapping[str, Any],
) -> None:
    validate_claim_shape(claim, policy)
    if claim["approval_digest"] != digest_json(dict(approval)):
        raise ContractError("claim approval digest mismatch")
    copied = (
        "protected_repository", "protected_repository_id", "control_repository",
        "control_repository_id", "approval_issue_id", "approval_comment_id",
        "gate", "bypass", "action", "surface", "target", "target_fingerprint",
        "target_commit", "nonce", "policy_sha256", "consumer_workflow_id",
        "consumer_workflow_path",
    )
    for key in copied:
        if claim[key] != approval[key]:
            raise ContractError(f"claim conflicts with approval field {key}")
    if claim["consumption_issue_id"] != config["issues"]["consumption"]:
        raise ContractError("claim consumption issue mismatch")
    if claim["consumer_default_branch_sha"] != approval["control_default_branch_sha"]:
        raise ContractError("claim default-branch SHA mismatch")
    created_at = _verify_machine_comment(
        comment,
        config=config,
        issue_number=config["issues"]["approval"],
        writer_login=config["consumer"]["writer_login"],
        label="claim comment",
    )
    if parse_timestamp(created_at, "claim.created_at") >= parse_timestamp(approval["expires_at"], "expires_at"):
        raise ContractError("claim was created after approval expiry")
    run = provider.workflow_run(config["control_repository"]["full_name"], claim["run_id"])
    _verify_run(
        run,
        config=config,
        kind="consumer",
        run_id=claim["run_id"],
        run_attempt=claim["run_attempt"],
        head_sha=claim["consumer_default_branch_sha"],
        event=claim["event"],
        actor=claim["actor"],
        triggering_actor=claim["triggering_actor"],
    )


def matching_claims(provider: Any, config: Mapping[str, Any], policy: Mapping[str, Any], approval: Mapping[str, Any]):
    matches = []
    comments = provider.issue_comments(config["control_repository"]["full_name"], config["issues"]["approval"])
    for claim, comment in iter_schema_comments(comments, CLAIM_SCHEMA, "claim"):
        validate_claim_shape(claim, policy)
        if claim["approval_digest"] != digest_json(dict(approval)):
            continue
        verify_claim(provider, config, policy, approval, claim, comment)
        matches.append((claim, comment))
    return matches


def verify_marker(
    provider: Any,
    config: Mapping[str, Any],
    policy: Mapping[str, Any],
    approval: Mapping[str, Any],
    claim: Mapping[str, Any],
    claim_comment: Mapping[str, Any],
    marker: Mapping[str, Any],
    marker_comment: Mapping[str, Any],
) -> None:
    validate_marker_shape(marker, policy)
    if marker["approval_digest"] != digest_json(dict(approval)) or marker["claim_digest"] != digest_json(dict(claim)):
        raise ContractError("marker digest binding mismatch")
    if marker["claim_comment_id"] != claim_comment.get("id") or marker["claim_created_at"] != claim_comment.get("created_at"):
        raise ContractError("marker claim provider binding mismatch")
    copied = (
        "protected_repository", "protected_repository_id", "control_repository",
        "control_repository_id", "approval_issue_id", "approval_comment_id",
        "consumption_issue_id", "gate", "bypass", "action", "surface", "target",
        "target_fingerprint", "target_commit", "nonce", "policy_sha256",
        "consumer_workflow_id", "consumer_workflow_path", "consumer_default_branch_sha",
    )
    for key in copied:
        source = claim if key in claim else approval
        if marker[key] != source[key]:
            raise ContractError(f"marker conflicts with source field {key}")
    if marker["consumer_run_id"] != claim["run_id"]:
        raise ContractError("marker consumer run binding mismatch")
    if marker["finalizer_workflow_id"] != approval["finalizer_workflow_id"] or marker["finalizer_workflow_path"] != approval["finalizer_workflow_path"]:
        raise ContractError("marker finalizer workflow binding mismatch")
    created_at = _verify_machine_comment(
        marker_comment,
        config=config,
        issue_number=config["issues"]["consumption"],
        writer_login=config["finalizer"]["writer_login"],
        label="marker comment",
    )
    if parse_timestamp(created_at, "marker.created_at") >= parse_timestamp(approval["expires_at"], "expires_at"):
        raise ContractError("marker was created after approval expiry")
    run = provider.workflow_run(config["control_repository"]["full_name"], marker["finalizer_run_id"])
    _verify_run(
        run,
        config=config,
        kind="finalizer",
        run_id=marker["finalizer_run_id"],
        run_attempt=marker["finalizer_run_attempt"],
        head_sha=marker["finalizer_default_branch_sha"],
        event=marker["finalizer_event"],
        actor=marker["finalizer_actor"],
        triggering_actor=marker["finalizer_triggering_actor"],
    )


def matching_markers(
    provider: Any,
    config: Mapping[str, Any],
    policy: Mapping[str, Any],
    approval: Mapping[str, Any],
    claim: Mapping[str, Any],
    claim_comment: Mapping[str, Any],
):
    matches = []
    comments = provider.issue_comments(config["control_repository"]["full_name"], config["issues"]["consumption"])
    for marker, comment in iter_schema_comments(comments, MARKER_SCHEMA, "marker"):
        validate_marker_shape(marker, policy)
        if marker["approval_digest"] != digest_json(dict(approval)):
            continue
        if marker["claim_digest"] != digest_json(dict(claim)):
            raise ContractError("conflicting marker exists for the approval")
        verify_marker(provider, config, policy, approval, claim, claim_comment, marker, comment)
        matches.append((marker, comment))
    return matches


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stage", choices=("approval", "claimed", "consumed"), default="consumed")
    parser.add_argument("--bypass", required=True)
    parser.add_argument("--gate", required=True)
    parser.add_argument("--action", required=True)
    parser.add_argument("--surface", required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--target", required=True)
    parser.add_argument("--target-fingerprint", required=True)
    parser.add_argument("--target-commit", required=True)
    parser.add_argument("--approval-comment-id", required=True, type=int)
    parser.add_argument("--provider-fixture", help=argparse.SUPPRESS)
    parser.add_argument("--now", help=argparse.SUPPRESS)
    parser.add_argument("--timeout", type=float, default=10.0)
    return parser


def load_runtime(args: argparse.Namespace):
    require_test_overrides(args)
    config = load_json(BASE / "bypass-control-plane.json")
    validate_control_config(config)
    policy = load_policy(BASE / "bypass-policy.tsv")
    if args.repository != config["protected_repository"]["full_name"]:
        raise ContractError("requested protected repository mismatch")
    provider = make_provider(args, config)
    now = parse_timestamp(args.now, "now") if args.now else datetime.now(timezone.utc)
    expected = {
        "bypass": args.bypass, "gate": args.gate, "action": args.action,
        "surface": args.surface, "target": args.target,
        "target_fingerprint": args.target_fingerprint, "target_commit": args.target_commit,
    }
    return config, policy, provider, now, expected


def validate_from_args(args: argparse.Namespace) -> dict[str, Any]:
    config, policy, provider, now, expected = load_runtime(args)
    approval = verify_approval(
        provider, config, policy,
        approval_comment_id=args.approval_comment_id,
        expected=expected,
        now=now,
    )
    result: dict[str, Any] = {
        "authorized": False,
        "stage": args.stage,
        "approval_digest": digest_json(approval),
        "approval_comment_id": approval["approval_comment_id"],
    }
    if args.stage == "approval":
        return result
    claims = matching_claims(provider, config, policy, approval)
    if len(claims) != 1:
        raise ContractError(f"expected exactly one durable claim, found {len(claims)}")
    claim, claim_comment = claims[0]
    result.update({"claim_digest": digest_json(claim), "claim_comment_id": claim_comment.get("id")})
    if args.stage == "claimed":
        return result
    markers = matching_markers(provider, config, policy, approval, claim, claim_comment)
    if len(markers) != 1:
        raise ContractError(f"expected exactly one durable marker, found {len(markers)}")
    marker, marker_comment = markers[0]
    result.update({
        "authorized": True,
        "marker_digest": digest_json(marker),
        "marker_comment_id": marker_comment.get("id"),
        "consumer_run_id": claim["run_id"],
        "finalizer_run_id": marker["finalizer_run_id"],
    })
    return result


def main() -> int:
    args = build_parser().parse_args()
    try:
        result = validate_from_args(args)
    except (ContractError, ProviderError, OSError, KeyError, TypeError, ValueError) as exc:
        print(json.dumps({"authorized": False, "error": str(exc)}, sort_keys=True), file=sys.stderr)
        return 1
    print(json.dumps(result, sort_keys=True, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
