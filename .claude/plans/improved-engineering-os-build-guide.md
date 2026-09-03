# Route Plan — Improved-Engineering-OS build guide

Plan Scope: standard
Plan Timestamp: 2026-09-03T18:40:00Z
Planning Mode: approved

## Goal / מטרה

Turn the owner's `Improved-Engineering-OS` architecture report (17 approved decisions, 18 stages) into a
single end-to-end build guide that a coding agent can execute from empty repository to Stable release,
and review every decision for correctness and hidden future technical debt.

## Route Plan

| Field | Decision |
|---|---|
| Task type | documentation / architecture review |
| Task class | `engineering_os_governance` (research artifact, no runtime change) |
| Domain tags | architecture, agents, telemetry, supabase, mcp, releases, evals |
| Target paths | `docs/research/improved-engineering-os/build-guide.md` |
| Templates | waiver — deliverable is a research/guide document, not a scaffold |
| Patterns | none implemented; guide references `patterns/` as import corpus |
| External systems/connectors | Context7 (Supabase docs, MCP spec 2026-07-28), GitHub |
| Skills | none required |
| Validation gates | `git diff --check`; markdown renders; no `TBD` placeholders; every flagged debt item has a resolution |
| User decisions required | none for the document; the guide itself lists decisions the owner must approve (D18–D26) |

## Brainstorming / חלופות

| Alternative | Rejected because |
|---|---|
| Write the guide directly into a new `Improved-Engineering-OS` repository | Repository does not exist yet; the owner asked for a document first. Boundary rule: promote from this repo via PR. |
| Split into many files (one per stage) | Owner asked for one document the agent can follow end to end; a single file with stable anchors is easier to pin and hand to an agent. |
| Keep the report as-is and only append a review | The report is an architecture baseline, not an execution guide; stages lack concrete deliverables, module names, exit checks and conventions. |
| Write the guide in Hebrew | The consumer is a coding agent; English spec text reduces ambiguity. Hebrew preface and Hebrew findings summary are included for the owner. |

## Source of Truth Checks

| Source | Status | What it settled |
|---|---|---|
| `core/workflow.md`, `core/documentation-policy.md`, `core/git-policy.md` | read | Plan-first, docs placement (`docs/research/`), commit format, non-draft PR rule. |
| `docs/operations/project8-first-real-run-findings.md` | read | Hooks load at session start; a green PR does not prove telemetry coverage. |
| `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` | read | Remote/web sessions are ephemeral; a local-only outbox loses telemetry; privacy must be allowlist-based. |
| `lessons-learned/bugs/evidence-keyed-on-mechanism.md` | read | Evidence must be keyed on the work performed, not on the invocation mechanism. |
| `lessons-learned/bugs/unit-level-contract-passing-while-wiring-violates-it.md` | read | Tests must run the rendered wiring, not only the unit. |
| Context7 `/websites/supabase` | queried | publishable/secret keys replace anon/service_role by end of 2026; Free plan pauses after 7 days and has no downloadable backups; storage objects excluded from DB backups. |
| Context7 `/websites/modelcontextprotocol_io_specification_2026-07-28` | queried | Stateless core, sessions removed from Streamable HTTP, caching utility, HTTP+SSE deprecated. |

## Plan / תכנון

1. Review each of the 17 decisions and the stage plan against the repo's recorded lessons and vendor docs.
2. Write the guide: Hebrew preface, review findings + added decisions, target repo layout, per-stage build
   instructions with deliverables and exit gates, contracts, conventions, open-parameter register, import appendix.
3. Verify: `git diff --check`, placeholder scan, link scan; commit; push; open PR (non-draft per git-policy).

## DoD / תנאי סיום

- [ ] Every decision D1–D17 has a verdict (confirmed / confirmed-with-change / gap) in the guide.
- [ ] Every identified technical-debt risk has an explicit resolution or an owner decision request.
- [ ] Every stage has: goal, deliverables (paths), interfaces, tests/simulations, exit gate checklist.
- [ ] Guide contains no placeholder markers and passes `git diff --check`.
- [ ] Committed on `claude/engineering-os-project-guide-roj911`, pushed, PR opened.

## Open Questions

- Implementation language and supported platforms are owner decisions; the guide recommends defaults and marks them PROPOSED.

## Affected Surfaces / משטחים מושפעים

- `docs/research/improved-engineering-os/build-guide.md` — new research/guide document (the only deliverable).
- `.claude/plans/improved-engineering-os-build-guide.md` — this temporary plan.
- No `core/`, `scripts/`, `patterns/`, hooks, CI or settings files change.

## Data/State Impact / השפעה על דאטה ומצב

- None. Documentation only; no schema, migration, cache, telemetry schema or runtime state changes in this repository.
- The guide *describes* schemas for a future separate repository; nothing here is executed.

## Integration Impact / השפעה על אינטגרציות

- None at runtime. Context7 was used read-only for vendor-fact verification; GitHub is used for the PR.
- No connector configuration, webhook, or MCP server changes.

## Validation Plan / תוכנית בדיקות

- `git diff --check` clean.
- Placeholder scan (`TBD`/`FIXME`/`XXX`) on the new file returns nothing.
- Internal anchor/section references in the guide resolve (manual read-through of the section list).
- `bash scripts/enforcement/check-documentation-hygiene.sh` passes with the new file present.
- PR opened (non-draft) on the designated branch; CI result recorded in the PR.

## Graphify Usage Evidence

- source: graphify query "telemetry evidence supabase project 8 lessons" over graphify-out/graph.json (1668 nodes, BFS depth 2, 321 nodes found)
- action: graphify traversal of the telemetry handoff community (telemetry_handoff.py, sync-telemetry-run.py, evidence.sh, test-project8-telemetry-readiness.sh) to locate the lessons and runbooks that constrain the new telemetry design
- result: the graph exposed the durable-handoff dependency path (remote workspace -> telemetry_handoff.py -> CI import) and the Project 8 readiness tests as owners of the "ephemeral session loses telemetry" finding
- decision: this graph finding changed the write target: D23 (remote/ephemeral session telemetry path) and TD-02 were added, Stage 5 gained the container-kill scenario, and the import appendix routes those lessons as lesson assets
- target: docs/research/improved-engineering-os/build-guide.md
