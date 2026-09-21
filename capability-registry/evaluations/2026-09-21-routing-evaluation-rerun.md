# Routing Evaluation Run — 2026-09-21 — Post-remediation

**Revision:** `f9fb0c79a12ab6b12fc9bb8b1fba77d481f30db8`

Rerun after remediating the two PARTIAL findings from the first routing evaluation.

| # | Scenario | Result | Evidence |
|---|---|---|---|
| 1 | Web checkout qualification | PASS | testing qualification route preserves UI + authoritative side-effect evidence |
| 2 | Android release readiness | PASS | Play readiness routes to mobile/security/current vendor requirements |
| 3 | Instagram Reel analysis | PASS | dedicated conditional video-analysis wrapper with explicit live-verification contract |
| 4 | Large-repository context cost | PASS | RTK/Graphify/memory split by actual bottleneck |
| 5 | Web security qualification | PASS | standards + executable evidence; no absolute-security claim |
| 6 | Browser UI regression | PASS | Playwright deterministic regression separated from exploratory/diagnostic tools |
| 7 | Cross-session coding memory | PASS | claude-mem, agentmemory and OpenViking now exposed with host/privacy/freshness/deletion qualification |
| 8 | External service integration | PASS | external-system/connector route requires current official provider docs |
| 9 | Known production bug | PASS | live troubleshooting index now routes reproduce → cause evidence → expected-reason regression → affected-path rerun |
| 10 | Autonomous coding runtime | PASS | host-native capability first; optional runtimes remain host-dependent and bounded |

## Counts
- PASS: **10**
- PARTIAL: **0**
- FAIL: **0**
- BLOCKED: **0**

This is a PASS for the **routing/evidence architecture**, not live qualification of all third-party tools.

## Next engineering gate
Add mechanical knowledge-integrity checks for active dead links, required routing targets and forbidden removed-runtime dependencies. This follows the same principle as the repository-knowledge approach: documentation structure should be mechanically checkable rather than relying only on human/agent memory.
