#!/usr/bin/env python3
"""Request and verify exactly one provider-backed bypass authorization attempt."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import importlib.util
import json
import os
from pathlib import Path
import re
import sys
import time
from typing import Any, Mapping

BASE = Path(__file__).resolve().parent
LIB = BASE / "lib"
sys.path.insert(0, str(LIB))
from bypass_contract import (  # noqa: E402
    ContractError,
    digest_json,
    load_json,
    load_policy,
    parse_timestamp,
    positive_int,
    validate_control_config,
    validate_sha,
)
from github_provider import FixtureProvider, GitHubProvider, ProviderError  # noqa: E402

spec = importlib.util.spec_from_file_location("eos_bypass_validator", BASE / "validate-bypass-approval.py")
if spec is None or spec.loader is None:
    raise RuntimeError("cannot load pinned bypass validator")
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)

ATTEMPT_SCHEMA = "eos-bypass-authorization-attempt/v1"
ATTEMPT_TASK = "engineering-os:bypass-authorization"
ATTEMPT_ENVIRONMENT = "engineering-os-bypass"
STATUS_RE = re.compile(r"^eos-bypass-auth/v1 (success|failure) run=([1-9][0-9]*) attempt=([1-9][0-9]*)$")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bypass", required=True)
    parser.add_argument("--gate", required=True)
    parser.add_argument("--action", required=True)
    parser.add_argument("--surface", required=True)
    parser.add_argument("--repository", required=True)
    parser.add_argument("--target", required=True)
    parser.add_argument("--target-fingerprint", required=True)
    parser.add_argument("--target-commit", required=True)
    parser.add_argument("--approval-comment-id", required=True, type=int)
    parser.add_argument("--timeout", type=float, default=10.0)
    parser.add_argument("--poll-timeout", type=float, default=120.0)
    parser.add_argument("--poll-interval", type=float, default=2.0)
    parser.add_argument("--provider-fixture", help=argparse.SUPPRESS)
    parser.add_argument("--now", help=argparse.SUPPRESS)
    parser.add_argument("--qualification-mode", action="store_true", help=argparse.SUPPRESS)
    return parser


def _qualification_requested(args: argparse.Namespace) -> bool:
    requested = bool(getattr(args, "qualification_mode", False))
    if requested and os.environ.get("ENGINEERING_OS_BYPASS_QUALIFICATION_MODE") != "1":
        raise ContractError("qualification mode requires explicit operator environment")
    return requested


def _require_populated_control_config(config: Mapping[str, Any]) -> None:
    control = config["control_repository"]
    if not control.get("full_name") or not isinstance(control.get("id"), int) or control["id"] <= 0:
        raise ContractError("control repository identities are not configured")
    validate_sha(control.get("trusted_default_branch_sha"), "control_repository.trusted_default_branch_sha")
    issues = config["issues"]
    if not all(isinstance(issues.get(name), int) and issues[name] > 0 for name in ("approval", "consumption")):
        raise ContractError("control issue identities are not configured")
    if issues["approval"] == issues["consumption"]:
        raise ContractError("approval and consumption issues must be separate")
    for kind in ("consumer", "finalizer"):
        positive_int(config[kind].get("workflow_id"), f"{kind}.workflow_id")


def _make_runtime_provider(args: argparse.Namespace, config: Mapping[str, Any]):
    if args.provider_fixture:
        if os.environ.get("ENGINEERING_OS_BYPASS_TEST_MODE") != "1":
            raise ContractError("test-only provider fixture is disabled outside explicit test mode")
        return FixtureProvider.from_path(args.provider_fixture)
    runtime_token = os.environ.get("EOS_BYPASS_PROVIDER_TOKEN", "")
    if not runtime_token:
        raise ContractError("runtime bypass provider credential is missing")
    protected_token = os.environ.get("GITHUB_TOKEN_READ_ONLY", "")
    return GitHubProvider(
        runtime_token,
        protected_token,
        control_repository=config["control_repository"]["full_name"],
        protected_repository=config["protected_repository"]["full_name"],
        api_base=config["provider"]["api_base"],
        timeout=args.timeout,
    )


def _repo_name_from_api_url(value: Any) -> str | None:
    return validator.repo_name_from_api_url(value)


def _deployment_id_from_url(value: Any) -> int | None:
    if not isinstance(value, str):
        return None
    match = re.search(r"/deployments/(\d+)$", value)
    return int(match.group(1)) if match else None


def _verify_deployment(
    deployment: Mapping[str, Any], *, config: Mapping[str, Any], approval: Mapping[str, Any],
    payload: Mapping[str, Any],
) -> int:
    deployment_id = positive_int(deployment.get("id"), "deployment.id")
    if deployment.get("task") != ATTEMPT_TASK or deployment.get("environment") != ATTEMPT_ENVIRONMENT:
        raise ContractError("deployment task/environment binding mismatch")
    if deployment.get("payload") != dict(payload):
        raise ContractError("deployment payload binding mismatch")
    if deployment.get("sha") != approval["control_default_branch_sha"]:
        raise ContractError("deployment resolved to an untrusted control-plane SHA")
    repo = deployment.get("repository")
    if isinstance(repo, dict):
        if repo.get("id") != config["control_repository"]["id"] or repo.get("full_name") != config["control_repository"]["full_name"]:
            raise ContractError("deployment repository identity mismatch")
    elif _repo_name_from_api_url(deployment.get("repository_url")) != config["control_repository"]["full_name"]:
        raise ContractError("deployment repository identity is unavailable or wrong")
    return deployment_id


def _trusted_terminal_status(
    statuses: list[Any], *, config: Mapping[str, Any], deployment_id: int,
) -> tuple[str, int, int, int] | None:
    candidates: list[tuple[str, int, int, int]] = []
    for status in statuses:
        if not isinstance(status, dict):
            raise ContractError("ambiguous deployment-status provider result")
        description = status.get("description")
        if not isinstance(description, str) or not description.startswith("eos-bypass-auth/"):
            continue
        match = STATUS_RE.fullmatch(description)
        if match is None:
            raise ContractError("malformed bypass authorization deployment status")
        creator = status.get("creator")
        expected = config["consumer"]
        if not isinstance(creator, dict) or (
            creator.get("login"), creator.get("id"), creator.get("type")
        ) != (expected["writer_login"], expected["writer_user_id"], "Bot"):
            raise ContractError("authorization status was not written by the pinned GitHub Actions identity")
        if _deployment_id_from_url(status.get("deployment_url")) != deployment_id:
            raise ContractError("authorization status belongs to the wrong deployment")
        if _repo_name_from_api_url(status.get("repository_url")) != config["control_repository"]["full_name"]:
            raise ContractError("authorization status belongs to the wrong repository")
        if status.get("environment") != ATTEMPT_ENVIRONMENT:
            raise ContractError("authorization status environment mismatch")
        created_at = status.get("created_at")
        if not isinstance(created_at, str) or status.get("updated_at") != created_at:
            raise ContractError("authorization status is edited or malformed")
        parse_timestamp(created_at, "authorization_status.created_at")
        result, run_text, attempt_text = match.groups()
        run_id, run_attempt = int(run_text), int(attempt_text)
        if status.get("state") != ("success" if result == "success" else "failure"):
            raise ContractError("authorization status state/result mismatch")
        candidates.append((result, run_id, run_attempt, positive_int(status.get("id"), "authorization_status.id")))
    if not candidates:
        return None
    if len(candidates) != 1:
        raise ContractError("ambiguous bypass authorization deployment statuses")
    return candidates[0]


def _consumer_run_state(
    provider: Any, *, config: Mapping[str, Any], approval: Mapping[str, Any],
    deployment: Mapping[str, Any], run_id: int, run_attempt: int,
) -> str:
    """Return pending/success; every terminal non-success or binding mismatch denies."""
    if run_attempt != 1:
        raise ContractError("authorization consumer run must be first attempt")
    run = provider.workflow_run(config["control_repository"]["full_name"], run_id)
    creator = deployment.get("creator")
    creator_login = creator.get("login") if isinstance(creator, dict) else None
    checks = {
        "id": run_id,
        "run_attempt": 1,
        "head_sha": approval["control_default_branch_sha"],
        "head_branch": config["control_repository"]["default_branch"],
        "event": "deployment",
        "workflow_id": config["consumer"]["workflow_id"],
        "path": config["consumer"]["workflow_path"],
        "repository.id": config["control_repository"]["id"],
    }
    for key, wanted in checks.items():
        if validator._nested(run, key) != wanted:
            raise ContractError(f"authorization consumer run binding mismatch for {key}")
    if creator_login and validator._nested(run, "actor.login") != creator_login:
        raise ContractError("authorization consumer run actor does not match deployment creator")
    status = run.get("status")
    conclusion = run.get("conclusion")
    if status != "completed":
        if conclusion not in (None, ""):
            raise ContractError("non-terminal authorization consumer run exposed a conclusion")
        return "pending"
    if conclusion != "success":
        raise ContractError("authorization consumer run did not complete successfully")
    return "success"


def authorize_once(
    provider: Any, *, config: Mapping[str, Any], policy: Mapping[str, Any],
    expected: Mapping[str, Any], approval_comment_id: int, now: datetime,
    poll_timeout: float, poll_interval: float,
) -> dict[str, Any]:
    if poll_timeout <= 0 or poll_timeout > 600:
        raise ContractError("poll timeout must be between 0 and 600 seconds")
    if poll_interval < 0 or poll_interval > 30:
        raise ContractError("poll interval must be between 0 and 30 seconds")
    approval = validator.verify_approval(
        provider, config, policy,
        approval_comment_id=approval_comment_id,
        expected=expected,
        now=now,
    )
    if approval["control_default_branch_sha"] != config["control_repository"]["trusted_default_branch_sha"]:
        raise ContractError("approval does not bind the configured trusted control-plane SHA")
    payload = {
        "schema": ATTEMPT_SCHEMA,
        "approval_comment_id": approval["approval_comment_id"],
        "approval_digest": digest_json(dict(approval)),
        "protected_repository": approval["protected_repository"],
        "bypass": approval["bypass"],
        "gate": approval["gate"],
        "action": approval["action"],
        "surface": approval["surface"],
        "target": approval["target"],
        "target_fingerprint": approval["target_fingerprint"],
        "target_commit": approval["target_commit"],
        "policy_sha256": approval["policy_sha256"],
    }
    deployment = provider.create_deployment(
        config["control_repository"]["full_name"],
        ref=config["control_repository"]["default_branch"],
        task=ATTEMPT_TASK,
        environment=ATTEMPT_ENVIRONMENT,
        payload=payload,
    )
    deployment_id = _verify_deployment(deployment, config=config, approval=approval, payload=payload)
    deadline = time.monotonic() + poll_timeout
    while True:
        status = _trusted_terminal_status(
            provider.deployment_statuses(config["control_repository"]["full_name"], deployment_id),
            config=config,
            deployment_id=deployment_id,
        )
        if status is not None:
            result, run_id, run_attempt, status_id = status
            if result != "success":
                raise ContractError("trusted consumer denied the one-shot authorization attempt")
            run_state = _consumer_run_state(
                provider,
                config=config,
                approval=approval,
                deployment=deployment,
                run_id=run_id,
                run_attempt=run_attempt,
            )
            if run_state == "success":
                claims = validator.matching_claims(provider, config, policy, approval)
                if len(claims) != 1:
                    raise ContractError(f"expected exactly one durable claim, found {len(claims)}")
                claim, claim_comment = claims[0]
                if claim["run_id"] != run_id or claim["run_attempt"] != run_attempt:
                    raise ContractError("durable claim is not bound to this fresh authorization attempt")
                return {
                    "authorized": True,
                    "approval_comment_id": approval["approval_comment_id"],
                    "approval_digest": digest_json(dict(approval)),
                    "deployment_id": deployment_id,
                    "authorization_status_id": status_id,
                    "consumer_run_id": run_id,
                    "claim_comment_id": claim_comment.get("id"),
                    "claim_digest": digest_json(claim),
                }
        if time.monotonic() >= deadline:
            raise ContractError("authorization attempt timed out before trusted consumer terminal success")
        time.sleep(poll_interval)


def main() -> int:
    args = build_parser().parse_args()
    try:
        validator.require_test_overrides(args)
        qualification_mode = _qualification_requested(args)
        config = load_json(BASE / "bypass-control-plane.json")
        validate_control_config(config, require_qualified=not qualification_mode)
        _require_populated_control_config(config)
        policy = load_policy(BASE / "bypass-policy.tsv")
        if args.repository != config["protected_repository"]["full_name"]:
            raise ContractError("requested protected repository mismatch")
        provider = _make_runtime_provider(args, config)
        now = parse_timestamp(args.now, "now") if args.now else datetime.now(timezone.utc)
        expected = {
            "bypass": args.bypass,
            "gate": args.gate,
            "action": args.action,
            "surface": args.surface,
            "target": args.target,
            "target_fingerprint": args.target_fingerprint,
            "target_commit": args.target_commit,
        }
        result = authorize_once(
            provider,
            config=config,
            policy=policy,
            expected=expected,
            approval_comment_id=args.approval_comment_id,
            now=now,
            poll_timeout=args.poll_timeout,
            poll_interval=args.poll_interval,
        )
    except (ContractError, ProviderError, OSError, KeyError, TypeError, ValueError) as exc:
        print(json.dumps({"authorized": False, "error": str(exc)}, sort_keys=True), file=sys.stderr)
        return 1
    print(json.dumps(result, sort_keys=True, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
