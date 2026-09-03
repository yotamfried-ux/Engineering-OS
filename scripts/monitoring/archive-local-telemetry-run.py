#!/usr/bin/env python3
"""Best-effort local archiving of a finished telemetry run.

Called from record-and-sync-telemetry.sh at the Stop/StopFailure/SessionEnd
boundary. When a local Engineering OS checkout is reachable via
ENGINEERING_OS_HOME, this builds the same handoff-enriched telemetry bundle
sync-telemetry-run.py builds for the remote push (export-telemetry-run.py's
output plus write_handoff_manifest()'s checksums/handoff metadata — that
metadata is not optional: import-telemetry-run.py's shared integrity
validator rejects a bundle without it), then imports that bundle into the
checkout's telemetry-archive/ (via import-telemetry-run.py). This is what
lets analyze-telemetry-archive.py see the run without a human running
export/import by hand.

This step is intentionally never allowed to block session termination: any
missing dependency, missing/empty run, or importer failure other than an
expected duplicate-import is logged and swallowed (exit 0). It never touches
sync-telemetry-run.py's actual remote push, which is a separate concern with
its own required/best_effort/disabled policy and keeps running exactly as
before.

A run made only of session-lifecycle bookkeeping (session_start plus the
Stop/StopFailure/SessionEnd boundary event itself, with no tool use, prompt,
or subagent activity in between) is deliberately not archived: every managed
session reaches at least one boundary event, so archiving unconditionally
would fill telemetry-archive/ with "opened and closed" noise on every trivial
session instead of runs worth analyzing later.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path


def warn(message: str) -> None:
    print(f"WARNING_FOR_AGENT: local telemetry archiving: {message}", file=sys.stderr)


# Pure session-lifecycle bookkeeping: recorded on every session regardless of
# whether the agent did anything. A run made only of these is "opened and
# closed" noise, not a real run: archiving it on every trivial session would
# fill telemetry-archive/ with clutter instead of runs worth analyzing later.
LIFECYCLE_ONLY_EVENT_NAMES = {
    "eos.session_start",
    "eos.stop",
    "eos.stop_failure",
    "eos.session_end",
}


def has_real_activity(events: list[dict]) -> bool:
    return any(str(item.get("name") or "") not in LIFECYCLE_ONLY_EVENT_NAMES for item in events)


def git_value(root: Path, args: list[str]) -> str:
    try:
        return subprocess.check_output(
            ["git", "-C", str(root), *args], text=True, stderr=subprocess.DEVNULL
        ).strip()
    except Exception:
        return ""


def repo_root() -> Path:
    try:
        out = subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"], text=True, stderr=subprocess.DEVNULL
        ).strip()
        return Path(out)
    except Exception:
        return Path.cwd()


def resolve_engineering_os_home() -> Path | None:
    configured = os.environ.get("ENGINEERING_OS_HOME", "").strip()
    if configured:
        home = Path(configured)
    else:
        # Same default as sync-telemetry-run.py's engineering_os_head(): two
        # parents above this script's own location (scripts/monitoring/../..).
        home = Path(__file__).resolve().parents[2]
    return home if home.is_dir() else None


def load_sync_module(home: Path):
    sync_path = home / "scripts" / "monitoring" / "sync-telemetry-run.py"
    spec = importlib.util.spec_from_file_location("eos_sync_telemetry_run", sync_path)
    module = importlib.util.module_from_spec(spec)
    sys.path.insert(0, str(home / "scripts" / "monitoring"))
    try:
        spec.loader.exec_module(module)  # type: ignore[union-attr]
    finally:
        sys.path.pop(0)
    return module


def log_diagnostic(target_root: Path, record: dict) -> None:
    log_path = target_root / ".engineering-os" / "telemetry" / "local-archive-errors.jsonl"
    try:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        with log_path.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")
    except Exception:
        pass


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Best-effort local import of the current telemetry run into "
        "ENGINEERING_OS_HOME's telemetry-archive/."
    )
    parser.add_argument("--event", default="unknown")
    parser.add_argument("--telemetry-dir", default=".engineering-os/telemetry")
    args = parser.parse_args()

    target_root = repo_root()
    telemetry_root = Path(args.telemetry_dir)
    if not telemetry_root.is_absolute():
        telemetry_root = target_root / telemetry_root
    events_src = Path(os.environ.get("EOS_TELEMETRY_FILE") or (telemetry_root / "events.jsonl"))
    run_id_file = Path(
        os.environ.get("EOS_TELEMETRY_RUN_ID_FILE") or (telemetry_root / "run_id")
    )

    if not events_src.is_file() or events_src.stat().st_size == 0:
        # Nothing recorded yet for this run; normal on early boundary calls.
        return 0

    home = resolve_engineering_os_home()
    if home is None:
        warn("ENGINEERING_OS_HOME is not a local directory; skipping archive import.")
        return 0

    archive_dir = home / "telemetry-archive"
    exporter = home / "scripts" / "monitoring" / "export-telemetry-run.py"
    importer = home / "scripts" / "monitoring" / "import-telemetry-run.py"
    sync_script = home / "scripts" / "monitoring" / "sync-telemetry-run.py"
    if not archive_dir.is_dir() or not exporter.is_file() or not importer.is_file() or not sync_script.is_file():
        warn(
            f"no local telemetry-archive/ + exporter/importer/sync runtime under {home}; "
            "skipping archive import."
        )
        return 0

    run_id = ""
    if run_id_file.is_file():
        run_id = run_id_file.read_text(encoding="utf-8", errors="replace").splitlines()[0].strip()
    if not run_id:
        warn("telemetry run_id is missing; skipping archive import.")
        return 0

    try:
        sync_mod = load_sync_module(home)
        events = sync_mod.load_jsonl_strict(events_src)
        if not events or any(str(item.get("trace_id") or "") != run_id for item in events):
            warn("current telemetry file is empty or mixes multiple run ids; skipping archive import.")
            return 0
        sync_mod.validate_metadata_only(events)

        if not has_real_activity(events):
            # Lifecycle-only run (e.g. a session opened and closed with no
            # tool use, prompt, or subagent activity). Not an error; keeping
            # these out of the archive is what keeps it navigable over time.
            return 0

        source_branch = sync_mod.git(target_root, "rev-parse", "--abbrev-ref", "HEAD")
        branch_hash = sync_mod.stable_hash(source_branch)
        head_sha = sync_mod.git(target_root, "rev-parse", "HEAD")
        repo_slug = sync_mod.detect_repo_slug(target_root, "")
        boundary = sync_mod.latest_boundary_position(events)
        eos_head_sha = sync_mod.engineering_os_head()
    except Exception as exc:
        log_diagnostic(
            target_root,
            {
                "schema_version": "eos.local_archive.error.v1",
                "event": args.event,
                "stage": "identity",
                "diagnostic_sha256": hashlib.sha256(str(exc).encode("utf-8", errors="replace")).hexdigest(),
                "timestamp": time.time(),
            },
        )
        warn(f"could not resolve run identity ({type(exc).__name__}); skipping archive import.")
        return 0

    with tempfile.TemporaryDirectory(prefix="eos-local-archive-") as tmp:
        bundle_dir = Path(tmp) / "bundle"
        export_cmd = [
            sys.executable,
            str(exporter),
            "--out",
            str(bundle_dir),
            "--telemetry-dir",
            str(telemetry_root),
            "--project",
            target_root.name,
            "--repo",
            repo_slug,
            "--branch",
            source_branch,
            "--head-sha",
            head_sha,
            "--engineering-os-head-sha",
            eos_head_sha,
        ]
        export_result = subprocess.run(export_cmd, cwd=target_root, capture_output=True, text=True)
        if export_result.returncode != 0:
            log_diagnostic(
                target_root,
                {
                    "schema_version": "eos.local_archive.error.v1",
                    "event": args.event,
                    "stage": "export",
                    "exit_status": export_result.returncode,
                    "diagnostic_sha256": hashlib.sha256(
                        export_result.stderr.encode("utf-8", errors="replace")
                    ).hexdigest(),
                    "timestamp": time.time(),
                },
            )
            warn(f"export step failed (exit {export_result.returncode}); left local telemetry untouched.")
            return 0

        # Same handoff enrichment sync() applies before a remote push: the shared
        # integrity validator in import-telemetry-run.py requires this metadata
        # (checksums + handoff block) and rejects a bare export-only bundle.
        try:
            sync_mod.write_handoff_manifest(
                bundle_dir,
                run_id=run_id,
                repo_slug=repo_slug,
                pr_number=0,
                branch_hash=branch_hash,
                head_sha=head_sha,
                event_count=len(events),
                boundary_position=boundary,
            )
        except Exception as exc:
            log_diagnostic(
                target_root,
                {
                    "schema_version": "eos.local_archive.error.v1",
                    "event": args.event,
                    "stage": "handoff_enrich",
                    "diagnostic_sha256": hashlib.sha256(str(exc).encode("utf-8", errors="replace")).hexdigest(),
                    "timestamp": time.time(),
                },
            )
            warn(f"handoff enrichment failed ({type(exc).__name__}); skipping archive import.")
            return 0

        import_cmd = [
            sys.executable,
            str(importer),
            str(bundle_dir),
            "--archive",
            str(archive_dir),
            "--expected-repo",
            repo_slug,
            "--expected-branch-hash",
            branch_hash,
            "--expected-head-sha",
            head_sha,
            "--expected-run-id",
            run_id,
            "--expected-engineering-os-head-sha",
            eos_head_sha,
        ]
        import_result = subprocess.run(import_cmd, cwd=home, capture_output=True, text=True)
        if import_result.returncode == 0:
            print(import_result.stdout.strip())
            return 0

        if "duplicate telemetry import for" in import_result.stderr:
            # Expected: Stop, StopFailure, and SessionEnd can all fire for one
            # session. The run is already archived; nothing more to do.
            return 0

        log_diagnostic(
            target_root,
            {
                "schema_version": "eos.local_archive.error.v1",
                "event": args.event,
                "stage": "import",
                "exit_status": import_result.returncode,
                "diagnostic_sha256": hashlib.sha256(
                    import_result.stderr.encode("utf-8", errors="replace")
                ).hexdigest(),
                "timestamp": time.time(),
            },
        )
        warn(f"import step failed (exit {import_result.returncode}); local telemetry left untouched.")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
