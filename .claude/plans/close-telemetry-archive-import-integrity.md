# Route Plan — Close telemetry-archive-import-integrity

## Route Plan

| Field | Decision |
|---|---|
| Task type | telemetry import integrity hardening |
| Task class | `engineering_os_governance` |
| Domain tags | telemetry integrity, archive import, bundle identity, fail-closed validation |
| Plan Scope | focused |
| Planning Mode | implementation; reuse the existing shared validator rather than adding a second one |
| Task-router evidence | `core/task-router.md` routes Engineering OS telemetry/observability governance through `ops-readiness`. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, `core/coderabbit-policy.md` require plan-first writes, focused PR, exact-head CI, review, explicit owner approval, expected-head merge, post-merge proof. |
| Target paths | `.claude/plans/close-telemetry-archive-import-integrity.md`; `scripts/monitoring/import-telemetry-run.py`; `scripts/enforcement/tests/test-telemetry-archive.sh` |
| Templates | waiver — focused change to an existing importer and its existing test |
| Architecture guides | `docs/operations/runtime-telemetry-archive-audit-checklist.md`; `docs/operations/operational-readiness-audit.md` |
| Patterns | none — no new implementation pattern is introduced |
| External systems/connectors | GitHub |
| Skills | `writing-plans`; `verification-before-completion` |
| Validation gates | telemetry archive; telemetry boundary validation; remote telemetry handoff; telemetry trust boundaries; full enforcement; PR policy; exact-head CI; review |
| Evidence to check | `import-telemetry-run.py` contains no reference to `telemetry_handoff`; `validate_bundle()` already implements checksum, symlink, identity and boundary checks |
| User decisions required | owner approval before merge; owner approved requiring a synced bundle for import (2026-08-03) |

## Goal

Make direct archive import prove a bundle's integrity and identity **before** it writes
anything. The exporter and the handoff validator already verify checksums and run identity,
but `import-telemetry-run.py` never called that path — it accepted a bundle on schema and
privacy checks alone, so a mutated bundle, or one belonging to a different run, could reach
the archive.

## Scope

In: the importer's pre-mutation gate, its identity passthrough, the recorded integrity
decision, and the fixtures that exercise them.

Out: the exporter, the selector, `telemetry_handoff.validate_bundle()` itself, the analyzer,
and any gap status change. Rewriting the validator was explicitly rejected — it already does
this job correctly for the handoff path.

## Claude Run Trace

- **goal**: Make direct archive import prove a bundle's integrity and identity before it
  writes anything, so the archive cannot accept a mutated bundle or one from another run.
- **hypothesis**: The integrity logic already existed and was simply not on this code path —
  the fix is a call, not a new implementation.
- **connectors/tools**: GitHub connector for `origin/main` at `ee138b26`; local execution of
  `import-telemetry-run.py`, `test-telemetry-archive.sh`, and the full enforcement suite.
  The Notion connector is not authorized in this session, so no `notion_progress_validated`
  evidence is produced; per `core/connector-policy.md` fallback, the GitHub-backed record for
  this change — PR head SHA, required workflow conclusions, and review threads — is the
  progress evidence instead. No Notion state is claimed or inferred.
- **steps**: Read the importer and `telemetry_handoff.validate_bundle()` side by side; located
  every archive mutation point; added a pre-mutation gate that delegates to the shared
  validator; added only the checks it does not own; recorded the decision in the index;
  rebuilt fixtures as synced bundles via the real `write_handoff_manifest`; then verified each
  rejection's actual cause rather than only its exit status.
- **evidence**: `grep telemetry_handoff import-telemetry-run.py` returned nothing before the
  change. Validation now runs at line 214, the first mutation at line 243. Twelve negative
  fixtures each assert a per-file hash fingerprint of the archive is unchanged after
  rejection. Observed causes: boundary → `handoff boundary position is invalid`; policy →
  `invalid telemetry policy identity`; manifest replacement → `events checksum mismatch`;
  symlink → `required file is missing or not regular`; extra file → `outside the allowlist`.
  Full enforcement suite 112 suites / 0 failures.
- **rejected attempts**: (1) Reimplementing checksum and identity checks inside the importer —
  rejected because `validate_bundle()` already does exactly this for the handoff path, and a
  second copy would drift, which is the same defect class PR #266 removed. (2) Hand-writing
  the handoff manifest in fixtures — rejected because it would restate the manifest shape and
  silently pass if the real writer changed; the fixtures call `write_handoff_manifest`
  instead. (3) Allowing exporter-only bundles through a flag — rejected because it would
  reintroduce the hole the gap exists to close.
- **result**: The importer fails closed before any mutation, with every required rejection
  covered and the integrity decision recorded in the archive index.
- **follow-up**: Gap status changes only after exact-head CI, review, owner approval,
  expected-head merge, and post-merge validation.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `scripts/monitoring/import-telemetry-run.py` | read | Contains zero references to `telemetry_handoff`. Validation limited to manifest schema, event schema and banned-field scanning, so checksums and run identity were never compared on the direct import path. |
| `scripts/monitoring/telemetry_handoff.py` | read | `validate_bundle()` already covers regular non-symlink required files, events and summary SHA-256, manifest/handoff repository agreement, 40-hex head, 32-hex branch hash, run-id to `trace_id` correlation, non-empty run, terminal boundary position, and metadata-only privacy. Reused as-is; not replaced. |
| `scripts/monitoring/sync-telemetry-run.py` | read | `write_handoff_manifest()` is what adds the handoff block and checksums, so run, policy and boundary identity exist only after sync. This is why import must require a synced bundle, and why fixtures call this writer rather than hand-writing the manifest. |
| `scripts/monitoring/export-telemetry-run.py` | read | Emits `checksums.events_sha256` and `checksums.summary_sha256` at export time, so the values the importer must verify already exist and need no new format. |
| `docs/operations/known-gaps.tsv` | read | The gap's closure column requires byte mutation, summary mutation, manifest replacement, symlink/non-regular file, wrong repository, wrong branch/head/run, missing boundary and invalid policy fixtures to fail while one valid selected bundle imports. Used directly as the fixture list. |
| `scripts/enforcement/tests/test-telemetry-archive.sh` | read | Existing fixtures build exporter-only bundles with a bare `repo` value and no handoff block, so they must be rebuilt as synced bundles once import requires handoff identity. |

## Design

Call the existing validator, do not restate it.

1. `validate_before_mutation()` runs ahead of every write: rejects a symlinked bundle
   directory, rejects any file outside the `manifest.json` / `events.jsonl` /
   `latest-summary.md` allowlist, then delegates to `telemetry_handoff.validate_bundle()`.
2. Policy identity: a declared `policy` block must name `POLICY_SCHEMA`. Absent means
   compatible with existing bundles; present-and-wrong fails closed.
3. `--expected-repo`, `--expected-branch-hash`, `--expected-head-sha` and `--expected-run-id`
   pass straight through to the validator's existing `expected_*` parameters, so a caller can
   assert the bundle belongs to the run they think it does.
4. The archive index row records the integrity decision — validator name, that it ran before
   mutation, which checksums were verified, and any asserted identity — so a later reader can
   tell validation happened rather than assuming it.

Consequence, accepted by the owner: an exporter-only bundle no longer imports, because
`handoff` metadata is written by `sync-telemetry-run.py`. Fixtures therefore build **synced**
bundles by calling the real `write_handoff_manifest`, not by hand-writing the manifest shape.

## Capability Evidence

- `routing.task-router-read` — routed as Engineering OS telemetry/observability governance.
- `workflow.workflow-read` — plan-first write, then implementation, tests, CI, review, approval, merge, post-merge.
- `plan.route-plan-before-write` — this plan is committed before the first importer change.
- `source.github-repo-read` — live `origin/main` re-read before any claim.
- `validation.policy-change-has-validator` — every new rejection has a negative fixture.
- `validation.coderabbit-policy` — PR review required before merge.

## Skill Evidence

- `writing-plans` — scope, reuse decision, and non-goals recorded.
- `verification-before-completion` — implementation, focused tests, full suite, exact-head CI, review, approval, merge, and post-merge remain separate assertions.

## Connector Evidence

| Connector | Status | Evidence |
|---|---|---|
| GitHub | used | Re-read `origin/main` at `ee138b26`, the importer, the shared validator, and the known-gaps closure condition before planning. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS` `main`, plus the working tree for the importer and validator.
- action: compared what `import-telemetry-run.py` verifies against what `telemetry_handoff.validate_bundle()` already verifies, and located every archive mutation point.
- result: against `main` at `ee138b26b8d9aacedbc3fae350176c08ba49c7a6`, the importer had no reference to `telemetry_handoff` at all, so checksums, symlink status, repository/branch/head/run identity and terminal boundary were never checked on the direct import path.
- decision: reused `validate_bundle()` behind a pre-mutation gate rather than adding importer-local integrity logic; added only what the shared validator does not own — bundle-directory symlink rejection, the filename allowlist, policy-schema identity, and the recorded decision.
- target: `scripts/monitoring/import-telemetry-run.py`; `scripts/enforcement/tests/test-telemetry-archive.sh`.

## Documentation Asset Evidence

- internal: `docs/operations/runtime-telemetry-archive-audit-checklist.md`; `docs/operations/known-gaps.tsv`; `scripts/monitoring/telemetry_handoff.py`; `scripts/monitoring/export-telemetry-run.py`; `scripts/monitoring/sync-telemetry-run.py`.
- context7: no external vendor source applies — this is repository-internal bundle integrity, not a third-party API contract.
- decision: reused the existing validator and the existing archive index schema rather than introducing a new integrity format or a new document. `runtime-telemetry-archive-audit-checklist.md` already owns the archive contract.

## Progress Lifecycle Evidence

- start: Route Plan committed before the first importer change. Measured on `main` at `ee138b26b8d9aacedbc3fae350176c08ba49c7a6`: `import-telemetry-run.py` contained zero references to `telemetry_handoff`, and its first archive mutation (`rmtree`) ran after schema checks only.
- mid: added `validate_before_mutation()` ahead of every write, wired the four `expected_*` passthroughs, recorded the integrity decision in the archive index, and rebuilt the fixtures as synced bundles via the real `write_handoff_manifest`. Each of the twelve required rejections was then checked for *why* it failed, not just that it failed — the boundaryless case additionally proved that `sync-telemetry-run.py` itself refuses to write handoff metadata for a run with no terminal boundary, so two independent layers reject it.
- pre-merge: verified on the implementation head. Full enforcement suite 112 suites, 0 failures; `test-telemetry-archive.sh` carries 24 assertions including all 12 required negative integrity cases, each asserting a per-file `sha256sum` fingerprint of the whole archive is unchanged after rejection. Each rejection was checked for its actual cause rather than only its exit status: missing boundary reported `handoff boundary position is invalid`; invalid policy reported `invalid telemetry policy identity`; manifest replacement reported `events checksum mismatch`; a symlinked member reported `required file is missing or not regular`; an extra file reported `outside the allowlist`. Validation runs before the first archive mutation. `shellcheck` 0.9.0 reported no findings on the changed shell file. `check-connector-evidence.sh`, `check-documentation-asset-evidence.sh` and `check-capability-staged-changes.sh` pass against this plan. Recorded on PR #268.
- outstanding external gates: exact-head CI, live review reconciliation, explicit owner approval, expected-head protected merge, and post-merge validation. No gap status changes before all of those complete.

## Definition of Done — Implementation

- [x] Import calls one shared fail-closed validator before any archive write, index update, or replacement.
- [x] Regular non-symlink selected files, exact allowlisted filenames, event and summary checksums, event count, non-empty qualification mode, privacy contract, repository, branch, head, run, policy, handoff, and terminal boundary identity are all required.
- [x] A one-byte events mutation, summary mutation, manifest replacement, checksum mismatch, symlink, non-regular file, unexpected file, wrong repository, wrong branch, wrong head, wrong run, missing boundary, and invalid policy are each rejected, and each rejection leaves the archive byte-identical.
- [x] One valid selected bundle imports successfully, and the validation result is recorded in the archive index.
- [x] Exporter, selector, validator, importer and analyzer share the same identity vocabulary — the importer now reuses `telemetry_handoff` rather than paraphrasing it.

Remaining external gates, which this commit cannot satisfy and which are therefore not
implementation DoD items:

- focused and full exact-head CI on the PR head;
- live review reconciliation with zero unresolved threads;
- explicit owner approval for the final exact head;
- expected-head protected merge and post-merge validation;
- only then: the `known-gaps.tsv` row and the audit checklist move to closed.

## Validation Plan

1. `test-telemetry-archive.sh` — the regression for every rejection class.
2. `test-telemetry-boundary-validation.sh`, `test-remote-telemetry-handoff.sh`, `test-telemetry-trust-boundaries.py`.
3. Full enforcement suite.
4. Exact-head CI on the PR head; latest attempt only.
5. Reconcile every live review thread; do not weaken a gate to pass CI.
6. No merge without a new explicit owner approval for the final exact head.
