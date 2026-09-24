# Token, Context & Memory Efficiency

Use this registry when the bottleneck is **context size, repeated repository reading, noisy command output, or repeated rediscovery across sessions**. Select by bottleneck; do not install all tools automatically. For the live-qualified core tools, check `tools/eos_capabilities.py status --json` before reading install documentation; a READY result means setup context should not be spent again.

| Need | First candidate | Mechanism | Host/shape |
|---|---|---|---|
| High-volume shell/build/test/git output | **RTK** | filters/compresses CLI output before model context | Claude Code hook/CLI |
| Large unfamiliar codebase / cross-file impact | **Graphify** | queryable code graph and targeted retrieval | CLI + optional MCP |
| Claude Code cross-session memory | **claude-mem** | local observations/summaries + lifecycle hooks/MCP | Claude Code |
| General coding-agent persistent memory | **agentmemory** | structured capture/retrieval across sessions | community capability; verify current host integration |
| Larger unified memory/knowledge/skills substrate | **OpenViking** | hierarchical/on-demand context database | external context system; qualify before adoption |

## Routing

1. Diagnose the actual waste first.
2. Shell-output heavy → RTK.
3. Repository-navigation heavy → Graphify.
4. Repeated Claude Code session reconstruction → claude-mem.
5. Need host-agnostic/general coding-agent memory → inspect agentmemory.
6. Need a broader context database spanning memory, resources and skills → inspect OpenViking.
7. If several appear applicable, compare rather than stacking by default.

## Memory qualification requirements

Before adopting any persistent-memory/context substrate, verify:
- supported host and integration mechanism;
- where data is stored and transmitted;
- what is captured automatically;
- secrets/private-data exclusion;
- retrieval quality on representative project questions;
- update/freshness behavior when source files change;
- deletion/reset/export behavior;
- cross-project isolation;
- token/context overhead;
- failure behavior when the memory service is unavailable.

Memory output is **context assistance, not source-of-truth evidence**. Current repository state, authoritative documentation and current tests override stale remembered facts.

## Detailed wrappers

- RTK: `../external-skills/rtk/`
- Graphify: `../external-skills/graphify/`
- claude-mem: `../external-skills/claude-mem/`
- agentmemory: `../external-skills/agentmemory/README.md`
- OpenViking: `../external-systems/openviking/README.md`

## Status discipline

Do not repeat upstream token-saving/performance claims as Engineering-OS facts unless reproduced on a recorded workload. Verify installation/connection before depending on a capability; if the host cannot run it, continue normally and record the gap.
