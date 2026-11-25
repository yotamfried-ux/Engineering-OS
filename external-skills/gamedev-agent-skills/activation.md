# gamedev-agent-skills — activation

**Status:** centrally registered / opt-in, **host installation not yet verified**. A GitHub catalog record alone is not an installation.

**Canonical upstream:** https://github.com/gamedev-skills/awesome-gamedev-agent-skills

## Activate on a persistent Claude Code host

```bash
# From a checkout of yotamfried-ux/Engineering-OS
python3 tools/eos_capabilities.py ensure --tool gamedev-agent-skills
python3 tools/eos_capabilities.py catalog | grep gamedev-agent-skills
```

The first command performs an actual installation, or returns nonzero when a required CLI is unavailable, an upstream fetch fails, an existing skill conflicts, or post-install checks fail. For git-skills, it clones the allowlisted GitHub repository once into `~/.local/share/engineering-os/reel-skills/` and symlinks real `SKILL.md` folders into `~/.claude/skills/` without overwriting existing files. For Claude plugins it calls the official CLI marketplace installer. Later calls reuse the installed state. This does not change default `core` profile.

**Use / prerequisites:** Full set of engine skills and router. Requires installed game engine(s) and actual game play-testing to validate outputs; https://github.com/gamedev-skills/awesome-gamedev-agent-skills .

**Scope and security:** Third-party instructions may request shell commands or secrets. Inspect upstream changes, run under least privilege, do not enable unsupervised writes or outbound messages, and never treat a successful installation check as end-to-end task qualification.

**Provenance:** Instagram video intake 2026-11-25. No claims of live installation on the user's VM.
