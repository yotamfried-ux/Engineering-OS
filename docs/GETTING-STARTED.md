# Engineering-OS — 60-second start

Engineering-OS is a knowledge library. **Clone the library once on a persistent
machine. Do not re-clone it for every project or every AI session.**

## 1. First time on a persistent host

```bash
git clone https://github.com/yotamfried-ux/Engineering-OS.git ~/Engineering-OS
git -C ~/Engineering-OS pull --ff-only
```

The first command is one-time. Later sessions use only `git pull --ff-only`.

Disposable cloud containers may lose their filesystem. Re-cloning can be
unavoidable there, but rediscovering tool installation is not.

## 2. New project: declare its tools once

Create a project manifest from a sensible seed:

```bash
# normal software project
python3 ~/Engineering-OS/tools/eos_capabilities.py init-project --project /path/to/project --profile core

# mobile application
python3 ~/Engineering-OS/tools/eos_capabilities.py init-project --project /path/to/project --profile mobile
```

This creates `.engineering-os-tools.json`. It is the project's durable list of
Engineering-OS external tools. Commit it when the team wants the same tool
selection on every checkout.

Profiles are only starting points. Add/remove tools in that JSON as the project
adopts them. The central catalog covers the integrated agent tools and
application-testing tools, including Superpowers, RTK, Graphify, Maestro,
Playwright MCP, Chrome DevTools MCP, Appium MCP, Mobile Next MCP, claude-mem,
gstack, UI UX Pro Max and CLI-Anything.

See every managed/catalogued tool without reading its activation guide:

```bash
python3 ~/Engineering-OS/tools/eos_capabilities.py catalog
```

## 3. Install/activate every declared project tool

```bash
python3 ~/Engineering-OS/tools/eos_capabilities.py setup --project /path/to/project
```

Default `--profile auto` means:

1. if `.engineering-os-tools.json` exists, process **every tool declared there**;
2. otherwise fall back to the small `core` profile.

The command is idempotent:

- host tools are installed once and reused across projects when already ready;
- host hooks/plugins are checked separately from binaries;
- project MCP registration is done once per project;
- Graphify is installed once on the host and its graph is rebuilt only when the
  project revision changes;
- npx-based MCPs are registered once instead of being rediscovered each session;
- manual/conditional/deprecated tools fail closed to one known activation guide
  instead of triggering open-ended research.

Code examples, patterns, templates and reference repositories are **knowledge,
not installation dependencies**. They are never installed just because a
project uses Engineering-OS.

## 4. Later sessions: status first, never reinstall blindly

```bash
python3 ~/Engineering-OS/tools/eos_capabilities.py status --project /path/to/project --json
```

If it reports `"ready":true`, stop setup work and begin the engineering task.
Do not reread activation docs and do not reinstall matching tools.

To add one newly adopted capability without reprocessing the project:

```bash
python3 ~/Engineering-OS/tools/eos_capabilities.py ensure \
  --project /path/to/project \
  --tool playwright-mcp
```

Then add that tool name to the project's `.engineering-os-tools.json` so later
sessions know it belongs to the project.

## 5. What “install once” means

- **Persistent host:** the actual host installation is reused.
- **New project on the same host:** only project-local activation is added.
- **New disposable cloud host:** binaries may need downloading again because the
  previous filesystem no longer exists, but the AI does not rediscover commands;
  the manager restores only missing/mismatched declared tools.
- **Manual/conditional tools:** Engineering-OS points to the single activation
  contract. They are not silently auto-installed until that path is qualified.

This keeps setup from consuming the session that should be spent solving and
testing the application.
