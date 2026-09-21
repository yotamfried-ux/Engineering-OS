# Graft

**Canonical candidate:** `naouaro/graft`

Codebase-understanding layer for coding agents. Upstream describes building a linked local graph of systems/APIs/concepts so agents can retrieve focused context instead of repeatedly rediscovering the repository. It can wire supported coding agents during initialization.

## Use when
Use when repository exploration is repeatedly consuming tokens/tool calls and a regenerable codebase knowledge graph would reduce rediscovery.

## Overlap
Strong overlap with Graphify and Codebase Memory MCP. Benchmark on a representative repository before choosing one; do not install all three by default.

## Qualification
Use upstream dry-run/init controls first. Record every file/config/hook it changes. Build a graph for a fixture repo, ask known architecture/navigation questions, modify the repo, rebuild/update and verify stale knowledge is not returned. Compare token/tool-call cost against the baseline agent.

**Status:** CANDIDATE / HOST-DEPENDENT. Reconfirm canonical ownership/package before installation because similarly named Graft repositories exist.
