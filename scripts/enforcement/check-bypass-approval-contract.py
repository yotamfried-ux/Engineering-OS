#!/usr/bin/env python3
"""Static contract checker for provider-verified enforcement bypasses."""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts/enforcement/lib"))
from bypass_contract import ContractError, load_json, load_policy, validate_control_config  # noqa: E402

BYPASS_RE = re.compile(r"\bEOS_BYPASS_[A-Z0-9_]+\b")
FALLBACK_RE = re.compile(r"(?:function\s+)?bypass_active\s*(?:\(\s*\))?\s*\{")
DIRECT_TRUTHY_RE = re.compile(
    r"(?:case\s+[^\n]*|\[\[?[^\n]*|\btest\s+[^\n]*)"
    r"\$\{?EOS_BYPASS_[A-Z0-9_]+(?:[^\n}]*)?"
)
OVERRIDE_RE = re.compile(r"EOS_(?:BYPASS_)?(?:VALIDATOR|POLICY|CONTROL_PLANE|PROVIDER)_PATH")
TAG_RE = re.compile(r"(?:git\s+tag|refs/tags|git\s+push[^\n]*--tags|git\s+update-ref\s+refs/tags)", re.I)
SCAN_SUFFIXES = {".sh", ".py", ".yml", ".yaml"}
SCAN_ROOTS = ("scripts/enforcement", "scripts/hooks", ".github/workflows", "templates")
INTERNAL_BYPASS_ENV = {
    "EOS_BYPASS_VALIDATOR_PATH", "EOS_BYPASS_POLICY_PATH",
    "EOS_BYPASS_CONTROL_PLANE_PATH", "EOS_BYPASS_PROVIDER_PATH",
    "EOS_BYPASS_PROVIDER_TOKEN",
}

MASTER_BYPASSES = {
    "EOS_BYPASS_WORKFLOW", "EOS_BYPASS_RUNTIME_EVIDENCE", "EOS_BYPASS_GIT",
    "EOS_BYPASS_CONNECTOR", "EOS_BYPASS_SKILL", "EOS_BYPASS_QUALITY",
    "EOS_BYPASS_DEBUG", "EOS_BYPASS_LEARNING", "EOS_BYPASS_RESOURCE",
    "EOS_BYPASS_TESTS", "EOS_BYPASS_DOC",
}


def iter_runtime_files(root: Path):
    for rel_root in SCAN_ROOTS:
        base = root / rel_root
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if not path.is_file() or path.suffix not in SCAN_SUFFIXES:
                continue
            rel = path.relative_to(root)
            if "tests" in rel.parts or path.name == "check-bypass-approval-contract.py":
                continue
            yield path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--strict-runtime", action="store_true", help="also reject migration fallbacks and direct env authorization")
    args = parser.parse_args()
    root = args.root.resolve()
    errors: list[str] = []
    try:
        policy_path = root / "scripts/enforcement/bypass-policy.tsv"
        config_path = root / "scripts/enforcement/bypass-control-plane.json"
        policy = load_policy(policy_path)
        validate_control_config(load_json(config_path), require_qualified=False)
    except ContractError as exc:
        print(f"bypass-contract: FAIL: {exc}", file=sys.stderr)
        return 1

    discovered: set[str] = set()
    for path in iter_runtime_files(root):
        text = path.read_text(encoding="utf-8", errors="replace")
        rel = path.relative_to(root)
        discovered.update(name for name in BYPASS_RE.findall(text) if name != "EOS_BYPASS_X" and name not in INTERNAL_BYPASS_ENV)
        if args.strict_runtime:
            if path.name != "evidence.sh" and FALLBACK_RE.search(text):
                errors.append(f"{rel}: local bypass_active fallback is forbidden")
            if DIRECT_TRUTHY_RE.search(text):
                errors.append(f"{rel}: direct environment authorization is forbidden")
            if path.name != "evidence.sh" and OVERRIDE_RE.search(text):
                errors.append(f"{rel}: validator/policy/control-plane path override is forbidden")
            if TAG_RE.search(text) and "bypass" in text.lower():
                errors.append(f"{rel}: mutable Git-tag bypass consumption is forbidden")
    missing = sorted(discovered - set(policy))
    unused = sorted(set(policy) - discovered)
    if missing:
        errors.append(f"policy is missing runtime bypasses: {', '.join(missing)}")
    # An unused policy entry is a stale authorization surface and must be removed.
    if unused:
        errors.append(f"policy has unused bypasses: {', '.join(unused)}")
    masters = sorted(name for name, entry in policy.items() if entry.is_master)
    wrong_masters = sorted(name for name in MASTER_BYPASSES if name not in policy or not policy[name].is_master)
    unexpected_masters = sorted(set(masters) - MASTER_BYPASSES)
    if wrong_masters:
        errors.append(f"canonical master bypasses are not disabled: {', '.join(wrong_masters)}")
    if unexpected_masters:
        errors.append(f"unexpected master-disabled entries: {', '.join(unexpected_masters)}")
    policy_digest = hashlib.sha256((root / "scripts/enforcement/bypass-policy.tsv").read_bytes()).hexdigest()
    if errors:
        for error in errors:
            print(f"bypass-contract: FAIL: {error}", file=sys.stderr)
        return 1
    print(f"bypass-contract: PASS entries={len(policy)} masters_disabled={len(masters)} action_specific={len(policy)-len(masters)} policy_sha256={policy_digest}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
