#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

python3 - "$ROOT" <<'PY'
from __future__ import annotations

import importlib.util
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
    shutil.copytree(
        root,
        repo,
        ignore=shutil.ignore_patterns(".git", "__pycache__", ".claude/.evidence"),
    )
    fixture = helper.build(repo)

    helper.command(
        repo,
        "validate-bypass-approval.py",
        fixture,
        helper.common_args("consumed"),
        expect=0,
    )

    # Security requirement: one durable approval/claim/marker chain may authorize
    # the protected operation once only. Re-reading the identical provider state
    # for the identical request must not return authorization a second time,
    # including while the approval is still inside its expiry window.
    helper.command(
        repo,
        "validate-bypass-approval.py",
        fixture,
        helper.common_args("consumed"),
        expect=1,
    )

print("PASS: identical approval/request cannot authorize twice")
PY
