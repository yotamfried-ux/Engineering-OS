# Library Normalization Audit — 2026-09-21

Audited revision before this normalization pass: `473469de3c10168cf73a981612bb851586f8dbe3`.

## Inventory

The repository contained **385 files**:
- capability registry: 24
- external skills: 54
- external systems: 67
- docs: 103
- patterns: 35
- templates: 43
- lessons learned: 25
- imported Stage 3 knowledge: 27
- architecture decisions: 3
- failed solutions: 3
- root README: 1

This pass treats the library as knowledge, not as a runtime.

## Findings

### Fixed in this pass

1. **No small agent entry point.** Added root `AGENTS.md` as a map with progressive disclosure.
2. **Routing was distributed.** Added `ROUTING-MAP.md` keyed by jobs rather than folder type.
3. **Source authority was implicit.** Added `SOURCE-POLICY.md` with canonical/reference/community/historical tiers.
4. **External-systems index still referenced deleted `core/` runtime owners.** Replaced those ownership pointers with live library paths.
5. **Capability registry contract lacked explicit overlap/do-not-use and proof boundaries.** Strengthened the contract.

### Existing strengths retained

- Testing guidance already separates evidence from a merely green CI run.
- Security guidance already uses standards/tool evidence rather than claiming absolute security.
- Application-testing wrappers distinguish exploratory MCP capability from deterministic regression evidence.
- Token/context capabilities have dedicated routing.
- Historical Stage 3 and lessons remain available as evidence/history instead of being rewritten as current runtime instructions.

## Qualification interpretation

A full library audit is not the same as live execution of every third-party tool. This pass normalizes **discovery, provenance, routing and status semantics**. Existing tool-specific qualification reports remain the source for capabilities already inspected.

The following classes require target-host execution before they can be called LIVE:
- MCP/stdio servers
- local CLI/hooks/plugins
- device/browser automation
- tools requiring credentials, cookies, API keys, Docker, emulators or physical devices

Do not upgrade HOST-DEPENDENT/CONDITIONAL to LIVE from documentation inspection alone.

## Remaining debt

- Older `external-skills/` wrappers are uneven: some use the former four-file Claude-centric contract while newer additions are concise single-file wrappers.
- Many `external-systems/` entries are inventory/reference notes rather than fully normalized capability records.
- Historical lessons intentionally contain names of removed runtime paths; these are evidence, not active dependencies.
- Some old README counts are snapshots and should not be treated as automatically maintained inventory.

## Next gate

Before building automated freshness maintenance, run **routing evaluations** against representative tasks. The success criterion is not “found a document”; it is whether an agent selects the right branch/source/tool, avoids irrelevant context, verifies prerequisites, and reports evidence/gaps correctly.
