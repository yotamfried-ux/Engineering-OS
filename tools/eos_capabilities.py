#!/usr/bin/env python3
"""Engineering-OS install-once capability manager.

The knowledge library stays a library. This helper only removes repeated setup
work: a project declares the external agent/testing tools it uses, and this
manager installs/configures each declared tool once when possible, then reuses
matching host/project state on later sessions.
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


def version_matches(name: str, expected: str | None) -> bool:
    if not expected:
        return command_exists(name)
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
        return git_dir / "engineering-os-tools-state.json"
    return project / ".engineering-os-tools-state.json"


def project_manifest_path(manifest: dict, project: Path) -> Path:
    return project / manifest.get("project_manifest", ".engineering-os-tools.json")


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


def load_project_tools(manifest: dict, project: Path) -> list[str] | None:
    path = project_manifest_path(manifest, project)
    if not path.is_file():
        return None
    payload = json.loads(path.read_text(encoding="utf-8"))
    tools = payload.get("tools")
    if not isinstance(tools, list) or not all(isinstance(x, str) for x in tools):
        raise RuntimeError(f"{path} must contain a string array named 'tools'")
    return tools


def resolve_tools(manifest: dict, profile: str, project: Path) -> list[str]:
    if profile in {"auto", "project"}:
        project_tools = load_project_tools(manifest, project)
        if project_tools is not None:
            names = project_tools
        elif profile == "project":
            raise RuntimeError(
                f"Project manifest not found: {project_manifest_path(manifest, project)}"
            )
        else:
            names = list(manifest["profiles"]["core"]["tools"])
    else:
        profiles = manifest["profiles"]
        if profile not in profiles:
            raise RuntimeError(f"Unknown profile: {profile}")
        names = list(profiles[profile]["tools"])

    unknown = [name for name in names if name not in manifest["tools"]]
    if unknown:
        raise RuntimeError(f"Unknown tool(s) in project/profile: {', '.join(unknown)}")
    return names


def tool_status(name: str, tool: dict, project: Path) -> dict:
    version = tool.get("qualified_version")
    installer = tool.get("installer")

    if name == "superpowers":
        plugins = claude_list("plugin")
        ready = "superpowers" in plugins.lower()
        return {"ready": ready, "detail": "plugin active" if ready else "plugin missing"}

    if name == "rtk":
        cli = version_matches("rtk", version)
        hook = rtk_hook_ready()
        return {
            "ready": cli and hook,
            "detail": f"cli={'yes' if cli else 'no'}, hook={'yes' if hook else 'no'}",
        }

    if name == "graphify":
        cli = version_matches("graphify", version)
        mcp_bin = command_exists("graphify-mcp")
        graph = graph_ready(project)
        mcp = mcp_ready("graphify", project)
        return {
            "ready": cli and mcp_bin and graph and mcp,
            "detail": (
                f"cli={'yes' if cli else 'no'}, mcp-bin={'yes' if mcp_bin else 'no'}, "
                f"graph={'current' if graph else 'missing/stale'}, mcp={'yes' if mcp else 'no'}"
            ),
        }

    if name == "maestro":
        cli = version_matches("maestro", version)
        mcp = mcp_ready("maestro", project)
        return {
            "ready": cli and mcp,
            "detail": f"cli={'yes' if cli else 'no'}, mcp={'yes' if mcp else 'no'}",
        }

    if installer == "claude-plugin":
        match = tool.get("plugin_match", name).lower()
        ready = match in claude_list("plugin").lower()
        return {
            "ready": ready,
            "detail": "plugin active" if ready else "plugin missing",
        }

    if installer == "gstack":
        root = Path.home() / ".claude" / "skills" / "gstack"
        ready = root.is_dir() and (root / "setup").exists()
        return {
            "ready": ready,
            "detail": str(root) if ready else "gstack checkout missing",
        }

    if installer == "project-mcp-npx":
        mcp_name = tool["mcp_name"]
        ready = mcp_ready(mcp_name, project)
        return {
            "ready": ready,
            "detail": f"MCP {'registered' if ready else 'missing'}: {mcp_name}",
        }

    if installer == "deprecated":
        return {"ready": False, "detail": "deprecated; do not install"}

    return {
        "ready": False,
        "detail": f"manual/conditional activation: {tool['activation']}",
    }


def ensure_posix() -> None:
    if platform.system() not in {"Linux", "Darwin"}:
        raise RuntimeError(
            "This automatic recipe is qualified only for Linux/macOS-style hosts. "
            "Use the referenced activation guide on this OS."
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
        print(f"CHANGE rtk: install pinned {version}")
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
    local = Path.home() / ".local" / "bin" / "rtk"
    if not command_exists("rtk") and local.exists():
        os.environ["PATH"] = f"{local.parent}{os.pathsep}{os.environ.get('PATH','')}"


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
        print(f"CHANGE maestro: install pinned CLI {version}")
        return
    if not first_line(["java", "-version"]):
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

    if mcp_ready("graphify", project):
        print("SKIP   graphify-mcp: already registered")
    elif dry_run:
        print("CHANGE graphify-mcp: register project MCP")
    else:
        graph_mcp = shutil.which("graphify-mcp")
        if not graph_mcp:
            raise RuntimeError("graphify-mcp is not on PATH after installation")
        run(
            ["claude", "mcp", "add", "-s", "local", "graphify", "--",
             graph_mcp, str(graph.resolve())],
            cwd=project,
        )


def ensure_maestro_project(project: Path, dry_run: bool) -> None:
    if mcp_ready("maestro", project):
        print("SKIP   maestro-mcp: already registered")
    elif dry_run:
        print("CHANGE maestro-mcp: register project MCP")
    else:
        run(
            ["claude", "mcp", "add", "-s", "local", "maestro", "--", "maestro", "mcp"],
            cwd=project,
        )


def ensure_claude_plugin(name: str, tool: dict, dry_run: bool) -> None:
    if tool_status(name, tool, Path.cwd())["ready"]:
        print(f"SKIP   {name}: plugin already installed")
        return
    if dry_run:
        print(f"CHANGE {name}: install Claude plugin {tool['plugin']}")
        return
    if not command_exists("claude"):
        raise RuntimeError(f"Claude Code CLI is required for {name}")
    marketplace = tool.get("marketplace")
    if marketplace:
        run(["claude", "plugin", "marketplace", "add", marketplace], check=False)
    run(["claude", "plugin", "install", tool["plugin"]])


def ensure_gstack(dry_run: bool) -> None:
    root = Path.home() / ".claude" / "skills" / "gstack"
    if root.is_dir() and (root / "setup").exists():
        print("SKIP   gstack: already installed")
        return
    if dry_run:
        print(f"CHANGE gstack: clone once to {root} and run ./setup")
        return
    if not command_exists("bun"):
        raise RuntimeError("gstack requires Bun; see external-skills/gstack/activation.md")
    root.parent.mkdir(parents=True, exist_ok=True)
    run([
        "git", "clone", "--single-branch", "--depth", "1",
        "https://github.com/garrytan/gstack.git", str(root),
    ])
    run(["./setup"], cwd=root)


def ensure_project_mcp(name: str, tool: dict, project: Path, dry_run: bool) -> None:
    mcp_name = tool["mcp_name"]
    if mcp_ready(mcp_name, project):
        print(f"SKIP   {name}: project MCP already registered")
        return
    if dry_run:
        print(f"CHANGE {name}: register project MCP via npx {tool['package']}")
        return
    if not command_exists("claude"):
        raise RuntimeError(f"Claude Code CLI is required to register {name}")
    if not command_exists("npx"):
        raise RuntimeError(f"Node/npm/npx is required for {name}")
    run([
        "claude", "mcp", "add", "-s", "local", mcp_name, "--",
        "npx", "-y", tool["package"],
    ], cwd=project)


def ensure_tool(name: str, tool: dict, project: Path, dry_run: bool) -> bool:
    installer = tool.get("installer")
    version = tool.get("qualified_version")
    status = tool_status(name, tool, project)
    if status["ready"]:
        print(f"SKIP   {name}: {status['detail']}")
        return True

    if name == "superpowers":
        install_superpowers(dry_run)
    elif name == "rtk":
        if version_matches("rtk", version):
            print(f"SKIP   rtk-cli: qualified {version} already installed")
        else:
            install_rtk(version, dry_run)
        if rtk_hook_ready():
            print("SKIP   rtk-hook: already registered")
        elif dry_run:
            print("CHANGE rtk-hook: register Claude PreToolUse hook")
        else:
            run(["rtk", "init", "-g", "--auto-patch"])
    elif name == "graphify":
        if version_matches("graphify", version) and command_exists("graphify-mcp"):
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
    elif installer == "claude-plugin":
        ensure_claude_plugin(name, tool, dry_run)
    elif installer == "gstack":
        ensure_gstack(dry_run)
    elif installer == "project-mcp-npx":
        ensure_project_mcp(name, tool, project, dry_run)
    elif installer in {"manual", "deprecated"}:
        print(f"MANUAL {name}: {tool['activation']}")
        return False
    else:
        print(f"MANUAL {name}: unsupported installer '{installer}'")
        return False
    return True


def init_project(manifest: dict, project: Path, profile: str, force: bool) -> int:
    project = project.resolve()
    if profile not in manifest["profiles"]:
        raise RuntimeError(f"Unknown profile: {profile}")
    path = project_manifest_path(manifest, project)
    if path.exists() and not force:
        raise RuntimeError(f"{path} already exists; use --force to replace it")
    payload = {
        "schema_version": 1,
        "profile_seed": profile,
        "tools": list(manifest["profiles"][profile]["tools"]),
    }
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(path)
    return 0


def print_catalog(manifest: dict, as_json: bool) -> int:
    if as_json:
        print(json.dumps(manifest["tools"], separators=(",", ":")))
        return 0
    for name, tool in manifest["tools"].items():
        print(
            f"{name:24} automation={tool['automation']:24} "
            f"scope={tool['scope']:18} activation={tool['activation']}"
        )
    return 0


def print_status(manifest: dict, project: Path, profile: str, as_json: bool) -> int:
    names = resolve_tools(manifest, profile, project)
    rows = {}
    all_ready = True
    for name in names:
        tool = manifest["tools"][name]
        status = tool_status(name, tool, project)
        rows[name] = {
            "automation": tool["automation"],
            "qualified_version": tool.get("qualified_version"),
            **status,
        }
        all_ready = all_ready and bool(status["ready"])
    if as_json:
        print(json.dumps(
            {"profile": profile, "project": str(project), "ready": all_ready, "tools": rows},
            separators=(",", ":"),
        ))
    else:
        for name, row in rows.items():
            print(f"{'READY' if row['ready'] else 'MISSING':7} {name:24} {row['detail']}")
        print("READY" if all_ready else "SETUP REQUIRED")
    return 0 if all_ready else 1


def setup(manifest: dict, project: Path, profile: str, dry_run: bool) -> int:
    project = project.resolve()
    if not project.is_dir():
        raise RuntimeError(f"Project directory does not exist: {project}")
    names = resolve_tools(manifest, profile, project)
    automatic_ok = True
    for name in names:
        automatic_ok = ensure_tool(name, manifest["tools"][name], project, dry_run) and automatic_ok

    if dry_run:
        return 0 if automatic_ok else 3

    state = {
        "profile": profile,
        "declared_tools": names,
        "library_revision": git_head(ROOT),
        "project_revision": git_head(project),
    }
    path = state_path(project)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")
    print(f"STATE  {path}")
    return print_status(manifest, project, profile, False)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Install once and reuse Engineering-OS external capabilities without repeated AI setup discovery."
    )
    sub = parser.add_subparsers(dest="command", required=True)

    catalog = sub.add_parser("catalog")
    catalog.add_argument("--json", action="store_true")

    init = sub.add_parser("init-project")
    init.add_argument("--project", default=".")
    init.add_argument("--profile", default="core")
    init.add_argument("--force", action="store_true")

    for command in ("status", "setup"):
        p = sub.add_parser(command)
        p.add_argument("--project", default=".", help="target project checkout")
        p.add_argument(
            "--profile", default="auto",
            help="auto uses the project's .engineering-os-tools.json when present, otherwise core",
        )
        if command == "status":
            p.add_argument("--json", action="store_true", help="compact machine-readable status")
        else:
            p.add_argument("--dry-run", action="store_true")

    ensure = sub.add_parser("ensure")
    ensure.add_argument("--project", default=".")
    ensure.add_argument("--tool", action="append", required=True)
    ensure.add_argument("--dry-run", action="store_true")

    args = parser.parse_args()
    manifest = load_manifest()
    project = Path(getattr(args, "project", ".")).expanduser().resolve()

    try:
        if args.command == "catalog":
            return print_catalog(manifest, args.json)
        if args.command == "init-project":
            return init_project(manifest, project, args.profile, args.force)
        if args.command == "status":
            return print_status(manifest, project, args.profile, args.json)
        if args.command == "ensure":
            ok = True
            for name in args.tool:
                if name not in manifest["tools"]:
                    raise RuntimeError(f"Unknown tool: {name}")
                ok = ensure_tool(name, manifest["tools"][name], project, args.dry_run) and ok
            return 0 if ok else 3
        return setup(manifest, project, args.profile, args.dry_run)
    except (RuntimeError, OSError, subprocess.CalledProcessError, KeyError, json.JSONDecodeError) as exc:
        print(f"ERROR {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
