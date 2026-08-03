#!/usr/bin/env python3
"""Trusted consumer: reserve one approval and attest the fresh provider attempt."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import importlib.util
import json
from pathlib import Path
import sys

BASE = Path(__file__).resolve().parent
LIB = BASE / "lib"
sys.path.insert(0, str(LIB))
from bypass_contract import (  # noqa: E402
    ContractError,
    claim_from_approval,
    digest_json,
    load_json,
    load_policy,
    parse_timestamp,
    positive_int,
    validate_claim_shape,
    validate_control_config,
    validate_sha,
)
from github_provider import ProviderError  # noqa: E402

spec = importlib.util.spec_from_file_location("eos_bypass_validator", BASE / "validate-bypass-approval.py")
if spec is None or spec.loader is None:
    raise RuntimeError("cannot load pinned bypass validator")
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)

ATTEMPT_ENVIRONMENT = "engineering-os-bypass"


def build_parser() -> argparse.ArgumentParser:
    parser = validator.build_parser()
    parser.set_defaults(stage="approval")
    parser.add_argument("--consumer-default-branch-sha", required=True)
    parser.add_argument("--run-id", required=True, type=int)
    parser.add_argument("--run-attempt", required=True, type=int)
    parser.add_argument("--actor", required=True)
    parser.add_argument("--triggering-actor", required=True)
    parser.add_argument("--event", required=True)
    parser.add_argument("--authorization-deployment-id", required=True, type=int)
    return parser


def _require_populated_control_config(config: dict) -> None:
    control = config["control_repository"]
    if not control.get("full_name") or not isinstance(control.get("id"), int) or control["id"] <= 0:
        raise ContractError("control repository identities are not configured")
    validate_sha(control.get("trusted_default_branch_sha"), "control_repository.trusted_default_branch_sha")
    issues = config["issues"]
    if not all(isinstance(issues.get(name), int) and issues[name] > 0 for name in ("approval", "consumption")):
        raise ContractError("control issue identities are not configured")
    if issues["approval"] == issues["consumption"]:
        raise ContractError("approval and consumption issues must be separate")
    positive_int(config["consumer"].get("workflow_id"), "consumer.workflow_id")
    positive_int(config["finalizer"].get("workflow_id"), "finalizer.workflow_id")


def _status_description(result: str, run_id: int, run_attempt: int) -> str:
    return f"eos-bypass-auth/v1 {result} run={run_id} attempt={run_attempt}"


def _verify_created_status(created: dict, *, config: dict, deployment_id: int, result: str) -> int:
    status_id = positive_int(created.get("id"), "authorization_status.id")
    expected_state = "success" if result == "success" else "failure"
    if created.get("state") != expected_state or created.get("environment") != ATTEMPT_ENVIRONMENT:
        raise ContractError("created authorization status state/environment mismatch")
    creator = created.get("creator")
    writer = config["consumer"]
    if not isinstance(creator, dict) or (
        creator.get("login"), creator.get("id"), creator.get("type")
    ) != (writer["writer_login"], writer["writer_user_id"], "Bot"):
        raise ContractError("created authorization status writer identity mismatch")
    if validator.repo_name_from_api_url(created.get("repository_url")) != config["control_repository"]["full_name"]:
        raise ContractError("created authorization status repository mismatch")
    deployment_url = created.get("deployment_url")
    if not isinstance(deployment_url, str) or not deployment_url.endswith(f"/deployments/{deployment_id}"):
        raise ContractError("created authorization status deployment mismatch")
    return status_id


def _best_effort_failure_status(provider, config: dict | None, args: argparse.Namespace) -> None:
    if provider is None or config is None:
        return
    try:
        provider.create_deployment_status(
            config["control_repository"]["full_name"],
            args.authorization_deployment_id,
            state="failure",
            description=_status_description("failure", args.run_id, args.run_attempt),
            environment=ATTEMPT_ENVIRONMENT,
        )
    except Exception:
        pass


def main() -> int:
    args = build_parser().parse_args()
    provider = None
    config = None
    try:
        validator.require_test_overrides(args)
        positive_int(args.authorization_deployment_id, "authorization_deployment_id")
        config = load_json(BASE / "bypass-control-plane.json")
        # The trusted consumer is allowed to exercise a fully populated but still
        # unqualified control plane during live qualification. Runtime
        # authorization remains disabled until the canonical config is qualified.
        validate_control_config(config, require_qualified=False)
        _require_populated_control_config(config)
        policy = load_policy(BASE / "bypass-policy.tsv")
        if args.repository != config["protected_repository"]["full_name"]:
            raise ContractError("requested protected repository mismatch")
        provider = validator.make_provider(args, config)
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
        approval = validator.verify_approval(
            provider, config, policy,
            approval_comment_id=args.approval_comment_id,
            expected=expected,
            now=now,
        )
        if approval["control_default_branch_sha"] != config["control_repository"]["trusted_default_branch_sha"]:
            raise ContractError("approval does not bind the configured trusted control-plane SHA")
        existing_claims = validator.matching_claims(provider, config, policy, approval)
        if existing_claims:
            raise ContractError("approval replay denied: durable claim already exists")
        for marker, _comment in validator.iter_schema_comments(
            provider.issue_comments(config["control_repository"]["full_name"], config["issues"]["consumption"]),
            __import__("bypass_contract").MARKER_SCHEMA,
            "marker",
        ):
            if marker.get("approval_digest") == digest_json(approval):
                raise ContractError("approval replay denied: durable marker already exists")
        claim = claim_from_approval(
            approval,
            consumption_issue_id=config["issues"]["consumption"],
            consumer_default_branch_sha=args.consumer_default_branch_sha,
            run_id=args.run_id,
            run_attempt=args.run_attempt,
            actor=args.actor,
            triggering_actor=args.triggering_actor,
            event=args.event,
        )
        validate_claim_shape(claim, policy)
        if claim["consumer_default_branch_sha"] != approval["control_default_branch_sha"]:
            raise ContractError("consumer run does not match approved default-branch SHA")
        body = json.dumps(claim, sort_keys=True, separators=(",", ":"))
        created_claim = provider.create_issue_comment(
            config["control_repository"]["full_name"],
            config["issues"]["consumption"],
            body,
        )
        if not isinstance(created_claim, dict) or not isinstance(created_claim.get("id"), int):
            raise ContractError("provider did not return one created claim comment")
        created_status = provider.create_deployment_status(
            config["control_repository"]["full_name"],
            args.authorization_deployment_id,
            state="success",
            description=_status_description("success", args.run_id, args.run_attempt),
            environment=ATTEMPT_ENVIRONMENT,
        )
        if not isinstance(created_status, dict):
            raise ContractError("provider did not return one created authorization status")
        status_id = _verify_created_status(
            created_status,
            config=config,
            deployment_id=args.authorization_deployment_id,
            result="success",
        )
        print(json.dumps({
            "claimed": True,
            "approval_digest": digest_json(approval),
            "claim_digest": digest_json(claim),
            "claim_comment_id": created_claim["id"],
            "authorization_deployment_id": args.authorization_deployment_id,
            "authorization_status_id": status_id,
        }, sort_keys=True, separators=(",", ":")))
        return 0
    except (ContractError, ProviderError, OSError, KeyError, TypeError, ValueError) as exc:
        _best_effort_failure_status(provider, config, args)
        print(json.dumps({"claimed": False, "error": str(exc)}, sort_keys=True), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
