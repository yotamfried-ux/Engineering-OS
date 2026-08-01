#!/usr/bin/env python3
from __future__ import annotations

from copy import deepcopy
from datetime import datetime
import argparse
import importlib.util
import os
import hashlib
import json
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
from unittest import mock

ROOT = Path(__file__).resolve().parents[3]


def canonical_digest(value: dict) -> str:
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def command(repo: Path, script: str, fixture: dict, extra: list[str], *, expect: int = 0, test_mode: bool = True):
    fixture_path = repo / "fixture.json"
    fixture_path.write_text(json.dumps(fixture), encoding="utf-8")
    cmd = ["python3", str(repo / "scripts/enforcement" / script), *extra, "--provider-fixture", str(fixture_path), "--now", "2026-07-26T20:30:00Z"]
    env = os.environ.copy()
    if test_mode:
        env["ENGINEERING_OS_BYPASS_TEST_MODE"] = "1"
    else:
        env.pop("ENGINEERING_OS_BYPASS_TEST_MODE", None)
    completed = subprocess.run(cmd, cwd=repo, text=True, capture_output=True, timeout=30, env=env)
    if completed.returncode != expect:
        raise AssertionError(f"{script} expected {expect}, got {completed.returncode}\nstdout={completed.stdout}\nstderr={completed.stderr}")
    return completed


def common_args(stage: str = "consumed") -> list[str]:
    return [
        "--stage", stage,
        "--repository", "yotamfried-ux/Engineering-OS",
        "--bypass", "EOS_BYPASS_ENTRY",
        "--gate", "workflow",
        "--action", "allow-work-command-before-plan",
        "--surface", "PreToolUse",
        "--target", "command:pytest",
        "--target-fingerprint", "1" * 64,
        "--target-commit", "2" * 40,
        "--approval-comment-id", "501",
    ]


def build(repo: Path):
    config_path = repo / "scripts/enforcement/bypass-control-plane.json"
    config = json.loads(config_path.read_text())
    config["qualification"] = {"status": "qualified", "live_control_repository_qualification": True}
    config["control_repository"].update({"full_name": "yotamfried-ux/eos-bypass-control", "id": 777})
    config["issues"] = {"approval": 41, "consumption": 42}
    config["consumer"]["workflow_id"] = 101
    config["finalizer"]["workflow_id"] = 102
    config_path.write_text(json.dumps(config, indent=2, sort_keys=True) + "\n")
    policy_digest = hashlib.sha256((repo / "scripts/enforcement/bypass-policy.tsv").read_bytes()).hexdigest()
    approval = {
        "schema": "eos-bypass-approval/v1",
        "protected_repository": "yotamfried-ux/Engineering-OS",
        "protected_repository_id": 1268851602,
        "control_repository": "yotamfried-ux/eos-bypass-control",
        "control_repository_id": 777,
        "approval_issue_id": 41,
        "approval_comment_id": 501,
        "approval_created_at": "2026-07-26T20:00:00Z",
        "issuer_login": "maintainer-user",
        "issuer_user_id": 88,
        "issuer_type": "User",
        "issuer_role": "maintain",
        "reason": "Permit this exact bounded command after a verified false positive.",
        "expires_at": "2026-07-26T21:00:00Z",
        "gate": "workflow",
        "bypass": "EOS_BYPASS_ENTRY",
        "action": "allow-work-command-before-plan",
        "surface": "PreToolUse",
        "target": "command:pytest",
        "target_fingerprint": "1" * 64,
        "target_commit": "2" * 40,
        "nonce": "nonce-0123456789abcdef0123456789abcdef",
        "policy_sha256": policy_digest,
        "consumer_workflow_id": 101,
        "consumer_workflow_path": ".github/workflows/consume-bypass.yml",
        "finalizer_workflow_id": 102,
        "finalizer_workflow_path": ".github/workflows/finalize-bypass.yml",
        "control_default_branch_sha": "3" * 40,
    }
    claim = {
        "schema": "eos-bypass-consumption/v1",
        "approval_digest": canonical_digest(approval),
        "protected_repository": approval["protected_repository"],
        "protected_repository_id": approval["protected_repository_id"],
        "control_repository": approval["control_repository"],
        "control_repository_id": approval["control_repository_id"],
        "approval_issue_id": 41,
        "approval_comment_id": 501,
        "consumption_issue_id": 42,
        "gate": approval["gate"], "bypass": approval["bypass"],
        "action": approval["action"], "surface": approval["surface"],
        "target": approval["target"], "target_fingerprint": approval["target_fingerprint"],
        "target_commit": approval["target_commit"], "nonce": approval["nonce"],
        "policy_sha256": approval["policy_sha256"],
        "consumer_workflow_id": 101,
        "consumer_workflow_path": approval["consumer_workflow_path"],
        "consumer_default_branch_sha": "3" * 40,
        "run_id": 601,
        "run_attempt": 1,
        "actor": "maintainer-user",
        "triggering_actor": "maintainer-user",
        "event": "workflow_dispatch",
    }
    marker = {
        "schema": "eos-bypass-marker/v1",
        "approval_digest": canonical_digest(approval),
        "claim_digest": canonical_digest(claim),
        "claim_comment_id": 701,
        "claim_created_at": "2026-07-26T20:05:00Z",
        "protected_repository": approval["protected_repository"],
        "protected_repository_id": approval["protected_repository_id"],
        "control_repository": approval["control_repository"],
        "control_repository_id": approval["control_repository_id"],
        "approval_issue_id": 41,
        "approval_comment_id": 501,
        "consumption_issue_id": 42,
        "gate": approval["gate"], "bypass": approval["bypass"],
        "action": approval["action"], "surface": approval["surface"],
        "target": approval["target"], "target_fingerprint": approval["target_fingerprint"],
        "target_commit": approval["target_commit"], "nonce": approval["nonce"],
        "policy_sha256": approval["policy_sha256"],
        "consumer_workflow_id": 101,
        "consumer_workflow_path": approval["consumer_workflow_path"],
        "consumer_default_branch_sha": "3" * 40,
        "consumer_run_id": 601,
        "finalizer_workflow_id": 102,
        "finalizer_workflow_path": approval["finalizer_workflow_path"],
        "finalizer_default_branch_sha": "4" * 40,
        "finalizer_run_id": 602,
        "finalizer_run_attempt": 1,
        "finalizer_actor": "github-actions[bot]",
        "finalizer_triggering_actor": "maintainer-user",
        "finalizer_event": "workflow_run",
    }
    approval_comment = {
        "id": 501,
        "body": json.dumps(approval, sort_keys=True, separators=(",", ":")),
        "created_at": approval["approval_created_at"],
        "updated_at": approval["approval_created_at"],
        "issue_url": "https://api.github.com/repos/yotamfried-ux/eos-bypass-control/issues/41",
        "repository_url": "https://api.github.com/repos/yotamfried-ux/eos-bypass-control",
        "user": {"login": "maintainer-user", "id": 88, "type": "User"},
    }
    claim_comment = {
        "id": 701,
        "body": json.dumps(claim, sort_keys=True, separators=(",", ":")),
        "created_at": "2026-07-26T20:05:00Z",
        "updated_at": "2026-07-26T20:05:00Z",
        "issue_url": "https://api.github.com/repos/yotamfried-ux/eos-bypass-control/issues/41",
        "repository_url": "https://api.github.com/repos/yotamfried-ux/eos-bypass-control",
        "user": {"login": "github-actions[bot]", "id": 41898282, "type": "Bot"},
    }
    marker_comment = {
        "id": 702,
        "body": json.dumps(marker, sort_keys=True, separators=(",", ":")),
        "created_at": "2026-07-26T20:10:00Z",
        "updated_at": "2026-07-26T20:10:00Z",
        "issue_url": "https://api.github.com/repos/yotamfried-ux/eos-bypass-control/issues/42",
        "repository_url": "https://api.github.com/repos/yotamfried-ux/eos-bypass-control",
        "user": {"login": "github-actions[bot]", "id": 41898282, "type": "Bot"},
    }
    fixture = {
        "repositories": {
            "yotamfried-ux/Engineering-OS": {"id": 1268851602, "full_name": "yotamfried-ux/Engineering-OS", "private": False},
            "yotamfried-ux/eos-bypass-control": {"id": 777, "full_name": "yotamfried-ux/eos-bypass-control", "private": True},
        },
        "comments": {"501": approval_comment},
        "permissions": {"yotamfried-ux/Engineering-OS:maintainer-user": {"role_name": "maintain"}},
        "workflows": {
            "yotamfried-ux/eos-bypass-control:101": {"id": 101, "path": ".github/workflows/consume-bypass.yml"},
            "yotamfried-ux/eos-bypass-control:102": {"id": 102, "path": ".github/workflows/finalize-bypass.yml"},
        },
        "runs": {
            "yotamfried-ux/eos-bypass-control:601": {
                "id": 601, "run_attempt": 1, "head_sha": "3" * 40, "head_branch": "main",
                "event": "workflow_dispatch", "status": "completed", "conclusion": "success",
                "workflow_id": 101, "path": ".github/workflows/consume-bypass.yml",
                "actor": {"login": "maintainer-user"}, "triggering_actor": {"login": "maintainer-user"},
                "repository": {"id": 777},
            },
            "yotamfried-ux/eos-bypass-control:602": {
                "id": 602, "run_attempt": 1, "head_sha": "4" * 40, "head_branch": "main",
                "event": "workflow_run", "status": "completed", "conclusion": "success",
                "workflow_id": 102, "path": ".github/workflows/finalize-bypass.yml",
                "actor": {"login": "github-actions[bot]"}, "triggering_actor": {"login": "maintainer-user"},
                "repository": {"id": 777},
            },
        },
        "issue_comments": {
            "yotamfried-ux/eos-bypass-control:41": [approval_comment, claim_comment],
            "yotamfried-ux/eos-bypass-control:42": [marker_comment],
        },
        "created_comment_user": {"login": "github-actions[bot]", "id": 41898282, "type": "Bot"},
        "created_comment_at": "2026-07-26T20:06:00Z",
    }
    return fixture


def expect_validation_failure(repo: Path, fixture: dict):
    command(repo, "validate-bypass-approval.py", fixture, common_args(), expect=1)


def main():
    with tempfile.TemporaryDirectory() as td:
        repo = Path(td) / "repo"
        shutil.copytree(ROOT, repo, ignore=shutil.ignore_patterns(".git", "__pycache__", ".claude/.evidence"))
        fixture = build(repo)

        blocked = command(repo, "validate-bypass-approval.py", fixture, common_args("approval"), expect=1, test_mode=False)
        if "test-only provider/time overrides are disabled" not in blocked.stderr:
            raise AssertionError(f"production fixture/time override did not fail for the intended reason: {blocked.stderr}")

        command(repo, "validate-bypass-approval.py", fixture, common_args("approval"))
        command(repo, "validate-bypass-approval.py", fixture, common_args("claimed"))
        command(repo, "validate-bypass-approval.py", fixture, common_args("consumed"))

        no_claim = deepcopy(fixture)
        no_claim["issue_comments"]["yotamfried-ux/eos-bypass-control:41"] = [no_claim["issue_comments"]["yotamfried-ux/eos-bypass-control:41"][0]]
        no_claim["issue_comments"]["yotamfried-ux/eos-bypass-control:42"] = []
        command(repo, "consume-bypass-approval.py", no_claim, [
            *common_args("approval"),
            "--consumer-default-branch-sha", "3" * 40,
            "--run-id", "601", "--run-attempt", "1",
            "--actor", "maintainer-user", "--triggering-actor", "maintainer-user",
            "--event", "workflow_dispatch",
        ])
        command(repo, "consume-bypass-approval.py", fixture, [
            *common_args("approval"),
            "--consumer-default-branch-sha", "3" * 40,
            "--run-id", "601", "--run-attempt", "1",
            "--actor", "maintainer-user", "--triggering-actor", "maintainer-user",
            "--event", "workflow_dispatch",
        ], expect=1)

        no_marker = deepcopy(fixture)
        no_marker["issue_comments"]["yotamfried-ux/eos-bypass-control:42"] = []
        command(repo, "finalize-bypass-consumption.py", no_marker, [
            "--consumer-run-id", "601", "--finalizer-default-branch-sha", "4" * 40,
            "--finalizer-run-id", "602", "--finalizer-run-attempt", "1",
            "--finalizer-actor", "github-actions[bot]",
            "--finalizer-triggering-actor", "maintainer-user",
            "--finalizer-event", "workflow_run",
        ])
        command(repo, "finalize-bypass-consumption.py", fixture, [
            "--consumer-run-id", "601", "--finalizer-default-branch-sha", "4" * 40,
            "--finalizer-run-id", "602", "--finalizer-run-attempt", "1",
            "--finalizer-actor", "github-actions[bot]",
            "--finalizer-triggering-actor", "maintainer-user",
            "--finalizer-event", "workflow_run",
        ], expect=1)

        # Core fail-closed mutations.
        mutations = []
        duplicate_claim = deepcopy(fixture)
        duplicate_claim["issue_comments"]["yotamfried-ux/eos-bypass-control:41"].append(deepcopy(duplicate_claim["issue_comments"]["yotamfried-ux/eos-bypass-control:41"][1]))
        mutations.append(duplicate_claim)
        duplicate_marker = deepcopy(fixture)
        duplicate_marker["issue_comments"]["yotamfried-ux/eos-bypass-control:42"].append(deepcopy(duplicate_marker["issue_comments"]["yotamfried-ux/eos-bypass-control:42"][0]))
        mutations.append(duplicate_marker)
        missing_claim = deepcopy(fixture); missing_claim["issue_comments"]["yotamfried-ux/eos-bypass-control:41"] = [missing_claim["issue_comments"]["yotamfried-ux/eos-bypass-control:41"][0]]; mutations.append(missing_claim)
        missing_marker = deepcopy(fixture); missing_marker["issue_comments"]["yotamfried-ux/eos-bypass-control:42"] = []; mutations.append(missing_marker)
        edited_approval = deepcopy(fixture); edited_approval["comments"]["501"]["updated_at"] = "2026-07-26T20:01:00Z"; mutations.append(edited_approval)
        edited_claim = deepcopy(fixture); edited_claim["issue_comments"]["yotamfried-ux/eos-bypass-control:41"][1]["updated_at"] = "2026-07-26T20:06:00Z"; mutations.append(edited_claim)
        edited_marker = deepcopy(fixture); edited_marker["issue_comments"]["yotamfried-ux/eos-bypass-control:42"][0]["updated_at"] = "2026-07-26T20:11:00Z"; mutations.append(edited_marker)
        bot = deepcopy(fixture); bot["comments"]["501"]["user"]["type"] = "Bot"; mutations.append(bot)
        write_role = deepcopy(fixture); write_role["permissions"]["yotamfried-ux/Engineering-OS:maintainer-user"] = {"role_name": "write"}; mutations.append(write_role)
        wrong_writer = deepcopy(fixture); wrong_writer["issue_comments"]["yotamfried-ux/eos-bypass-control:41"][1]["user"]["login"] = "maintainer-user"; mutations.append(wrong_writer)
        rerun = deepcopy(fixture); rerun["runs"]["yotamfried-ux/eos-bypass-control:601"]["run_attempt"] = 2; mutations.append(rerun)
        failed = deepcopy(fixture); failed["runs"]["yotamfried-ux/eos-bypass-control:601"]["conclusion"] = "failure"; mutations.append(failed)
        cancelled = deepcopy(fixture); cancelled["runs"]["yotamfried-ux/eos-bypass-control:602"]["conclusion"] = "cancelled"; mutations.append(cancelled)
        wrong_event = deepcopy(fixture); wrong_event["runs"]["yotamfried-ux/eos-bypass-control:602"]["event"] = "push"; mutations.append(wrong_event)
        wrong_sha = deepcopy(fixture); wrong_sha["runs"]["yotamfried-ux/eos-bypass-control:601"]["head_sha"] = "5" * 40; mutations.append(wrong_sha)
        wrong_actor = deepcopy(fixture); wrong_actor["runs"]["yotamfried-ux/eos-bypass-control:601"]["actor"]["login"] = "other"; mutations.append(wrong_actor)
        wrong_trigger = deepcopy(fixture); wrong_trigger["runs"]["yotamfried-ux/eos-bypass-control:601"]["triggering_actor"]["login"] = "other"; mutations.append(wrong_trigger)
        wrong_repo_id = deepcopy(fixture); wrong_repo_id["repositories"]["yotamfried-ux/eos-bypass-control"]["id"] = 778; mutations.append(wrong_repo_id)
        wrong_workflow = deepcopy(fixture); wrong_workflow["workflows"]["yotamfried-ux/eos-bypass-control:101"]["path"] = ".github/workflows/other.yml"; mutations.append(wrong_workflow)
        provider_error = deepcopy(fixture); del provider_error["runs"]["yotamfried-ux/eos-bypass-control:601"]; mutations.append(provider_error)
        malformed = deepcopy(fixture); malformed["comments"]["501"]["body"] = '{"schema":"eos-bypass-approval/v1"'; mutations.append(malformed)
        malformed_claim = deepcopy(fixture); malformed_claim["issue_comments"]["yotamfried-ux/eos-bypass-control:41"][1]["body"] = '{"schema":"eos-bypass-consumption/v1"'; mutations.append(malformed_claim)
        malformed_marker = deepcopy(fixture); malformed_marker["issue_comments"]["yotamfried-ux/eos-bypass-control:42"][0]["body"] = '{"schema":"eos-bypass-marker/v1"'; mutations.append(malformed_marker)
        conflicting_marker = deepcopy(fixture)
        conflict_body = json.loads(conflicting_marker["issue_comments"]["yotamfried-ux/eos-bypass-control:42"][0]["body"]); conflict_body["claim_digest"] = "f" * 64
        conflicting_marker["issue_comments"]["yotamfried-ux/eos-bypass-control:42"][0]["body"] = json.dumps(conflict_body, sort_keys=True, separators=(",", ":")); mutations.append(conflicting_marker)
        ambiguous_comment = deepcopy(fixture); ambiguous_comment["issue_comments"]["yotamfried-ux/eos-bypass-control:41"].append("ambiguous-provider-value"); mutations.append(ambiguous_comment)
        wrong_marker_writer = deepcopy(fixture); wrong_marker_writer["issue_comments"]["yotamfried-ux/eos-bypass-control:42"][0]["user"]["login"] = "maintainer-user"; mutations.append(wrong_marker_writer)
        finalizer_rerun = deepcopy(fixture); finalizer_rerun["runs"]["yotamfried-ux/eos-bypass-control:602"]["run_attempt"] = 2; mutations.append(finalizer_rerun)
        generic_reason = deepcopy(fixture)
        body = json.loads(generic_reason["comments"]["501"]["body"]); body["reason"] = "approved"; generic_reason["comments"]["501"]["body"] = json.dumps(body, sort_keys=True, separators=(",", ":")); mutations.append(generic_reason)
        for item in mutations:
            expect_validation_failure(repo, item)

        # Runtime/control and protected-repository credentials are intentionally distinct.
        validator_path = repo / "scripts/enforcement/validate-bypass-approval.py"
        spec = importlib.util.spec_from_file_location("credential_test_validator", validator_path)
        if spec is None or spec.loader is None:
            raise AssertionError("cannot load validator for credential test")
        validator_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(validator_module)
        config = json.loads((repo / "scripts/enforcement/bypass-control-plane.json").read_text())
        args = argparse.Namespace(provider_fixture=None, timeout=10.0)
        with mock.patch.dict(os.environ, {"EOS_BYPASS_PROVIDER_TOKEN": "runtime-only"}, clear=True):
            try:
                validator_module.make_provider(args, config)
                raise AssertionError("runtime token was reused as protected-repository verifier credential")
            except validator_module.ProviderError:
                pass
        with mock.patch.dict(os.environ, {"EOS_BYPASS_PROVIDER_TOKEN": "runtime-control", "GITHUB_TOKEN_READ_ONLY": "protected-read"}, clear=True):
            separated = validator_module.make_provider(args, config)
            if separated.control_token != "runtime-control" or separated.protected_token != "protected-read":
                raise AssertionError("runtime/protected credential separation was not preserved")

        # Lowercase Link pagination and timeout are fail-closed.
        sys_path = str(repo / "scripts/enforcement/lib")
        import sys
        sys.path.insert(0, sys_path)
        from github_provider import GitHubProvider, ProviderError, Response
        provider = GitHubProvider("c", "p", control_repository="o/c", protected_repository="o/p")
        with mock.patch.object(provider, "_request", return_value=Response(200, {"link": '<x>; rel="next"'}, [])):
            try:
                provider.issue_comments("o/c", 1)
                raise AssertionError("lowercase Link pagination was not rejected")
            except ProviderError:
                pass
        with mock.patch("urllib.request.urlopen", side_effect=socket.timeout("timeout")):
            try:
                provider.repository("o/c")
                raise AssertionError("provider timeout was not rejected")
            except ProviderError:
                pass

    print("test-bypass-provider-validation: PASS")


if __name__ == "__main__":
    main()
