#!/usr/bin/env python3
from __future__ import annotations

from copy import deepcopy
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile
from unittest import mock

ROOT = Path(__file__).resolve().parents[3]
CONTROL = "yotamfried-ux/eos-bypass-control"
PROTECTED = "yotamfried-ux/Engineering-OS"
TRUSTED_SHA = "3" * 40


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
        "--repository", PROTECTED,
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
    config["control_repository"].update({"full_name": CONTROL, "id": 777, "trusted_default_branch_sha": TRUSTED_SHA})
    config["issues"] = {"approval": 41, "consumption": 42}
    config["consumer"]["workflow_id"] = 101
    config["finalizer"]["workflow_id"] = 102
    config_path.write_text(json.dumps(config, indent=2, sort_keys=True) + "\n")
    policy_digest = hashlib.sha256((repo / "scripts/enforcement/bypass-policy.tsv").read_bytes()).hexdigest()
    approval = {
        "schema": "eos-bypass-approval/v1",
        "protected_repository": PROTECTED,
        "protected_repository_id": 1268851602,
        "control_repository": CONTROL,
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
        "control_default_branch_sha": TRUSTED_SHA,
    }
    claim = {
        "schema": "eos-bypass-consumption/v1",
        "approval_digest": canonical_digest(approval),
        "protected_repository": PROTECTED,
        "protected_repository_id": 1268851602,
        "control_repository": CONTROL,
        "control_repository_id": 777,
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
        "consumer_default_branch_sha": TRUSTED_SHA,
        "run_id": 601, "run_attempt": 1,
        "actor": "runtime-app[bot]", "triggering_actor": "runtime-app[bot]",
        "event": "deployment",
    }
    marker = {
        "schema": "eos-bypass-marker/v1",
        "approval_digest": canonical_digest(approval),
        "claim_digest": canonical_digest(claim),
        "claim_comment_id": 701,
        "claim_created_at": "2026-07-26T20:05:00Z",
        "protected_repository": PROTECTED,
        "protected_repository_id": 1268851602,
        "control_repository": CONTROL,
        "control_repository_id": 777,
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
        "consumer_default_branch_sha": TRUSTED_SHA,
        "consumer_run_id": 601,
        "finalizer_workflow_id": 102,
        "finalizer_workflow_path": approval["finalizer_workflow_path"],
        "finalizer_default_branch_sha": "4" * 40,
        "finalizer_run_id": 602,
        "finalizer_run_attempt": 1,
        "finalizer_actor": "github-actions[bot]",
        "finalizer_triggering_actor": "runtime-app[bot]",
        "finalizer_event": "workflow_run",
    }
    authored_approval = {k: v for k, v in approval.items() if k not in ("approval_comment_id", "approval_created_at")}
    approval_comment = {
        "id": 501, "body": json.dumps(authored_approval, sort_keys=True, separators=(",", ":")),
        "created_at": approval["approval_created_at"], "updated_at": approval["approval_created_at"],
        "issue_url": f"https://api.github.com/repos/{CONTROL}/issues/41",
        "repository_url": f"https://api.github.com/repos/{CONTROL}",
        "user": {"login": "maintainer-user", "id": 88, "type": "User"},
    }
    claim_comment = {
        "id": 701, "body": json.dumps(claim, sort_keys=True, separators=(",", ":")),
        "created_at": "2026-07-26T20:05:00Z", "updated_at": "2026-07-26T20:05:00Z",
        "issue_url": f"https://api.github.com/repos/{CONTROL}/issues/42",
        "repository_url": f"https://api.github.com/repos/{CONTROL}",
        "user": {"login": "github-actions[bot]", "id": 41898282, "type": "Bot"},
    }
    marker_comment = {
        "id": 702, "body": json.dumps(marker, sort_keys=True, separators=(",", ":")),
        "created_at": "2026-07-26T20:10:00Z", "updated_at": "2026-07-26T20:10:00Z",
        "issue_url": f"https://api.github.com/repos/{CONTROL}/issues/42",
        "repository_url": f"https://api.github.com/repos/{CONTROL}",
        "user": {"login": "github-actions[bot]", "id": 41898282, "type": "Bot"},
    }
    attempt_payload = {
        "schema": "eos-bypass-authorization-attempt/v1",
        "approval_comment_id": 501,
        "approval_digest": canonical_digest(approval),
        "protected_repository": PROTECTED,
        "bypass": approval["bypass"], "gate": approval["gate"],
        "action": approval["action"], "surface": approval["surface"],
        "target": approval["target"], "target_fingerprint": approval["target_fingerprint"],
        "target_commit": approval["target_commit"], "policy_sha256": policy_digest,
    }
    deployment = {
        "id": 801, "task": "engineering-os:bypass-authorization", "environment": "engineering-os-bypass",
        "payload": attempt_payload, "sha": TRUSTED_SHA,
        "repository": {"id": 777, "full_name": CONTROL},
        "creator": {"login": "runtime-app[bot]", "id": 99001, "type": "Bot"},
    }
    status = {
        "id": 811, "state": "success", "description": "eos-bypass-auth/v1 success run=601 attempt=1",
        "environment": "engineering-os-bypass",
        "created_at": "2026-07-26T20:06:00Z", "updated_at": "2026-07-26T20:06:00Z",
        "deployment_url": f"https://api.github.com/repos/{CONTROL}/deployments/801",
        "repository_url": f"https://api.github.com/repos/{CONTROL}",
        "creator": {"login": "github-actions[bot]", "id": 41898282, "type": "Bot"},
    }
    return {
        "repositories": {
            PROTECTED: {"id": 1268851602, "full_name": PROTECTED, "private": False},
            CONTROL: {"id": 777, "full_name": CONTROL, "private": True},
        },
        "comments": {"501": approval_comment},
        "permissions": {f"{PROTECTED}:maintainer-user": {"role_name": "maintain"}},
        "workflows": {
            f"{CONTROL}:101": {"id": 101, "path": ".github/workflows/consume-bypass.yml"},
            f"{CONTROL}:102": {"id": 102, "path": ".github/workflows/finalize-bypass.yml"},
        },
        "runs": {
            f"{CONTROL}:601": {
                "id": 601, "run_attempt": 1, "head_sha": TRUSTED_SHA, "head_branch": "main",
                "event": "deployment", "status": "completed", "conclusion": "success",
                "workflow_id": 101, "path": ".github/workflows/consume-bypass.yml",
                "actor": {"login": "runtime-app[bot]"}, "triggering_actor": {"login": "runtime-app[bot]"},
                "repository": {"id": 777},
            },
            f"{CONTROL}:602": {
                "id": 602, "run_attempt": 1, "head_sha": "4" * 40, "head_branch": "main",
                "event": "workflow_run", "status": "completed", "conclusion": "success",
                "workflow_id": 102, "path": ".github/workflows/finalize-bypass.yml",
                "actor": {"login": "github-actions[bot]"}, "triggering_actor": {"login": "runtime-app[bot]"},
                "repository": {"id": 777},
            },
        },
        "issue_comments": {
            f"{CONTROL}:41": [approval_comment],
            f"{CONTROL}:42": [marker_comment, claim_comment],
        },
        "deployment_responses": [deployment],
        "deployment_statuses": {f"{CONTROL}:801": [status]},
        "created_comment_user": {"login": "github-actions[bot]", "id": 41898282, "type": "Bot"},
        "created_comment_at": "2026-07-26T20:06:00Z",
        "created_deployment_status_user": {"login": "github-actions[bot]", "id": 41898282, "type": "Bot"},
        "created_deployment_status_at": "2026-07-26T20:06:00Z",
    }


def expect_claim_failure(repo: Path, fixture: dict):
    command(repo, "validate-bypass-approval.py", fixture, common_args("claimed"), expect=1)


def consumed_failure(repo: Path, fixture: dict):
    return command(repo, "validate-bypass-approval.py", fixture, common_args("consumed"), expect=1)


def main():
    with tempfile.TemporaryDirectory() as td:
        repo = Path(td) / "repo"
        shutil.copytree(ROOT, repo, ignore=shutil.ignore_patterns(".git", "__pycache__", ".claude/.evidence"))
        fixture = build(repo)

        blocked = command(repo, "validate-bypass-approval.py", fixture, common_args("approval"), expect=1, test_mode=False)
        assert "test-only provider/time overrides are disabled" in blocked.stderr

        command(repo, "validate-bypass-approval.py", fixture, common_args("approval"))
        command(repo, "validate-bypass-approval.py", fixture, common_args("claimed"))
        authorized = command(repo, "validate-bypass-approval.py", fixture, common_args("consumed"))
        assert json.loads(authorized.stdout)["deployment_id"] == 801

        no_claim = deepcopy(fixture)
        no_claim["issue_comments"][f"{CONTROL}:42"] = []
        command(repo, "consume-bypass-approval.py", no_claim, [
            *common_args("approval"),
            "--consumer-default-branch-sha", TRUSTED_SHA,
            "--run-id", "601", "--run-attempt", "1",
            "--actor", "runtime-app[bot]", "--triggering-actor", "runtime-app[bot]",
            "--event", "deployment", "--authorization-deployment-id", "801",
        ])
        command(repo, "consume-bypass-approval.py", fixture, [
            *common_args("approval"),
            "--consumer-default-branch-sha", TRUSTED_SHA,
            "--run-id", "601", "--run-attempt", "1",
            "--actor", "runtime-app[bot]", "--triggering-actor", "runtime-app[bot]",
            "--event", "deployment", "--authorization-deployment-id", "801",
        ], expect=1)

        no_marker = deepcopy(fixture)
        no_marker["issue_comments"][f"{CONTROL}:42"] = [no_marker["issue_comments"][f"{CONTROL}:42"][1]]
        finalize_args = [
            "--consumer-run-id", "601", "--finalizer-default-branch-sha", "4" * 40,
            "--finalizer-run-id", "602", "--finalizer-run-attempt", "1",
            "--finalizer-actor", "github-actions[bot]",
            "--finalizer-triggering-actor", "runtime-app[bot]", "--finalizer-event", "workflow_run",
        ]
        command(repo, "finalize-bypass-consumption.py", no_marker, finalize_args)
        command(repo, "finalize-bypass-consumption.py", fixture, finalize_args, expect=1)

        mutations = []
        duplicate_claim = deepcopy(fixture); duplicate_claim["issue_comments"][f"{CONTROL}:42"].append(deepcopy(duplicate_claim["issue_comments"][f"{CONTROL}:42"][1])); mutations.append(duplicate_claim)
        missing_claim = deepcopy(fixture); missing_claim["issue_comments"][f"{CONTROL}:42"] = [missing_claim["issue_comments"][f"{CONTROL}:42"][0]]; mutations.append(missing_claim)
        edited_approval = deepcopy(fixture); edited_approval["comments"]["501"]["updated_at"] = "2026-07-26T20:01:00Z"; mutations.append(edited_approval)
        edited_claim = deepcopy(fixture); edited_claim["issue_comments"][f"{CONTROL}:42"][1]["updated_at"] = "2026-07-26T20:06:00Z"; mutations.append(edited_claim)
        bot = deepcopy(fixture); bot["comments"]["501"]["user"]["type"] = "Bot"; mutations.append(bot)
        write_role = deepcopy(fixture); write_role["permissions"][f"{PROTECTED}:maintainer-user"] = {"role_name": "write"}; mutations.append(write_role)
        wrong_writer = deepcopy(fixture); wrong_writer["issue_comments"][f"{CONTROL}:42"][1]["user"]["id"] = 999; mutations.append(wrong_writer)
        rerun = deepcopy(fixture); rerun["runs"][f"{CONTROL}:601"]["run_attempt"] = 2; mutations.append(rerun)
        failed = deepcopy(fixture); failed["runs"][f"{CONTROL}:601"]["conclusion"] = "failure"; mutations.append(failed)
        wrong_sha = deepcopy(fixture); wrong_sha["runs"][f"{CONTROL}:601"]["head_sha"] = "5" * 40; mutations.append(wrong_sha)
        wrong_actor = deepcopy(fixture); wrong_actor["runs"][f"{CONTROL}:601"]["actor"]["login"] = "other"; mutations.append(wrong_actor)
        wrong_repo_id = deepcopy(fixture); wrong_repo_id["repositories"][CONTROL]["id"] = 778; mutations.append(wrong_repo_id)
        wrong_workflow = deepcopy(fixture); wrong_workflow["workflows"][f"{CONTROL}:101"]["path"] = ".github/workflows/other.yml"; mutations.append(wrong_workflow)
        provider_error = deepcopy(fixture); del provider_error["runs"][f"{CONTROL}:601"]; mutations.append(provider_error)
        malformed = deepcopy(fixture); malformed["comments"]["501"]["body"] = '{"schema":"eos-bypass-approval/v1"'; mutations.append(malformed)
        malformed_claim = deepcopy(fixture); malformed_claim["issue_comments"][f"{CONTROL}:42"][1]["body"] = '{"schema":"eos-bypass-consumption/v1"'; mutations.append(malformed_claim)
        ambiguous_comment = deepcopy(fixture); ambiguous_comment["issue_comments"][f"{CONTROL}:42"].append("ambiguous-provider-value"); mutations.append(ambiguous_comment)
        generic_reason = deepcopy(fixture); body = json.loads(generic_reason["comments"]["501"]["body"]); body["reason"] = "approved"; generic_reason["comments"]["501"]["body"] = json.dumps(body, sort_keys=True, separators=(",", ":")); mutations.append(generic_reason)
        for item in mutations:
            expect_claim_failure(repo, item)

        # Fresh-attempt provider binding: every canonical status must be trusted,
        # unambiguous, immutable, and bound to a successful first-attempt run.
        wrong_status_writer = deepcopy(fixture); wrong_status_writer["deployment_statuses"][f"{CONTROL}:801"][0]["creator"]["id"] = 99001; consumed_failure(repo, wrong_status_writer)
        failure_status = deepcopy(fixture); failure_status["deployment_statuses"][f"{CONTROL}:801"][0].update({"state": "failure", "description": "eos-bypass-auth/v1 failure run=601 attempt=1"}); consumed_failure(repo, failure_status)
        malformed_status = deepcopy(fixture); malformed_status["deployment_statuses"][f"{CONTROL}:801"][0]["description"] = "eos-bypass-auth/v1 ???"; consumed_failure(repo, malformed_status)
        edited_status = deepcopy(fixture); edited_status["deployment_statuses"][f"{CONTROL}:801"][0]["updated_at"] = "2026-07-26T20:07:00Z"; consumed_failure(repo, edited_status)
        duplicate_status = deepcopy(fixture); duplicate_status["deployment_statuses"][f"{CONTROL}:801"].append(deepcopy(duplicate_status["deployment_statuses"][f"{CONTROL}:801"][0])); consumed_failure(repo, duplicate_status)
        bad_deployment_sha = deepcopy(fixture); bad_deployment_sha["deployment_responses"][0]["sha"] = "5" * 40; consumed_failure(repo, bad_deployment_sha)
        bad_event = deepcopy(fixture); bad_event["runs"][f"{CONTROL}:601"]["event"] = "workflow_dispatch"; consumed_failure(repo, bad_event)
        bad_attempt = deepcopy(fixture); bad_attempt["deployment_statuses"][f"{CONTROL}:801"][0]["description"] = "eos-bypass-auth/v1 success run=601 attempt=2"; consumed_failure(repo, bad_attempt)

        validator_path = repo / "scripts/enforcement/validate-bypass-approval.py"
        spec = importlib.util.spec_from_file_location("credential_test_validator", validator_path)
        assert spec is not None and spec.loader is not None
        validator_module = importlib.util.module_from_spec(spec); spec.loader.exec_module(validator_module)
        config = json.loads((repo / "scripts/enforcement/bypass-control-plane.json").read_text())
        args = argparse.Namespace(provider_fixture=None, timeout=10.0)
        with mock.patch.dict(os.environ, {"EOS_BYPASS_PROVIDER_TOKEN": "runtime-only"}, clear=True):
            try:
                validator_module.make_provider(args, config); raise AssertionError("runtime token was reused as protected verifier")
            except validator_module.ProviderError:
                pass
        with mock.patch.dict(os.environ, {"EOS_BYPASS_PROVIDER_TOKEN": "runtime-control", "GITHUB_TOKEN_READ_ONLY": "protected-read"}, clear=True):
            separated = validator_module.make_provider(args, config)
            assert separated.control_token == "runtime-control" and separated.protected_token == "protected-read"

        import sys
        sys.path.insert(0, str(repo / "scripts/enforcement/lib"))
        from github_provider import GitHubProvider, ProviderError, Response
        provider = GitHubProvider("c", "p", control_repository="o/c", protected_repository="o/p")
        pages = [Response(200, {"link": '<x>; rel="next"'}, [{"id": 1}]), Response(200, {}, [{"id": 2}])]
        with mock.patch.object(provider, "_request", side_effect=pages):
            assert [x["id"] for x in provider.issue_comments("o/c", 1)] == [1, 2]
        with mock.patch.object(provider, "_request", return_value=Response(200, {"link": '<x>; rel="next"'}, [])):
            try:
                provider.issue_comments("o/c", 1); raise AssertionError("unbounded pagination accepted")
            except ProviderError:
                pass
        for bad in ("1%2F..%2F..", 1.0, True, 0, -1):
            try:
                provider.issue_comment("o/c", bad); raise AssertionError(f"bad path id accepted: {bad!r}")
            except ProviderError:
                pass
        with mock.patch("urllib.request.OpenerDirector.open", side_effect=socket.timeout("timeout")):
            try:
                provider.repository("o/c"); raise AssertionError("timeout accepted")
            except ProviderError:
                pass
        from github_provider import _NoRedirect
        try:
            _NoRedirect().redirect_request(None, None, 302, "Found", {}, "https://evil.example/x"); raise AssertionError("redirect accepted")
        except ProviderError:
            pass

        for field, value in (("approval_comment_id", 501), ("approval_created_at", "2026-07-26T20:00:00Z")):
            self_ref = deepcopy(fixture); body = json.loads(self_ref["comments"]["501"]["body"]); body[field] = value; self_ref["comments"]["501"]["body"] = json.dumps(body, sort_keys=True, separators=(",", ":"))
            failed_cmd = command(repo, "validate-bypass-approval.py", self_ref, common_args("approval"), expect=1)
            assert "authored approval" in failed_cmd.stderr

        wrong_target = deepcopy(fixture); body = json.loads(wrong_target["comments"]["501"]["body"]); body["target"] = "staged-tree:deadbeef"; wrong_target["comments"]["501"]["body"] = json.dumps(body, sort_keys=True, separators=(",", ":"))
        fail_target = command(repo, "validate-bypass-approval.py", wrong_target, [*common_args("approval")[:-2], "--target", "staged-tree:deadbeef", "--approval-comment-id", "501"], expect=1)
        assert "target_type" in fail_target.stderr

        escaped_key = deepcopy(fixture); claim_ref = escaped_key["issue_comments"][f"{CONTROL}:42"][1]; claim_ref["body"] = claim_ref["body"].replace('"schema":', '"\\u0073chema":', 1)
        command(repo, "validate-bypass-approval.py", escaped_key, common_args("claimed"))

        misplaced = deepcopy(fixture); ledger = misplaced["issue_comments"]; stray = deepcopy(ledger[f"{CONTROL}:42"][1]); stray["issue_url"] = f"https://api.github.com/repos/{CONTROL}/issues/41"; ledger[f"{CONTROL}:42"] = [ledger[f"{CONTROL}:42"][0]]; ledger[f"{CONTROL}:41"].append(stray)
        wrong_ledger = command(repo, "validate-bypass-approval.py", misplaced, common_args("claimed"), expect=1)
        assert "found 0" in wrong_ledger.stderr

    print("test-bypass-provider-validation: PASS")


if __name__ == "__main__":
    main()
