#!/usr/bin/env python3
"""Engineering-OS qualified capability setup.

This is a convenience installer for the small live-qualified tool set. It is
not an Engineering-OS runtime and it never installs the whole knowledge catalog.
"""
from __future__ import annotations

import argparse
import json
import os
import platform
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "capability-registry" / "INSTALL-PROFILES.json"


def load_manifest() -> dict:
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))


def run(cmd: list[str], *, cwd: Path | None = None, env: dict | None = None,
        check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        cwd=str(cwd) if cwd else None,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=check,
    )


def first_line(cmd: list[str], *, cwd: Path | None = None) -> str:
    try:
        result = run(cmd, cwd=cwd, check=False)
    except OSError:
        return ""
    return (result.stdout or "").splitlines()[0] if result.stdout else ""


def command_exists(name: str) -> bool:
    return shutil.which(name) is not None


def version_matches(name: str, expected: str) -> bool:
    line = first_line([name, "--version"])
    return bool(line and expected in line)


def claude_list(kind: str, *, cwd: Path | None = None) -> str:
    if not command_exists("claude"):
        return ""
    result = run(["claude", kind, "list"], cwd=cwd, check=False)
    return result.stdout or ""


def git_head(project: Path) -> str | None:
    if not (project / ".git").exists():
        return None
    result = run(["git", "rev-parse", "HEAD"], cwd=project, check=False)
    if result.returncode != 0:
        return None
    return result.stdout.strip()


def state_path(project: Path) -> Path:
    git_dir = project / ".git"
    if git_dir.is_dir():
        return git_dir / "engineering-os-tools.json"
    return project / ".engineering-os-tools.json"


def rtk_hook_ready() -> bool:
    settings = Path.home() / ".claude" / "settings.json"
    if not settings.is_file():
        return False
    return "rtk hook" in settings.read_text(encoding="utf-8", errors="replace")


def mcp_ready(name: str, project: Path) -> bool:
    return name.lower() in claude_list("mcp", cwd=project).lower()


def graph_ready(project: Path) -> bool:
    graph = project / "graphify-out" / "graph.json"
    stamp = project / "graphify-out" / ".engineering-os-head"
    head = git_head(project)
    if not graph.is_file() or graph.stat().st_size == 0:
        return False
    if head is None:
        return stamp.is_file()
    return stamp.is_file() and stamp.read_text(encoding="utf-8").strip() == head


def tool_status(name: str, version: str, project: Path) -> dict:
    if name == "superpowers":
        plugins = claude_list("plugin")
        ready = "superpowers" in plugins.lower()
        return {"ready": ready, "detail": "plugin active" if ready else "plugin missing"}
    if name == "rtk":
        cli = version_matches("rtk", version)
        hook = rtk_hook_ready()
        ready = cli and hook
        return {
            "ready": ready,
            "detail": f"cli={'yes' if cli else 'no'}, hook={'yes' if hook else 'no'}",
        }
    if name == "graphify":
        cli = version_matches("graphify", version)
        mcp_bin = command_exists("graphify-mcp")
        graph = graph_ready(project)
        mcp = mcp_ready("graphify", project)
        ready = cli and mcp_bin and graph and mcp
        return {
            "ready": ready,
            "detail": (
                f"cli={'yes' if cli else 'no'}, mcp-bin={'yes' if mcp_bin else 'no'}, "
                f"graph={'current' if graph else 'missing/stale'}, mcp={'yes' if mcp else 'no'}"
            ),
        }
    if name == "maestro":
        cli = version_matches("maestro", version)
        mcp = mcp_ready("maestro", project)
        ready = cli and mcp
        return {
            "ready": ready,
            "detail": f"cli={'yes' if cli else 'no'}, mcp={'yes' if mcp else 'no'}",
        }
    return {"ready": False, "detail": "unsupported by installer"}


def ensure_posix() -> None:
    if platform.system() not in {"Linux", "Darwin"}:
        raise RuntimeError(
            "The automatic installer is live-qualified for Linux/macOS-style hosts only. "
            "Use the capability activation.md on this OS; do not guess an install command."
        )


def install_superpowers(dry_run: bool) -> None:
    if dry_run:
        print("CHANGE superpowers: add official marketplace and install plugin")
        return
    if not command_exists("claude"):
        raise RuntimeError("Claude Code CLI is required for Superpowers")
    run(["claude", "plugin", "marketplace", "add", "anthropics/claude-plugins-official"], check=False)
    run(["claude", "plugin", "install", "superpowers@claude-plugins-official"])


def install_rtk(version: str, dry_run: bool) -> None:
    ensure_posix()
    if dry_run:
        print(f"CHANGE rtk: install pinned {version} and register Claude hook")
        return
    with tempfile.TemporaryDirectory(prefix="eos-rtk-") as temp:
        installer = Path(temp) / "install.sh"
        urllib.request.urlretrieve(
            "https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh",
            installer,
        )
        env = os.environ.copy()
        env["RTK_VERSION"] = f"v{version}"
        run(["sh", str(installer)], env=env)
    if not command_exists("rtk"):
        local = Path.home() / ".local" / "bin" / "rtk"
        if local.exists():
            os.environ["PATH"] = f"{local.parent}{os.pathsep}{os.environ.get('PATH','')}"
    run(["rtk", "init", "-g", "--auto-patch"])


def install_graphify(version: str, dry_run: bool) -> None:
    if dry_run:
        print(f"CHANGE graphify: uv tool install graphifyy[mcp]=={version}")
        return
    if not command_exists("uv"):
        raise RuntimeError("uv is required for the qualified Graphify install path")
    env = os.environ.copy()
    env.setdefault("UV_TOOL_BIN_DIR", str(Path.home() / ".local" / "bin"))
    run(["uv", "tool", "install", "--force", f"graphifyy[mcp]=={version}"], env=env)
    os.environ["PATH"] = f"{Path.home() / '.local' / 'bin'}{os.pathsep}{os.environ.get('PATH','')}"


def install_maestro(version: str, dry_run: bool) -> None:
    ensure_posix()
    if dry_run:
        print(f"CHANGE maestro: install pinned CLI {version} under ~/.local/share/engineering-os")
        return
    java = first_line(["java", "-version"])
    if not java:
        raise RuntimeError("Java 17+ is required before installing Maestro")
    install_root = Path.home() / ".local" / "share" / "engineering-os" / "maestro" / version
    bin_dir = Path.home() / ".local" / "bin"
    bin_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="eos-maestro-") as temp:
        archive = Path(temp) / "maestro.zip"
        urllib.request.urlretrieve(
            f"https://github.com/mobile-dev-inc/Maestro/releases/download/cli-{version}/maestro.zip",
            archive,
        )
        if install_root.exists():
            shutil.rmtree(install_root)
        install_root.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(archive) as zf:
            zf.extractall(install_root)
    source = install_root / "maestro" / "bin" / "maestro"
    if not source.exists():
        raise RuntimeError(f"Maestro archive layout changed; expected {source}")
    target = bin_dir / "maestro"
    if target.exists() or target.is_symlink():
        target.unlink()
    target.symlink_to(source)
    os.environ["PATH"] = f"{bin_dir}{os.pathsep}{os.environ.get('PATH','')}"


def ensure_graphify_project(project: Path, dry_run: bool) -> None:
    graph = project / "graphify-out" / "graph.json"
    head = git_head(project)
    if graph_ready(project):
        print("SKIP   graphify-project: current graph already exists")
    elif dry_run:
        print("CHANGE graphify-project: build code-only graph for current checkout")
    else:
        run(["graphify", "extract", ".", "--code-only"], cwd=project)
        stamp = project / "graphify-out" / ".engineering-os-head"
        stamp.parent.mkdir(parents=True, exist_ok=True)
        stamp.write_text((head or "non-git") + "\n", encoding="utf-8")

    git_info_exclude = project / ".git" / "info" / "exclude"
    if git_info_exclude.parent.is_dir():
        existing = git_info_exclude.read_text(encoding="utf-8") if git_info_exclude.exists() else ""
        if "graphify-out/" not in existing.splitlines():
            if dry_run:
                print("CHANGE graphify-project: exclude graphify-out/ locally")
            else:
                with git_info_exclude.open("a", encoding="utf-8") as fh:
                    if existing and not existing.endswith("\n"):
                        fh.write("\n")
                    fh.write("graphify-out/\n")

    mcp_list = claude_list("mcp", cwd=project)
    if "graphify" in mcp_list.lower():
        print("SKIP   graphify-mcp: already registered for this project/host")
    elif dry_run:
        print("CHANGE graphify-mcp: register local MCP for this project")
    else:
        graph_mcp = shutil.which("graphify-mcp")
        if not graph_mcp:
            raise RuntimeError("graphify-mcp is not on PATH after installation")
        run(["claude", "mcp", "add", "-s", "local", "graphify", "--", graph_mcp, str(graph.resolve())], cwd=project)


def ensure_maestro_project(project: Path, dry_run: bool) -> None:
    mcp_list = claude_list("mcp", cwd=project)
    if "maestro" in mcp_list.lower():
        print("SKIP   maestro-mcp: already registered for this project/host")
    elif dry_run:
        print("CHANGE maestro-mcp: register local Maestro MCP")
    else:
        run(["claude", "mcp", "add", "-s", "local", "maestro", "--", "maestro", "mcp"], cwd=project)


def resolve_tools(manifest: dict, profile: str) -> list[str]:
    profiles = manifest["profiles"]
    if profile not in profiles:
        raise KeyError(f"Unknown profile: {profile}")
    return list(profiles[profile]["tools"])


def print_status(manifest: dict, project: Path, profile: str, as_json: bool) -> int:
    rows = {}
    all_ready = True
    for name in resolve_tools(manifest, profile):
        version = manifest["tools"][name]["qualified_version"]
        status = tool_status(name, version, project)
        rows[name] = {"qualified_version": version, **status}
        all_ready = all_ready and bool(status["ready"])
    if as_json:
        print(json.dumps(
            {"profile": profile, "project": str(project), "ready": all_ready, "tools": rows},
            separators=(",", ":"),
        ))
    else:
        for name, row in rows.items():
            print(f"{'READY' if row['ready'] else 'MISSING':7} {name:12} {row['detail']}")
        print("READY" if all_ready else "SETUP REQUIRED")
    return 0 if all_ready else 1


def setup(manifest: dict, project: Path, profile: str, dry_run: bool) -> int:
    project = project.resolve()
    if not project.is_dir():
        raise RuntimeError(f"Project directory does not exist: {project}")
    names = resolve_tools(manifest, profile)
    for name in names:
        version = manifest["tools"][name]["qualified_version"]
        status = tool_status(name, version, project)
        if name == "superpowers":
            if status["ready"]:
                print("SKIP   superpowers: already installed")
            else:
                install_superpowers(dry_run)
        elif name == "rtk":
            if version_matches("rtk", version):
                print(f"SKIP   rtk-cli: qualified {version} already installed")
            else:
                install_rtk(version, dry_run)
            if not rtk_hook_ready():
                if dry_run:
                    print("CHANGE rtk-hook: register Claude PreToolUse hook")
                else:
                    run(["rtk", "init", "-g", "--auto-patch"])
            else:
                print("SKIP   rtk-hook: already registered")
        elif name == "graphify":
            cli_ready = version_matches("graphify", version) and command_exists("graphify-mcp")
            if cli_ready:
                print(f"SKIP   graphify-cli: qualified {version} already installed")
            else:
                install_graphify(version, dry_run)
            ensure_graphify_project(project, dry_run)
        elif name == "maestro":
            if version_matches("maestro", version):
                print(f"SKIP   maestro-cli: qualified {version} already installed")
            else:
                install_maestro(version, dry_run)
            ensure_maestro_project(project, dry_run)

    if not dry_run:
        state = {
            "profile": profile,
            "library_revision": git_head(ROOT),
            "project_revision": git_head(project),
            "qualified_versions": {
                name: manifest["tools"][name]["qualified_version"] for name in names
            },
        }
        path = state_path(project)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
        print(f"STATE  {path}")
        return print_status(manifest, project, profile, False)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Install/reuse the small live-qualified Engineering-OS tool set without re-discovery."
    )
    sub = parser.add_subparsers(dest="command", required=True)
    for command in ("status", "setup"):
        p = sub.add_parser(command)
        p.add_argument("--project", default=".", help="target project checkout")
        p.add_argument("--profile", default="core", choices=("core", "mobile"))
        if command == "status":
            p.add_argument("--json", action="store_true", help="compact machine-readable status")
        else:
            p.add_argument("--dry-run", action="store_true", help="show only the changes that would be made")
    args = parser.parse_args()
    manifest = load_manifest()
    project = Path(args.project).expanduser().resolve()
    try:
        if args.command == "status":
            return print_status(manifest, project, args.profile, args.json)
        return setup(manifest, project, args.profile, args.dry_run)
    except (RuntimeError, OSError, subprocess.CalledProcessError, KeyError) as exc:
        print(f"ERROR {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
