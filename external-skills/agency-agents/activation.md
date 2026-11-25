# Agency Agents — real Claude agent-definition installation

**Canonical upstream:** https://github.com/msitarzewski/agency-agents
**Discovery:** https://www.instagram.com/reel/DgJcVOdzDCB/
**Status:** opt-in Git-backed installer; no production-host installation evidenced.

```bash
# From Engineering-OS checkout with real Claude Code installed:
python3 tools/eos_capabilities.py ensure --tool agency-agents
```

The installer clones the canonical repository once to `~/.local/share/engineering-os/reel-skills/agency-agents` and links validated native agent definition Markdown files from the upstream divisions to `~/.claude/agents/<division>-<agent>.md`. It never overwrites an existing agent and checks every symlink on re-use. It does **not** run the upstream install.sh or arbitrary conversion scripts.

The source divisions include engineering, design, marketing, product, sales, testing, security and other team specialisms. Installing a large roster may add context/tool complexity: choose relevant agents rather than activating all simultaneously. A symlink/CLI check proves the definitions are present, not that every agent is effective or authorized to take actions. Keep write/merge/send policy gates managed independently.

Upstream README: https://github.com/msitarzewski/agency-agents#readme
