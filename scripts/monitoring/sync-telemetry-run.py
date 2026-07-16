#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any

from telemetry_handoff import (
    HANDOFF_SCHEMA,
    HandoffError,
    atomic_write_json,
    file_digest,
    latest_boundary_position,
    load_json_object,
    load_jsonl_strict,
    load_policy,
    read_run_id,
    repo_root,
    stable_hash,
    utc_now,
    validate_bundle,
    validate_metadata_only,
    validate_repo_slug,
)


def run(
    args: list[str],
    *,
    cwd: Path | None = None,
    check: bool = True,
    capture: bool = True,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        args,
        cwd=str(cwd) if cwd else None,
        check=check,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )


def git(root: Path, *args: str, required: bool = True) -> str:
    try:
        return run(["git", "-C", str(root), *args]).stdout.strip()
    except Exception:
        if required:
            raise
        return ""


def repo_slug_from_url(value: str) -> str:
    value = str(value or "").strip()
    if value.endswith(".git"):
        value = value[:-4]
    for marker in ("github.com/", "github.com:"):
        if marker in value:
            candidate = value.split(marker, 1)[1].strip("/")
            try:
                return validate_repo_slug(candidate)
            except HandoffError:
                return ""
    return ""


def detect_repo_slug(root: Path, explicit: str = "") -> str:
    if str(explicit or "").strip():
        return validate_repo_slug(explicit)
    candidate = repo_slug_from_url(
        git(root, "remote", "get-url", "origin", required=False)
    )
    if candidate:
        return candidate
    env_repo = os.environ.get("GITHUB_REPOSITORY", "").strip()
    if env_repo:
        return validate_repo_slug(env_repo)
    raise HandoffError(
        "cannot determine canonical repository identity; provide --repo, "
        "configure a GitHub origin, or set GITHUB_REPOSITORY"
    )


def detect_pr_number(root: Path, repo_slug: str, explicit: str = "") -> int:
    repo_slug = validate_repo_slug(repo_slug)
    raw = explicit or os.environ.get("EOS_TELEMETRY_PR_NUMBER", "")
    if str(raw).strip():
        if not str(raw).strip().isdigit() or int(str(raw).strip()) <= 0:
            raise HandoffError("EOS_TELEMETRY_PR_NUMBER must be a positive integer")
        return int(str(raw).strip())
    if not shutil.which("gh"):
        return 0
    try:
        result = run(
            ["gh", "pr", "view", "--repo", repo_slug, "--json", "number", "--jq", ".number"],
            cwd=root,
        ).stdout.strip()
        return int(result) if result.isdigit() else 0
    except Exception:
        return 0


def engineering_os_head() -> str:
    home = Path(os.environ.get("ENGINEERING_OS_HOME", Path(__file__).resolve().parents[2]))
    return git(home, "rev-parse", "HEAD", required=False) or "unknown"


def write_handoff_manifest(
    bundle: Path,
    *,
    run_id: str,
    repo_slug: str,
    pr_number: int,
    branch_hash: str,
    head_sha: str,
    event_count: int,
    boundary_position: int,
) -> dict[str, Any]:
    manifest_path = bundle / "manifest.json"
    manifest = load_json_object(manifest_path)
    manifest["repo"] = repo_slug
    manifest["head_sha"] = head_sha
    manifest["engineering_os_head_sha"] = engineering_os_head()
    manifest["handoff"] = {
        "schema_version": HANDOFF_SCHEMA,
        "repo": repo_slug,
        "pr_number": pr_number,
        "pr_binding": "exact" if pr_number > 0 else "provisional",
        "source_branch_hash": branch_hash,
        "head_sha": head_sha,
        "run_id_hash": stable_hash(run_id),
        "event_count": event_count,
        "boundary_position": boundary_position,
        "synced_at": utc_now(),
    }
    manifest["checksums"] = {
        "events_sha256": file_digest(bundle / "events.jsonl"),
        "summary_sha256": file_digest(bundle / "latest-summary.md"),
    }
    validate_metadata_only(manifest)
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return manifest


def bundle_progress(manifest: dict[str, Any]) -> tuple[int, int, int]:
    handoff = manifest["handoff"]
    return (
        int(manifest.get("event_count") or 0),
        int(handoff.get("boundary_position") or 0),
        int(handoff.get("pr_number") or 0),
    )


def bind_bundle_to_pr(
    bundle: Path,
    pr_number: int,
    *,
    repo_slug: str,
    branch_hash: str,
    head_sha: str,
    run_id: str,
) -> dict[str, Any]:
    manifest = validate_bundle(
        bundle,
        expected_repo=repo_slug,
        expected_branch_hash=branch_hash,
        expected_head_sha=head_sha,
        expected_run_id=run_id,
    )
    handoff = manifest["handoff"]
    existing_pr = int(handoff.get("pr_number") or 0)
    if existing_pr > 0 and existing_pr != pr_number:
        raise HandoffError(
            f"telemetry bundle is already bound to PR #{existing_pr}, "
            f"not requested PR #{pr_number}"
        )
    handoff["pr_number"] = pr_number
    handoff["pr_binding"] = "exact"
    handoff["synced_at"] = utc_now()
    manifest["handoff"] = handoff
    validate_metadata_only(manifest)
    (bundle / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return validate_bundle(
        bundle,
        expected_repo=repo_slug,
        expected_branch_hash=branch_hash,
        expected_head_sha=head_sha,
        expected_run_id=run_id,
    )


def commit_bundle(
    *,
    root: Path,
    policy: dict[str, Any],
    bundle: Path,
    run_id: str,
    repo_slug: str,
    branch_hash: str,
    head_sha: str,
    event_count: int,
    boundary_position: int,
    pr_number: int,
) -> tuple[str, bool, int]:
    remote_url = git(root, "remote", "get-url", policy["remote"])
    branch = policy["branch"]
    for attempt in range(1, 4):
        with tempfile.TemporaryDirectory(prefix="eos-telemetry-push-") as tmp_raw:
            tmp = Path(tmp_raw)
            run(["git", "init", "-q", str(tmp)])
            run(["git", "-C", str(tmp), "config", "user.email", "telemetry@engineering-os.local"])
            run(["git", "-C", str(tmp), "config", "user.name", "Engineering OS Telemetry"])
            run(["git", "-C", str(tmp), "remote", "add", "origin", remote_url])
            fetched = run(
                ["git", "-C", str(tmp), "fetch", "--depth=1", "origin", f"refs/heads/{branch}:refs/remotes/origin/{branch}"],
                check=False,
            )
            if fetched.returncode == 0:
                run(["git", "-C", str(tmp), "checkout", "-q", "-B", branch, f"refs/remotes/origin/{branch}"])
            else:
                run(["git", "-C", str(tmp), "checkout", "-q", "--orphan", branch])
                for child in tmp.iterdir():
                    if child.name == ".git":
                        continue
                    if child.is_dir():
                        shutil.rmtree(child)
                    else:
                        child.unlink()
                (tmp / "README.md").write_text(
                    "# Engineering OS telemetry handoff\n\n"
                    "Metadata-only bundles generated by instrumented Claude sessions.\n",
                    encoding="utf-8",
                )

            destination = tmp / "runs" / run_id
            if destination.exists():
                existing_manifest = validate_bundle(
                    destination,
                    expected_repo=repo_slug,
                    expected_branch_hash=branch_hash,
                    expected_head_sha=head_sha,
                    expected_run_id=run_id,
                )
                existing_events, existing_boundary, existing_pr = bundle_progress(existing_manifest)
            else:
                existing_events, existing_boundary, existing_pr = (0, 0, 0)

            if existing_pr > 0 and pr_number > 0 and existing_pr != pr_number:
                raise HandoffError(
                    f"remote telemetry bundle is already bound to PR #{existing_pr}, "
                    f"not requested PR #{pr_number}"
                )
            effective_pr_number = existing_pr or pr_number
            remote_is_newer = (existing_events, existing_boundary) > (
                event_count,
                boundary_position,
            )

            if remote_is_newer:
                if pr_number > 0 and existing_pr <= 0:
                    bind_bundle_to_pr(
                        destination,
                        pr_number,
                        repo_slug=repo_slug,
                        branch_hash=branch_hash,
                        head_sha=head_sha,
                        run_id=run_id,
                    )
                    run(["git", "-C", str(tmp), "add", str(destination.relative_to(tmp))])
                    run([
                        "git", "-C", str(tmp), "commit", "-q", "-m",
                        f"telemetry: bind {stable_hash(run_id, 12)} to PR {pr_number}",
                    ])
                    pushed = run(
                        ["git", "-C", str(tmp), "push", "origin", f"HEAD:refs/heads/{branch}"],
                        check=False,
                    )
                    if pushed.returncode == 0:
                        return git(tmp, "rev-parse", "HEAD"), True, pr_number
                else:
                    return git(tmp, "rev-parse", "HEAD"), True, effective_pr_number
                if attempt < 3:
                    time.sleep(attempt)
                continue

            if existing_pr > 0 and pr_number <= 0:
                bind_bundle_to_pr(
                    bundle,
                    existing_pr,
                    repo_slug=repo_slug,
                    branch_hash=branch_hash,
                    head_sha=head_sha,
                    run_id=run_id,
                )

            if destination.exists():
                shutil.rmtree(destination)
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copytree(bundle, destination)
            run(["git", "-C", str(tmp), "add", "README.md", "runs"])
            changed = run(["git", "-C", str(tmp), "status", "--porcelain"]).stdout.strip()
            if not changed:
                return git(tmp, "rev-parse", "HEAD"), False, effective_pr_number
            run([
                "git", "-C", str(tmp), "commit", "-q", "-m",
                f"telemetry: sync {stable_hash(run_id, 12)} events={event_count}",
            ])
            pushed = run(
                ["git", "-C", str(tmp), "push", "origin", f"HEAD:refs/heads/{branch}"],
                check=False,
            )
            if pushed.returncode == 0:
                return git(tmp, "rev-parse", "HEAD"), False, effective_pr_number
        if attempt < 3:
            time.sleep(attempt)
    raise HandoffError("failed to push telemetry handoff branch after 3 attempts")


def dispatch_pr_policy(root: Path, repo_slug: str, source_branch: str, pr_number: int) -> None:
    if pr_number <= 0 or os.environ.get("EOS_TELEMETRY_HANDOFF_DISPATCH", "1") == "0":
        return
    workflow = os.environ.get("EOS_TELEMETRY_HANDOFF_WORKFLOW", "pr-policy.yml")
    if not shutil.which("gh"):
        raise HandoffError("gh CLI is required to dispatch pr-policy after telemetry handoff")
    result = run([
        "gh", "workflow", "run", workflow,
        "--repo", repo_slug,
        "--ref", source_branch,
        "-f", f"pr_number={pr_number}",
    ], cwd=root, check=False)
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or "unknown error").strip()
        raise HandoffError(f"telemetry was pushed but pr-policy dispatch failed: {detail}")


def state_path(root: Path) -> Path:
    return Path(os.environ.get(
        "EOS_TELEMETRY_HANDOFF_STATE_FILE",
        str(root / ".engineering-os" / "telemetry" / "handoff-state.json"),
    ))


def check_state(root: Path, policy: dict[str, Any]) -> int:
    if policy["mode"] == "disabled":
        return 0
    telemetry_root = Path(os.environ.get(
        "EOS_TELEMETRY_DIR",
        root / ".engineering-os" / "telemetry",
    ))
    events_path = Path(os.environ.get("EOS_TELEMETRY_FILE", telemetry_root / "events.jsonl"))
    run_id_path = Path(os.environ.get("EOS_TELEMETRY_RUN_ID_FILE", telemetry_root / "run_id"))
    state_file = state_path(root)
    run_id = read_run_id(run_id_path)
    if not run_id or not events_path.is_file() or not state_file.is_file():
        raise HandoffError("current telemetry run has no successful remote handoff state")
    events = load_jsonl_strict(events_path)
    if not events or any(str(item.get("trace_id") or "") != run_id for item in events):
        raise HandoffError("current telemetry events do not match the active run")
    validate_metadata_only(events)

    state = load_json_object(state_file)
    if state.get("schema_version") != HANDOFF_SCHEMA:
        raise HandoffError("remote handoff state schema is invalid")
    validate_metadata_only(state)
    if str(state.get("run_id_hash") or "") != stable_hash(run_id):
        raise HandoffError("remote handoff state belongs to another telemetry run")
    if int(state.get("event_count") or 0) > len(events):
        raise HandoffError("remote handoff state event count is invalid")
    boundary = latest_boundary_position(events)
    if int(state.get("boundary_position") or 0) < boundary:
        raise HandoffError("latest completed session boundary was not handed off remotely")

    current_repo = detect_repo_slug(root)
    current_branch = git(root, "rev-parse", "--abbrev-ref", "HEAD")
    current_head = git(root, "rev-parse", "HEAD")
    expected = {
        "repo": current_repo,
        "source_branch_hash": stable_hash(current_branch),
        "head_sha": current_head,
        "remote": policy["remote"],
        "remote_branch": policy["branch"],
    }
    for key, expected_value in expected.items():
        if str(state.get(key) or "") != expected_value:
            raise HandoffError(
                f"remote handoff state {key} does not match the current workspace"
            )

    current_pr = detect_pr_number(root, current_repo)
    state_pr = int(state.get("pr_number") or 0)
    if current_pr > 0 and state_pr != current_pr:
        raise HandoffError(
            f"current branch is PR #{current_pr}, but durable handoff is still "
            "provisional or bound elsewhere; run a fresh sync"
        )
    if not str(state.get("remote_commit") or ""):
        raise HandoffError("remote handoff state has no durable commit identifier")
    print(
        f"telemetry remote handoff ready: events={state.get('event_count', 0)} "
        f"boundary={state.get('boundary_position', 0)} pr={state_pr or 'provisional'}"
    )
    return 0


def sync(root: Path, policy: dict[str, Any], args: argparse.Namespace) -> int:
    if policy["mode"] == "disabled":
        return 0
    telemetry_root = Path(args.telemetry_dir)
    if not telemetry_root.is_absolute():
        telemetry_root = root / telemetry_root
    events_path = Path(os.environ.get("EOS_TELEMETRY_FILE", telemetry_root / "events.jsonl"))
    run_id_path = Path(os.environ.get("EOS_TELEMETRY_RUN_ID_FILE", telemetry_root / "run_id"))
    run_id = read_run_id(run_id_path)
    if not run_id or not events_path.is_file():
        raise HandoffError(
            "cannot hand off telemetry before the current run has events and a run_id"
        )
    events = load_jsonl_strict(events_path)
    if not events or any(str(item.get("trace_id") or "") != run_id for item in events):
        raise HandoffError("current telemetry file is empty or mixes multiple run ids")
    validate_metadata_only(events)

    source_branch = git(root, "rev-parse", "--abbrev-ref", "HEAD")
    branch_hash = stable_hash(source_branch)
    head_sha = git(root, "rev-parse", "HEAD")
    repo_slug = detect_repo_slug(root, args.repo)
    pr_number = detect_pr_number(root, repo_slug, args.pr_number)
    boundary = latest_boundary_position(events)

    with tempfile.TemporaryDirectory(prefix="eos-telemetry-bundle-") as bundle_raw:
        bundle = Path(bundle_raw)
        exporter = Path(__file__).resolve().parent / "export-telemetry-run.py"
        run([
            sys.executable, str(exporter),
            "--out", str(bundle),
            "--telemetry-dir", str(telemetry_root),
            "--project", root.name,
            "--repo", repo_slug,
            "--branch", source_branch,
            "--head-sha", head_sha,
            "--engineering-os-head-sha", engineering_os_head(),
        ], cwd=root)
        write_handoff_manifest(
            bundle,
            run_id=run_id,
            repo_slug=repo_slug,
            pr_number=pr_number,
            branch_hash=branch_hash,
            head_sha=head_sha,
            event_count=len(events),
            boundary_position=boundary,
        )
        validate_bundle(
            bundle,
            expected_repo=repo_slug,
            expected_branch_hash=branch_hash,
            expected_head_sha=head_sha,
            expected_run_id=run_id,
        )
        remote_commit, stale_skip, effective_pr_number = commit_bundle(
            root=root,
            policy=policy,
            bundle=bundle,
            run_id=run_id,
            repo_slug=repo_slug,
            branch_hash=branch_hash,
            head_sha=head_sha,
            event_count=len(events),
            boundary_position=boundary,
            pr_number=pr_number,
        )

    dispatch_pr_policy(root, repo_slug, source_branch, effective_pr_number)
    state = {
        "schema_version": HANDOFF_SCHEMA,
        "run_id_hash": stable_hash(run_id),
        "repo": repo_slug,
        "pr_number": effective_pr_number,
        "pr_binding": "exact" if effective_pr_number > 0 else "provisional",
        "source_branch_hash": branch_hash,
        "head_sha": head_sha,
        "event_count": len(events),
        "boundary_position": boundary,
        "remote": policy["remote"],
        "remote_branch": policy["branch"],
        "remote_commit": remote_commit,
        "synced_at": utc_now(),
    }
    validate_metadata_only(state)
    atomic_write_json(state_path(root), state)

    if stale_skip:
        print(
            f"telemetry handoff skipped stale local bundle: events={len(events)} "
            f"pr={effective_pr_number or 'provisional'} "
            f"remote_commit={remote_commit[:12]}"
        )
        return 0
    print(
        f"telemetry handoff synced: events={len(events)} "
        f"pr={effective_pr_number or 'provisional'} "
        f"remote_commit={remote_commit[:12]}"
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Persist or verify a metadata-only telemetry handoff."
    )
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--telemetry-dir", default=".engineering-os/telemetry")
    parser.add_argument("--policy-file", type=Path)
    parser.add_argument("--repo", default="")
    parser.add_argument("--pr-number", default="")
    parser.add_argument("--event", default="")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    root = repo_root(args.root)
    policy = load_policy(root, args.policy_file)
    try:
        return check_state(root, policy) if args.check else sync(root, policy, args)
    except Exception as exc:
        if policy["mode"] == "best_effort" and not args.check:
            print(
                f"WARNING_FOR_AGENT: telemetry remote handoff failed: {exc}",
                file=sys.stderr,
            )
            return 0
        print(f"ERROR_FOR_AGENT: telemetry remote handoff failed: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
