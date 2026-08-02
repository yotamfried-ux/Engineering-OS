#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

python3 - "$ROOT" <<'PY'
from __future__ import annotations

from copy import deepcopy
from datetime import datetime, timezone
import importlib.util
import json
from pathlib import Path
import shutil
import sys
import tempfile

root = Path(sys.argv[1])
helper_path = root / "scripts/enforcement/tests/test-bypass-provider-validation.py"
spec = importlib.util.spec_from_file_location("bypass_provider_test_helper", helper_path)
if spec is None or spec.loader is None:
    raise SystemExit("FAIL: cannot load provider validation test helper")
helper = importlib.util.module_from_spec(spec)
spec.loader.exec_module(helper)

with tempfile.TemporaryDirectory() as td:
    repo = Path(td) / "repo"
    shutil.copytree(root, repo, ignore=shutil.ignore_patterns(".git", "__pycache__", ".claude/.evidence"))
    fixture = helper.build(repo)

    second = deepcopy(fixture["deployment_responses"][0])
    second["id"] = 802
    fixture["deployment_responses"].append(second)
    failure_status = deepcopy(fixture["deployment_statuses"][f"{helper.CONTROL}:801"][0])
    failure_status.update({
        "id": 812,
        "state": "failure",
        "description": "eos-bypass-auth/v1 failure run=603 attempt=1",
        "deployment_url": f"https://api.github.com/repos/{helper.CONTROL}/deployments/802",
    })
    fixture["deployment_statuses"][f"{helper.CONTROL}:802"] = [failure_status]

    authorizer_path = repo / "scripts/enforcement/authorize-bypass-once.py"
    authorizer_spec = importlib.util.spec_from_file_location("one_shot_authorizer", authorizer_path)
    if authorizer_spec is None or authorizer_spec.loader is None:
        raise SystemExit("FAIL: cannot load one-shot authorizer")
    authorizer = importlib.util.module_from_spec(authorizer_spec)
    authorizer_spec.loader.exec_module(authorizer)

    config = json.loads((repo / "scripts/enforcement/bypass-control-plane.json").read_text())
    policy = authorizer.load_policy(repo / "scripts/enforcement/bypass-policy.tsv")
    provider = authorizer.FixtureProvider(fixture)
    expected = {
        "bypass": "EOS_BYPASS_ENTRY",
        "gate": "workflow",
        "action": "allow-work-command-before-plan",
        "surface": "PreToolUse",
        "target": "command:pytest",
        "target_fingerprint": "1" * 64,
        "target_commit": "2" * 40,
    }
    now = datetime(2026, 7, 26, 20, 30, tzinfo=timezone.utc)

    first = authorizer.authorize_once(
        provider,
        config=config,
        policy=policy,
        expected=expected,
        approval_comment_id=501,
        now=now,
        poll_timeout=2,
        poll_interval=0,
    )
    if first.get("authorized") is not True or first.get("deployment_id") != 801:
        raise AssertionError(f"first attempt did not authorize exactly once: {first}")

    try:
        authorizer.authorize_once(
            provider,
            config=config,
            policy=policy,
            expected=expected,
            approval_comment_id=501,
            now=now,
            poll_timeout=2,
            poll_interval=0,
        )
        raise AssertionError("identical replay unexpectedly authorized")
    except authorizer.ContractError as exc:
        if "denied" not in str(exc):
            raise AssertionError(f"replay failed for the wrong reason: {exc}") from exc

    if len(provider.created_deployments) != 2:
        raise AssertionError("each runtime invocation must create a fresh provider attempt")

print("PASS: one approval authorizes one fresh execution attempt only")
PY
