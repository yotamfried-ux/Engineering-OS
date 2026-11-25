# Remotion Agent Skills — actual install

Canonical upstream: https://github.com/remotion-dev/skills
Official guidance: https://www.remotion.dev/docs/agents
Reel: https://www.instagram.com/reel/DgCYbIeAt69/

```bash
python3 tools/eos_capabilities.py ensure --tool remotion-agent-skills
```

The generic Git installer clones the official repo, links real `SKILL.md` files to Claude Code, refuses overwrites and verifies every link. Skills guide the agent but **do not install Remotion runtime/rendering libraries**. Adopt `remotion-project` separately in a supported React project. Check licenses, media rights and that browser/render dependencies are present, run a real video render before production qualification.
