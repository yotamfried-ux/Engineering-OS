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

- Integrated skills are now explicitly separated from catalog-only references: every skill listed in the integrated Skill registry is enforced by Knowledge Integrity to have the exact four-file contract; README-only directories remain discovery/catalog references until promoted.
- Many `external-systems/` entries are inventory/reference notes rather than fully normalized capability records.
- Historical lessons intentionally contain names of removed runtime paths; these are evidence, not active dependencies.
- Root catalog counts are snapshot metadata and should not be treated as an automatically maintained inventory.

## Follow-up status — 2026-09-23

The representative routing evaluation was subsequently run and remediated. The active routing map now covers the integrated capability entry points, and Knowledge Integrity validates resolvable first stops plus the exact integrated-skill contract. The remaining debt above is maintenance/normalization work, not a blocker to using the library.
