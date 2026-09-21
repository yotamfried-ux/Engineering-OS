# Routing Evaluation Run — 2026-09-21

**Engineering-OS revision evaluated:** `454634f1e0f543d2bdbbe5a3737fe7a528107b83`

This evaluates the **knowledge-routing layer**, not the live executability of every third-party tool. A route passes only when it reaches the appropriate library branch, preserves authoritative-source/evidence boundaries, checks prerequisites at the knowledge level, and avoids claiming unexecuted work as PASS.

## Results

| # | Scenario | Route | Canonical source reached | Prereqs | Evidence boundary | Major irrelevant branch loaded | Unsupported claim | Result |
|---|---|---|---|---|---|---|---|---|
| 1 | Web checkout qualification | testing project qualification → web full-stack example → provider docs | yes | yes | yes | no | no | PASS |
| 2 | Android release readiness | release-readiness/google-play → application testing + security → current Google/Android docs | yes | yes | yes | no | no | PASS |
| 3 | Instagram Reel analysis | video-analysis/video-url-analyzer-mcp | yes, upstream identified | yes | yes | no | no | PASS |
| 4 | Large-repository context cost | token-context-efficiency → RTK/Graphify/claude-mem by bottleneck | yes, via tool wrappers | yes | yes | no | no | PASS |
| 5 | Web security qualification | patterns/security → OWASP + executable security tools | yes | yes | yes | no | no | PASS |
| 6 | Browser UI regression | application-testing → Playwright; Chrome DevTools only for diagnostics | yes | yes | yes | no | no | PASS |
| 7 | Cross-session coding memory | token-context-efficiency → claude-mem; compare agentmemory/OpenViking only when host/privacy/storage requirements justify it | partial | partial | yes | no | no | PARTIAL |
| 8 | External service integration | connectors/external-systems → matching official provider docs | yes | yes | yes | no | no | PASS |
| 9 | Known production bug | troubleshooting → lessons/failed-solutions → reproduce → deterministic regression evidence | partial | yes | yes | no | no | PARTIAL |
| 10 | Autonomous coding runtime | host-native capability first → OpenHands/Hermes only as optional host-dependent alternatives | yes | yes | yes | no | no | PASS |

## Counts

- PASS: **8**
- PARTIAL: **2**
- FAIL: **0**
- BLOCKED: **0**

These counts are routing-evaluation results only. They are not a claim that all cataloged tools work live.

## Findings

### Scenario 7 — memory routing is incomplete
The current token/context registry names RTK, Graphify and claude-mem but does not include the newer `agentmemory` and `OpenViking` assets in its comparison surface. An agent can find them by repository search, but the first-stop routing path does not expose the full choice set.

**Required remediation:** extend the memory/context section with explicit categories:
- session memory for Claude Code;
- general coding-agent memory;
- larger context/knowledge substrate;
and require privacy, deletion/update, host support and retrieval-quality checks before adoption.

### Scenario 9 — troubleshooting index contains a dead runtime pointer
`docs/troubleshooting/README.md` still points to deleted `core/debugging-policy.md`. This violates the knowledge-library architecture and can send an agent into a missing path.

**Required remediation:** replace it with the live evidence-driven debugging route: troubleshooting → lessons/failed-solutions → reproduce → regression test using the target project's authoritative runner.

## Search-discoverability observation

Exact multi-term repository search did not reliably surface the memory trio or production-bug knowledge. The explicit routing map compensates for this, but it confirms why a small deterministic map is preferable to expecting free-form repository search to discover every relevant asset.

## Interpretation

The normalized routing layer works for the majority of representative jobs and correctly preserves the distinction between documentation inspection and live qualification. The two PARTIAL scenarios are concrete information-architecture defects, not tool failures. Fix them, rerun this bank, then add mechanical knowledge checks for dead active links and required routing targets.
