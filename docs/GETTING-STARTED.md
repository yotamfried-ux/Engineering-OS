# Engineering-OS — 60-second start

Engineering-OS is a knowledge library. **Clone the library once on a persistent
machine. Do not re-clone it for every project or every AI session.**

## 1. First time on a persistent host

```bash
git clone https://github.com/yotamfried-ux/Engineering-OS.git ~/Engineering-OS
cd ~/Engineering-OS
```

For later sessions, reuse the same checkout:

```bash
git -C ~/Engineering-OS pull --ff-only
```

Do not delete/re-clone the library just to get current knowledge.

Disposable cloud containers are different: their filesystem may disappear. In
that case cloning again is unavoidable, but **tool discovery is still not** —
use the capability manager below.

## 2. New project: one setup command

For a normal Claude Code project:

```bash
python3 ~/Engineering-OS/tools/eos_capabilities.py setup --project /path/to/project --profile core
```

For a mobile application project:

```bash
python3 ~/Engineering-OS/tools/eos_capabilities.py setup --project /path/to/project --profile mobile
```

The command is idempotent:

- matching host tools are reused;
- RTK's Claude hook is ensured, not rediscovered;
- Graphify is installed once on the host and its graph/MCP is prepared once per project/revision;
- Maestro is added only by the mobile profile;
- no application dependencies, examples, reference repositories or the rest of the catalog are installed.

Supported automatic profiles contain only the tools with live qualification from
the 2026-09-23 Claude Code host work:

- **core:** Superpowers, RTK, Graphify;
- **mobile:** core + Maestro.

Everything else in Engineering-OS remains knowledge until the task actually
requires it.

## 3. Later sessions: check, don't reinstall

Usually no installation command is needed again. If the AI needs to verify the
environment, use the compact status command:

```bash
python3 ~/Engineering-OS/tools/eos_capabilities.py status --project /path/to/project --profile core --json
```

If it reports `"ready": true`, **do not read installation guides and do not
reinstall anything**. Start the actual engineering task.

The project checkout stores a tiny local state file under `.git/`; generated
Graphify data remains project-local and is not a source-of-truth artifact.

## 4. Route knowledge separately from installing tools

Installation is not the purpose of most library assets.

- Need a code example/pattern/reference? Read or copy the relevant knowledge only.
- Need an external capability to execute something? Route through
  `capability-registry/ROUTING-MAP.md`.
- If the required tool is already READY, use it.
- If a tool is outside the automatic profiles, read its `activation.md` only
  when the task actually triggers it.

This keeps setup from consuming the session that should be spent solving the
project.
