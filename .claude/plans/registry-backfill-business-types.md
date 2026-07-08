# Registry Coverage Backfill — Business/Customer-Facing Project Types Route Plan

Plan Scope: standard

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | ops-readiness, registry-coverage, scaling |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Templates | templates/admin-dashboard/, templates/crm-system/, templates/saas-platform/, templates/marketplace/, templates/booking-system/ (already exist and already contain real researched official documentation) |
| Architecture guides | docs/operations/project-type-roadmaps.md, docs/operations/scaling-extension-procedure.md |
| Patterns | patterns/registry.yaml (reused, not modified) |
| External systems/connectors | GitHub |
| Skills | not required |
| Validation gates | scripts/enforcement/check-scaling-extension.py, scripts/enforcement/check-result-loop-contract.py, scripts/enforcement/tests/test-scaling-extension.sh, scripts/enforcement/tests/test-result-loop-contract.sh |
| Evidence to check | scripts/enforcement/project-type-roadmaps.tsv; scripts/enforcement/result-loop-requirements.tsv; scripts/enforcement/documentation-sources.tsv; scripts/enforcement/pattern-requirements.tsv; scripts/enforcement/skill-requirements.tsv; docs/operations/project-type-roadmaps.md; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md |
| User decisions required | User explicitly confirmed: promote all 10 deferred project types to active (not a smaller subset), split across 2 PRs of 5 types each. |
| Target paths | scripts/enforcement/project-type-roadmaps.tsv, scripts/enforcement/result-loop-requirements.tsv, scripts/enforcement/documentation-sources.tsv, scripts/enforcement/pattern-requirements.tsv, scripts/enforcement/skill-requirements.tsv, docs/operations/project-type-roadmaps.md |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| templates/admin-dashboard/README.md | checked | Real "Official Documentation" section: Refine docs, TanStack Table, Tremor, Cloudflare Access. |
| templates/crm-system/README.md | checked | Real "Official Documentation" section: Gmail API, Twenty CRM, Supabase RLS, Microsoft Graph Mail API, Nylas, TanStack Table, HubSpot CRM API. |
| templates/saas-platform/README.md | checked | Real "Official Documentation" section: Stripe Billing/Subscriptions, Supabase Auth/RLS, Clerk Organizations, Next.js docs. |
| templates/marketplace/README.md | checked | Real "Official Documentation" section: Stripe Connect, Medusa docs, Stripe Identity, Algolia InstantSearch. |
| templates/booking-system/README.md | checked | Real "Official Documentation" section: Google Calendar API, Cal.com docs/API, Microsoft Graph Calendar, RFC 5545, Stripe Payment Intents, BullMQ. |
| scripts/enforcement/check-scaling-extension.py | checked | Promoting a project type to `active` requires a matching row in ALL of: project-type-roadmaps.tsv, result-loop-requirements.tsv (any status per `result` set check), documentation-sources.tsv (presence), pattern-requirements.tsv (status active), skill-requirements.tsv (status active) — verified by reading `check()` directly, not assumed. |
| scripts/enforcement/check-result-loop-contract.py | checked | Requires all 13 result-loop-requirements.tsv fields concrete (non-placeholder, len>=8) plus generic keyword checks for creator_local_review/user_simulation/feedback_surfaces/performance_monitoring/acceptance_metrics/change_impact_measurement/telemetry_export/failure_repair_loop/evidence_artifacts. None of these 5 project types hit the type-specific extra rules (those only apply to web-application/mobile/desktop/game/api-service/data-pipeline/machine-learning/ai-agent/computer-vision/browser-extension). |
| scripts/enforcement/documentation-sources.tsv, pattern-requirements.tsv, skill-requirements.tsv | checked | Existing `active` rows (e.g. web-application) show the exact schema/format; pattern and skill rows are formulaic (point at the same `patterns/registry.yaml` and `external-skills/README.md`), only project_type_id and light description text change per type. |
| docs/operations/project-type-roadmaps.md | checked | Canonical human-readable roadmap doc; every existing TSV row's `source_doc_path` points at this SAME file (not per-type external paths) — the per-type detail lives inside this file's table and Source URLs section, which must gain 5 new rows plus any new source URLs. |

## Documentation Asset Evidence

- internal: `templates/admin-dashboard/README.md`; `templates/crm-system/README.md`; `templates/saas-platform/README.md`; `templates/marketplace/README.md`; `templates/booking-system/README.md`; `docs/operations/project-type-roadmaps.md`; `docs/operations/scaling-extension-procedure.md`.
- context7: not required — this is internal-only governance manifest data entry; it does not implement, touch, use, or integrate any external library, framework, SDK, or API. All official documentation sources (Refine, Stripe, Supabase, Clerk, Medusa, Cal.com, Gmail API, Microsoft Graph, Algolia, RFC 5545) were already researched and cited in the existing template READMEs before this PR; this PR only transcribes that already-verified real research into the manifest schema.
- decision: reuse the templates' existing "Official Documentation" sections as the source of truth for `documentation-sources.tsv` rows and `project-type-roadmaps.md` entries, rather than researching from scratch or inventing placeholder sources.

## Connector Evidence

- GitHub: repository reads and writes.

## Connector Usage Evidence

- source: GitHub repository `yotamfried-ux/Engineering-OS`, `templates/{admin-dashboard,crm-system,saas-platform,marketplace,booking-system}/README.md`, `scripts/enforcement/project-type-roadmaps.tsv` deferred rows (added by merged PR #225).
- action: read all 5 template READMEs' real "Official Documentation" sections and cross-referenced them against `check-scaling-extension.py`'s and `check-result-loop-contract.py`'s actual validation logic (not assumed) to determine the exact manifest rows needed.
- result: added `active` rows to `project-type-roadmaps.tsv`, `result-loop-requirements.tsv`, `documentation-sources.tsv`, `pattern-requirements.tsv`, and `skill-requirements.tsv` for admin-dashboard, crm-system, saas-platform, marketplace, and booking-system, plus 5 new table rows in `docs/operations/project-type-roadmaps.md`.
- decision: changed `status` from `deferred` to `active` and added complete rows across all 5 manifests for admin-dashboard, crm-system, saas-platform, marketplace, and booking-system, since real official-doc sources and complete result-loop contract fields now exist for each, verified locally against both checkers before pushing.
- target: scripts/enforcement/project-type-roadmaps.tsv; scripts/enforcement/result-loop-requirements.tsv; scripts/enforcement/documentation-sources.tsv; scripts/enforcement/pattern-requirements.tsv; scripts/enforcement/skill-requirements.tsv; docs/operations/project-type-roadmaps.md

## Template/Pattern Rating Evidence

- asset: patterns/registry.yaml
- rating: reused as-is, not modified — matches the existing shape of the `web-patterns`/`mobile-patterns` rows already active in `pattern-requirements.tsv`.
- outcome: confirmed the registry already covers the pattern reference shape needed by the 5 new `pattern-requirements.tsv` rows for admin-dashboard, crm-system, saas-platform, marketplace, and booking-system; no new patterns were added or removed.
- decision: kept `patterns/registry.yaml` unchanged and pointed all 5 new `pattern-requirements.tsv` rows at it, matching the existing active rows' pattern rather than inventing a new pattern source.
- confidence: high — verified directly by reading `patterns/registry.yaml` and the existing active `pattern-requirements.tsv` rows before reusing the same reference shape.

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `plan.route-plan-before-write` — this plan committed before any manifest edit.
- `source.github-repo-read` — repository files read.
- `validation.policy-change-has-validator` — reusing existing checkers (`check-scaling-extension.py`, `check-result-loop-contract.py`) with no new validator code; only new manifest data rows.
- `validation.coderabbit-policy` — review or fallback required before merge.

## Claude Run Trace

- goal: promote 5 of the 10 deferred project types (admin-dashboard, crm-system, saas-platform, marketplace, booking-system) from `status=deferred` to `status=active` with real, complete manifest coverage across all 5 required manifests.
- hypothesis: the existing template READMEs already contain genuine, researched official documentation sources sufficient to fill the manifest schema without fresh research; only `check-scaling-extension.py`'s and `check-result-loop-contract.py`'s exact validation rules needed to be re-verified from source (not assumed) to avoid a repeat of the gap-1/gap-2 CI round-trip pattern.
- connectors: GitHub.
- steps: read all 5 template READMEs' Official Documentation sections; read `check-scaling-extension.py` and `check-result-loop-contract.py` in full to determine every manifest row required for `active` status; construct rows for all 5 manifests; validate locally before pushing.
- evidence: local `python3 scripts/enforcement/check-scaling-extension.py --root .` and `python3 scripts/enforcement/check-result-loop-contract.py --root .` runs; full local `test-*.sh` sweep.
- rejected: fabricating placeholder documentation sources to save research time — rejected per explicit task instruction never to mark a registry asset validated without real evidence; the templates' existing real research was used instead.
- result: both `check-scaling-extension.py --root .` and `check-result-loop-contract.py --root .` passed on the first local run; the full local `test-*.sh` sweep passed clean; the 3 real CI-flagged plan-evidence gaps found on commit `0e84753` (documentation-asset-policy, connector-evidence-policy, workflow-evidence-policy) were fixed in `ce6ab98` and re-confirmed both locally and on real CI (head `ce6ab98`) before this pre-merge checkpoint.
- follow-up: PR B covers the remaining 5 project types (automation-system, etl-elt-system, multi-agent-system, microservice, analytics-platform).

## Lessons Reused

- `lessons-learned/bugs/ci-environment-dependent-fixture-premise.md` — verify locally against the exact same checker logic the CI runs, not an assumed simplification of it.
- `lessons-learned/bugs/security-gate-silent-diff-truncation.md` — do not let a governance manifest silently accept incomplete/placeholder data; every field must satisfy the checker's real `concrete()`/keyword rules, verified locally before claiming completeness.

## Graphify Usage Evidence

- source: graphify explain query against graphify-out/graph.json.
- action: ran `graphify explain "check-scaling-extension.py"` and `graphify explain "project-type-roadmaps.tsv"` before editing.
- result: consistent with prior findings in PRs #227-#229 — enforcement scripts and TSV manifests are not covered by the graph (no nodes returned); verification was done by direct file reads of the checker source instead of graph traversal.
- decision: treated this as a data-only manifest change scoped to the target files, verified by direct file reads of checker logic.
- target: scripts/enforcement/project-type-roadmaps.tsv; scripts/enforcement/result-loop-requirements.tsv; scripts/enforcement/documentation-sources.tsv; scripts/enforcement/pattern-requirements.tsv; scripts/enforcement/skill-requirements.tsv; docs/operations/project-type-roadmaps.md

## Alternatives

- Promoting all 10 project types in a single PR — rejected; user explicitly confirmed splitting into 2 PRs of 5 to keep each reviewable.
- Fabricating documentation sources instead of reusing the templates' real research — rejected as dishonest per explicit task instruction.
- Leaving all 10 deferred (the pre-existing, already-honest state from PR #225) — rejected since the user explicitly asked for real roadmap research to promote them to active.

## Affected Surfaces

- `scripts/enforcement/project-type-roadmaps.tsv`.
- `scripts/enforcement/result-loop-requirements.tsv`.
- `scripts/enforcement/documentation-sources.tsv`.
- `scripts/enforcement/pattern-requirements.tsv`.
- `scripts/enforcement/skill-requirements.tsv`.
- `docs/operations/project-type-roadmaps.md`.

## Data/State Impact

- No application data impact; governance manifest data only.

## Integration Impact

- `check-scaling-extension.py` and `check-result-loop-contract.py` (both now real named CI gates per PRs #228/#229) will validate these 5 project types' manifest completeness on every future PR.

## Validation Plan

- Run `python3 scripts/enforcement/check-scaling-extension.py --root .` locally (must exit 0).
- Run `python3 scripts/enforcement/check-result-loop-contract.py --root .` locally (must exit 0).
- Run `bash scripts/enforcement/tests/test-scaling-extension.sh` and `bash scripts/enforcement/tests/test-result-loop-contract.sh` locally.
- Run the full local `scripts/enforcement/tests/test-*.sh` sweep.
- Confirm the two named CI gates (added in PRs #228/#229) pass on this PR's real CI run.
- Confirm zero open review threads before merge.

## Open Questions

- None outstanding for this scoped PR.

## Progress Lifecycle Evidence

- start: read all 5 template READMEs and both checkers' full source before any manifest edit; confirmed the real 5-manifest requirement for `active` status directly from `check-scaling-extension.py`'s `check()` function rather than assuming a 2-manifest scope.
- mid: added active rows across all 5 required manifests for admin-dashboard, crm-system, saas-platform, marketplace, and booking-system, removed the old deferred rows for these 5 types, added 5 new table rows plus 20 new Source URLs to `docs/operations/project-type-roadmaps.md`, and confirmed `check-scaling-extension.py --root .` and `check-result-loop-contract.py --root .` both pass on the first run against the real repo state. Full local `test-*.sh` sweep passes clean. `known-gaps.tsv`/audit doc intentionally not yet updated — `registry-coverage-backfill` covers all 10 project types and stays open until PR B also lands.
- pre-merge: fixed the 3 real CI failures found on commit `0e84753` (documentation-asset-policy, connector-evidence-policy, workflow-evidence-policy's Template/Pattern Rating Evidence requirement) in commit `ce6ab98`, re-verified each fix locally against the exact checker scripts CI runs, then confirmed on real CI: `enforcement-tests`, `Require connector route plan evidence`, `Require documentation/reference asset evidence`, `Require capability evidence in changed plans`, `import-cleanup-policy`, `semantic-cleanup-policy`, and `Require ready-for-review PR` all passed on head `ce6ab98` (job run 28914517468 and follow-ups). Confirmed zero open review threads via `get_review_comments`. `known-gaps.tsv`/audit intentionally still not updated — `registry-coverage-backfill` stays open until the companion PR for the remaining 5 project types also lands.

## DoD

- [x] Add `active` rows to all 5 manifests for admin-dashboard, crm-system, saas-platform, marketplace, and booking-system.
- [x] Add 5 corresponding rows to `docs/operations/project-type-roadmaps.md`'s table plus any new Source URLs.
- [x] `check-scaling-extension.py --root .` passes locally.
- [x] `check-result-loop-contract.py --root .` passes locally.
- [x] Full local `test-*.sh` sweep passes clean.
- [x] Confirm both named CI gates (`Verify result loop contract gate`, `Verify scaling extension gate`, part of `enforcement-tests`) pass on this PR's real CI run — confirmed on head `ce6ab98`.
- [x] `known-gaps.tsv`/audit intentionally left unchanged — registry-coverage-backfill stays open until all 10 types are done across both PRs.
- [x] Zero open review threads before merge — confirmed via `get_review_comments` (0 threads).
