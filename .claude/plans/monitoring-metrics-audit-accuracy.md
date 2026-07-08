# Monitoring Metrics Sufficiency — Audit Accuracy Route Plan

Plan Scope: standard

| Field | Value |
|---|---|
| Task type | Engineering OS documentation accuracy |
| Task class | engineering_os_governance |
| Domain tags | ops-readiness, monitoring, telemetry |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Templates | not required |
| Architecture guides | docs/operations/runtime-telemetry-archive-audit-checklist.md |
| Patterns | not required |
| External systems/connectors | GitHub |
| Skills | not required |
| Validation gates | scripts/enforcement/check-readiness-audit.sh, scripts/enforcement/check-known-gaps.sh |
| Evidence to check | scripts/monitoring/export-telemetry-run.py; scripts/monitoring/import-telemetry-run.py; docs/operations/operational-readiness-audit.md |
| User decisions required | None — task explicitly instructs a doc-accuracy-only fix, no real target-project run, no status flip. |
| Target paths | docs/operations/operational-readiness-audit.md |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| scripts/monitoring/export-telemetry-run.py | checked | Sets `manifest["privacy_contract"] = "metadata-only"` (line 114) but never scans the content of `events.jsonl`/`latest-summary.md` — it copies the files verbatim (lines 94, 96) and only computes counts/checksums. The label is asserted, not verified, at export time. |
| scripts/monitoring/import-telemetry-run.py | checked | `validate_metadata_only()` (lines 54-60) is called from `validate_manifest()` (line 78) and per-event in `load_events()` (line 99). It actually scans for banned keys (`raw_*`, etc.) and banned sensitive-value regex patterns (private keys, GH/OpenAI-style tokens) in the manifest and every event. This is real content-level enforcement, but it only runs at import time — never at export time, and only against whatever bundle happens to be imported. |
| docs/operations/operational-readiness-audit.md | checked | Row 92 ("Monitoring metrics sufficiency") currently says "Gate: exporter/importer/analyzer tests exist but no real target run." — accurate but doesn't describe the specific export/import asymmetry; this PR adds that detail without claiming sufficiency. |
| docs/operations/known-gaps.tsv row 31 (monitoring-metrics-sufficiency) | checked | Already accurate: "Telemetry exporter, importer, and analyzer exist and pass their tests, but no real target-project run has ever been imported, so monitoring sufficiency cannot yet be judged against real data." No change needed — status stays `open`, not touched by this PR. |

## Documentation Asset Evidence

- internal: `scripts/monitoring/export-telemetry-run.py`; `scripts/monitoring/import-telemetry-run.py`; `docs/operations/operational-readiness-audit.md`; `docs/operations/known-gaps.tsv`.
- context7: not required — this is internal-only governance documentation accuracy; it does not implement, touch, use, or integrate any external library, framework, SDK, or API. The claim being documented was verified by reading the actual internal Python source directly.
- decision: verify the export/import asymmetry claim directly from source before writing anything, rather than reusing a prior closed PR's (#226) description uncritically, per explicit task instruction not to resurrect unverified prior text.

## Connector Evidence

- GitHub: repository reads and writes.

## Connector Usage Evidence

- source: GitHub repository `yotamfried-ux/Engineering-OS`, `scripts/monitoring/export-telemetry-run.py`, `scripts/monitoring/import-telemetry-run.py`.
- action: read both scripts in full to confirm exactly which side (export or import) actually scans bundle content for the metadata-only contract, rather than assuming symmetry.
- result: confirmed the asymmetry is real — export only labels the bundle, import is what actually validates content — and confirmed the existing audit/known-gaps wording does not overclaim sufficiency.
- decision: added the asymmetry detail to the audit's Monitoring metrics sufficiency row without changing its `Missing enforcement` status or claiming sufficiency, and left `known-gaps.tsv`'s `open` status and existing accurate wording untouched.
- target: docs/operations/operational-readiness-audit.md

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `plan.route-plan-before-write` — this plan committed before any doc edit.
- `source.github-repo-read` — repository files read.

## Claude Run Trace

- goal: verify the export/import telemetry metadata-only asymmetry claim directly from source, then make a small, honest documentation-only update to the audit's monitoring row describing exactly what is enforced (import-side content validation) versus what is not (export-side content is never scanned) — without claiming monitoring sufficiency and without touching `known-gaps.tsv` status or telemetry code.
- hypothesis: `export-telemetry-run.py` asserts a `metadata-only` label without scanning content, while `import-telemetry-run.py`'s `validate_metadata_only()` is the only place that actually scans bundle content against banned keys/patterns.
- connectors: GitHub.
- steps: read both telemetry scripts in full; confirm the asymmetry against real line numbers; update only the audit row's "What is enforced or checked" description; leave known-gaps.tsv and telemetry code untouched.
- evidence: direct line-number citations from `export-telemetry-run.py` (lines 94, 96, 114) and `import-telemetry-run.py` (lines 54-60, 78, 99).
- rejected: reusing the closed PR #226's description uncritically — rejected per explicit task instruction to re-verify fresh rather than trust a closed, unmerged PR's claims.
- result: pending commit and CI confirmation.
- follow-up: none — this PR does not close the gap; `monitoring-metrics-sufficiency` stays open until a real target-project run is imported and analyzed (depends on `project-8-real-run-evidence`).

## Lessons Reused

- `lessons-learned/bugs/ci-environment-dependent-fixture-premise.md` — verify locally against the exact same checker logic the CI runs, not an assumed simplification of it.

## Graphify Usage Evidence

- source: graphify explain query against graphify-out/graph.json.
- action: ran `graphify explain "export-telemetry-run.py"` and `graphify explain "operational-readiness-audit.md"` before editing.
- result: consistent with prior findings — these files are not covered by the graph (no nodes returned); verification was done by direct file reads instead of graph traversal.
- decision: treated this as a doc-only accuracy change scoped to the target file, verified by direct file reads of both telemetry scripts.
- target: docs/operations/operational-readiness-audit.md

## Alternatives

- Marking monitoring-metrics-sufficiency closed or "Enforced" — rejected; no real target-project run exists yet, and closing without one would violate the explicit task instruction never to claim monitoring sufficiency without a real run.
- Touching telemetry code to add export-side content scanning — rejected; out of scope for this task, which is explicitly a documentation-accuracy-only fix.
- Reusing closed PR #226's language verbatim — rejected; re-verified the claim fresh from current source instead.

## Affected Surfaces

- `docs/operations/operational-readiness-audit.md`.

## Data/State Impact

- No application data impact; documentation-only change.

## Integration Impact

- None — no code, config, or manifest files changed; no new or changed enforcement behavior.

## Validation Plan

- Run `bash scripts/enforcement/check-readiness-audit.sh` locally (must exit 0).
- Run `bash scripts/enforcement/check-known-gaps.sh` locally (must exit 0, confirming known-gaps.tsv is untouched and still consistent with the audit).
- Confirm `docs/operations/known-gaps.tsv` row 31 is byte-identical to before this PR (no status or wording change).
- Confirm zero open review threads before merge.

## Open Questions

- None outstanding for this scoped PR.

## Progress Lifecycle Evidence

- start: read both `export-telemetry-run.py` and `import-telemetry-run.py` in full before any doc edit, confirming the real asymmetry directly from source rather than reusing prior session or closed-PR claims.

## DoD

- [ ] Update `docs/operations/operational-readiness-audit.md`'s Monitoring metrics sufficiency row with the verified export/import asymmetry detail, without claiming sufficiency or changing its status.
- [ ] Confirm `docs/operations/known-gaps.tsv` is untouched (byte-identical diff shows no changes to that file).
- [ ] `check-readiness-audit.sh` passes locally.
- [ ] `check-known-gaps.sh` passes locally.
- [ ] Confirm both named CI gates and all other real policy checks pass on this PR's real CI run.
- [ ] Zero open review threads before merge.
