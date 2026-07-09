# Runtime Telemetry Archive Plan

Status: planned
Owner: observability-governance
Purpose: turn local Engineering OS telemetry files into a durable archive and learning loop that can be used after Project 8 and future target-project runs.

This plan is the tracking document for building central runtime telemetry storage. It intentionally does not claim monitoring readiness until real target-project runs prove that the collected data is sufficient for investigation and improvement.

## Audit tracking checklist

- [ ] Confirm Project 8 runs on a version of Engineering OS that includes PR #205 or later.
- [ ] Export the local target-project telemetry bundle after Project 8.
- [ ] Import the bundle into a central Engineering OS archive location.
- [ ] Validate the imported bundle schema and privacy contract.
- [ ] Build run indexes for project, branch, head SHA, run id, start/end time, event count, and summary path.
- [ ] Add a findings document for Project 8 after reviewing the imported data.
- [ ] Compare Project 8 with at least one future target-project run.
- [ ] Identify missing event coverage, missing correlation coverage, and missing failure coverage.
- [ ] Convert recurring missing coverage into tracked known gaps.
- [ ] Decide whether local archive is enough or whether an OpenTelemetry Collector pipeline is needed.
- [ ] Add CI or command fixtures proving export/import behavior.
- [ ] Update operational readiness status only after real run evidence exists.

## Source-of-truth documentation checked

| Source | Why it matters | Design implication |
|---|---|---|
| Claude Code hooks documentation: `https://docs.anthropic.com/en/docs/claude-code/hooks` | Hook commands receive JSON input and are the correct place to collect session/tool lifecycle data. | Keep collection at the hook layer and avoid scraping generated text. |
| OpenTelemetry Collector configuration: `https://opentelemetry.io/docs/collector/configuration/` | Collector architecture is receivers, processors, exporters, and service pipelines. Components must be wired into pipelines before they are active. | Model Engineering OS archive as ingest/export, validate/process, store/export, and later optionally a Collector pipeline. |
| OpenTelemetry filelog receiver: `https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/receiver/filelogreceiver` | Official receiver for reading local log files, including JSON-style log files. | Future collector mode can read `.engineering-os/telemetry/events.jsonl` from target projects. |
| OpenTelemetry file exporter: `https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/exporter/fileexporter` | Official exporter for writing telemetry to files, with file path and rotation options. | Archive storage should use appendable structured files and retention rules instead of ad hoc scattered logs. |
| OpenTelemetry batch processor: `https://github.com/open-telemetry/opentelemetry-collector/tree/main/processor/batchprocessor` | Official processor for batching telemetry before export. | Future collector mode should batch writes instead of processing one event at a time. |
| OpenTelemetry memory limiter processor: `https://github.com/open-telemetry/opentelemetry-collector/tree/main/processor/memorylimiterprocessor` | Official processor for reducing memory risk under telemetry load. | Future collector mode should protect long runs from memory growth. |
| GitHub Actions artifacts: `https://docs.github.com/en/actions/tutorials/store-and-share-data` | Official way to store workflow outputs for later download and review. | If a target run happens in CI, telemetry export must be uploaded as an artifact or it will be lost with the runner. |

## Current baseline after PR #205

Local target-project telemetry exists at:

```text
.engineering-os/telemetry/events.jsonl
.engineering-os/telemetry/latest-summary.md
.engineering-os/telemetry/run_id
```

The current baseline records safe metadata for local investigation, including trace/span ids, event name, hook/tool name, command category, target path metadata, resource attributes, and hashed correlation fields for session, turn, transcript path, and working directory.

The current baseline is intentionally metadata-only. It must not store raw model text, file contents, raw shell commands, raw paths, connector payloads, environment values, credentials, or other sensitive values.

## Problem to solve

Local telemetry is useful for one run, but it is not enough for long-term system learning. If every target project keeps telemetry only in its own local `.engineering-os/telemetry/` directory, Engineering OS cannot easily compare runs, detect recurring gaps, measure coverage over time, or improve policies based on real evidence.

The update must create a durable archive owned by Engineering OS while preserving the local privacy model.

## Target architecture

```text
Target project run
  .engineering-os/telemetry/events.jsonl
  .engineering-os/telemetry/latest-summary.md
  .engineering-os/telemetry/run_id
        |
        v
Export bundle
  manifest.json
  events.jsonl
  latest-summary.md
        |
        v
Engineering OS central archive
  telemetry-archive/runs/<date>/<project>/<run_id>/
  telemetry-archive/indexes/runs.jsonl
  telemetry-archive/indexes/projects.json
  telemetry-archive/indexes/gaps.jsonl
        |
        v
Post-run findings and readiness decisions
```

## Proposed archive layout

```text
telemetry-archive/
  README.md
  runs/
    YYYY-MM-DD/
      <project_slug>/
        <run_id>/
          manifest.json
          events.jsonl
          latest-summary.md
          findings.md
  indexes/
    runs.jsonl
    projects.json
    gaps.jsonl
```

`telemetry-archive/README.md` explains the privacy contract, folder structure, import/export workflow, retention policy, and review process.

`runs/<date>/<project>/<run_id>/manifest.json` records run metadata and schema version.

`runs/<date>/<project>/<run_id>/events.jsonl` stores the metadata-only events from the target project.

`runs/<date>/<project>/<run_id>/latest-summary.md` stores the summary generated by the target project.

`runs/<date>/<project>/<run_id>/findings.md` is written after review and records what the run taught us.

`indexes/runs.jsonl` is the append-only index for comparing runs.

`indexes/projects.json` is the project registry for known target projects.

`indexes/gaps.jsonl` records telemetry gaps discovered across runs before they become formal known gaps.

## Required manifest fields

```json
{
  "schema_version": "eos.telemetry.run.v1",
  "run_id": "<hashed-or-safe-run-id>",
  "project": "project-8",
  "project_slug": "project-8",
  "repo": "<safe repo URL or repo name>",
  "branch": "<branch>",
  "head_sha": "<sha>",
  "engineering_os_head_sha": "<sha>",
  "exported_at": "<UTC timestamp>",
  "source_telemetry_dir": ".engineering-os/telemetry",
  "events_file": "events.jsonl",
  "summary_file": "latest-summary.md",
  "event_count": 0,
  "privacy_contract": "metadata-only"
}
```

## Required export command

Create:

```text
scripts/monitoring/export-telemetry-run.sh
```

Responsibilities (implemented in `scripts/monitoring/export-telemetry-run.py`, wrapped by `export-telemetry-run.sh`; verified against the actual source below):

- [x] Locate the target project root using `git rev-parse --show-toplevel` with a safe fallback to `pwd` (`repo_root()`).
- [x] Locate `.engineering-os/telemetry/events.jsonl`.
- [x] Locate `.engineering-os/telemetry/latest-summary.md`.
- [x] Read `.engineering-os/telemetry/run_id` if present.
- [x] Create an export bundle directory.
- [x] Copy events and summary into the bundle.
- [x] Generate `manifest.json`.
- [x] Count events.
- [x] Fail clearly if no events file exists unless an explicit empty-run mode is provided.
- [x] Avoid copying unrelated local files (only `events.jsonl`, `latest-summary.md`, and the generated `manifest.json` are written to the bundle).

Initial command shape:

```bash
bash scripts/monitoring/export-telemetry-run.sh --out telemetry-export/project-8
```

## Required import command

Create:

```text
scripts/monitoring/import-telemetry-run.py
```

Responsibilities (implemented in `scripts/monitoring/import-telemetry-run.py`; verified against the actual source below):

- [x] Read an export bundle.
- [x] Validate `manifest.json` (`validate_manifest()`).
- [x] Validate `events.jsonl` is valid JSONL (`load_events()`).
- [x] Validate every event has `schema_version`, `trace_id`, `span_id`, `name`, `timestamp`, `resource`, and `attributes` (`EVENT_REQUIRED`).
- [x] Validate no banned raw fields are present (`validate_metadata_only()`, `BANNED_KEYS`/`BANNED_PATTERNS`).
- [x] Copy bundle into `telemetry-archive/runs/<date>/<project>/<run_id>/`.
- [x] Create or update `findings.md` placeholder.
- [x] Append a row to `telemetry-archive/indexes/runs.jsonl`.
- [x] Avoid duplicate import unless `--replace` is explicitly used.

Initial command shape:

```bash
python3 scripts/monitoring/import-telemetry-run.py telemetry-export/project-8 --archive telemetry-archive
```

## Required analyzer command

Create:

```text
scripts/monitoring/analyze-telemetry-archive.py
```

Responsibilities (implemented in `scripts/monitoring/analyze-telemetry-archive.py`; verified against the actual source below):

- [x] Read `telemetry-archive/indexes/runs.jsonl`.
- [x] Compare event counts by project (`Project-level summary`: min/max/total events).
- [x] Compare missing session/turn/transcript/cwd coverage (`coverage_counts()`).
- [x] Compare command category distribution (`command_categories()`).
- [x] Surface repeated missing coverage patterns (`Recurring missing coverage`, requires ≥2 affected runs).
- [x] Produce a markdown report that can become or update `findings.md` (`--output` writes the report to any target path).

Initial command shape:

```bash
python3 scripts/monitoring/analyze-telemetry-archive.py telemetry-archive --project project-8
```

## Required CI artifact workflow pattern

If a target-project run happens in GitHub Actions, add an optional artifact step:

```yaml
- name: Export Engineering OS telemetry
  if: always()
  run: |
    bash scripts/monitoring/export-telemetry-run.sh --out telemetry-export

- name: Upload Engineering OS telemetry
  if: always()
  uses: actions/upload-artifact@v4
  with:
    name: engineering-os-telemetry-${{ github.run_id }}
    path: telemetry-export
    retention-days: 30
```

The artifact step is not the final archive. It is a transport mechanism for CI runs. The durable archive remains in Engineering OS or in a later approved storage backend.

## Optional future OpenTelemetry Collector mode

Do not build this first. Use it only after the local export/import path works.

Collector-aligned design:

```yaml
receivers:
  filelog/eos:
    include:
      - /workspaces/*/.engineering-os/telemetry/events.jsonl
    start_at: beginning
    operators:
      - type: json_parser
        parse_from: body

processors:
  memory_limiter:
    check_interval: 1s
    limit_mib: 256
    spike_limit_mib: 64
  batch:
    timeout: 5s
    send_batch_size: 1000

exporters:
  file/eos_archive:
    path: /data/eos-telemetry.json
    rotation:
      max_megabytes: 10
      max_days: 30
      max_backups: 30
    format: json

service:
  pipelines:
    logs/eos:
      receivers: [filelog/eos]
      processors: [memory_limiter, batch]
      exporters: [file/eos_archive]
```

Collector mode is useful when there are many projects, large runs, or a need to forward telemetry into an external observability backend. Until then, a deterministic local archive is simpler and more auditable.

## Privacy contract

The archive must preserve the same privacy model as local telemetry.

Allowed:

- [ ] trace id and span id.
- [ ] event name.
- [ ] hook/tool name.
- [ ] command category.
- [ ] command hash.
- [ ] target path metadata and path hash.
- [ ] repo name.
- [ ] branch.
- [ ] short/head SHA.
- [ ] active plan basename.
- [ ] session hash.
- [ ] turn hash.
- [ ] transcript hash.
- [ ] cwd hash.
- [ ] response/error presence and hash.
- [ ] counts and summaries derived from allowed fields.

Not allowed:

- [ ] raw model text.
- [ ] raw user text.
- [ ] raw shell command.
- [ ] raw file path.
- [ ] file contents.
- [ ] raw connector payloads.
- [ ] raw tool responses.
- [ ] environment values.
- [ ] credentials or secrets.
- [ ] private transcript path.

## Project 8 run checklist (readiness reference, not an authorization to run)

This section ties the export/import/analyze commands above into one concrete
run-day sequence for whenever Project 8 (or any target project) is actually
authorized to run. It is a readiness reference only: it does not run Project 8,
does not import telemetry, and does not claim `monitoring-metrics-sufficiency` or
`project-8-real-run-evidence` (`docs/operations/known-gaps.tsv`) are closed. As of
this writing, `telemetry-archive/indexes/runs.jsonl` and `indexes/gaps.jsonl` are
empty and `indexes/projects.json` is empty — confirmed directly, not assumed —
because no real target-project run has ever been imported.

**Before the run:**

1. Confirm the target project's Engineering OS reference includes this archive
   layer (PR #205 or later) and the Operational Work History layer (PR #233 or
   later, for correlating the run with any PRs it produces).
2. Confirm which environment will actually run Claude for the target project. This
   matters because of the same-workspace caveat already documented in
   `docs/operations/operational-work-history-rollout.md` (Stage 1.5): telemetry
   only exports usefully from the exact environment/workspace where
   `.engineering-os/telemetry/events.jsonl` was actually written during the
   session. If the target project's Claude session and the export step run in
   different environments (the common case — including most CI runners and
   remote sessions), export the bundle from within the same session/workspace
   that did the work, not from a separate CI job that never saw that telemetry
   directory.
3. Decide the `--project` / `--project-slug` values up front (e.g. `project-8`) so
   the manifest, archive path, and `indexes/projects.json` entries stay
   consistent across the run and any later comparison runs.

**Run-day sequence:**

1. Export: `bash scripts/monitoring/export-telemetry-run.sh --out telemetry-export/<project-slug> --project <project-slug>` from the target project's own workspace, after real work has happened (so `events.jsonl` is non-empty). Use `--empty-run` only for an explicit, deliberate empty-run record, never to paper over a missing telemetry directory.
2. Import: `python3 scripts/monitoring/import-telemetry-run.py telemetry-export/<project-slug> --archive telemetry-archive` from the Engineering OS repo. This is the step that actually validates the metadata-only contract (`validate_metadata_only()`) — the export step only labels the bundle, it does not scan content (documented asymmetry, already recorded in `docs/operations/operational-readiness-audit.md`'s Monitoring metrics sufficiency row; not a bug, a known design point re-verified against source this session).
3. Analyze: `python3 scripts/monitoring/analyze-telemetry-archive.py telemetry-archive --project <project-slug> --output telemetry-archive/runs/<date>/<project-slug>/<run_id>/findings.md` (or review the printed report directly) to get the run/project comparison tables the importer's placeholder `findings.md` does not fill in by itself.

**Fields to review after import (source: the importer's own required schema, not a new manual field):**

- From `manifest.json` / the `indexes/runs.jsonl` row: `event_count`, `privacy_contract` (must read `metadata-only`), `head_sha`, `engineering_os_head_sha`, `branch`, `exported_at`.
- From the index row's `coverage` object: `missing_session`, `missing_turn`, `missing_transcript`, `missing_cwd` counts — these are the concrete signals for "did the hook layer actually capture what we expect," not a subjective read.
- From the analyzer report: command-category distribution, and the `## Recurring missing coverage` section, which only fires once a pattern has appeared in ≥2 imported runs — so it stays silent (correctly) until Project 8 plus at least one later comparison run both exist.
- Confirm the importer did not reject the bundle (`TelemetryImportError`) for a banned key/pattern — a rejection here is itself a finding worth investigating, not just a retry-until-it-passes obstacle.

**How findings should flow into existing artifacts (no new tracking surface):**

- Update `docs/operations/runtime-telemetry-archive-audit-checklist.md`'s "Project 8 evidence" and "Longitudinal learning" checkboxes only from the actual import/analysis results, one at a time, the same way `check-known-gaps.sh` already requires known-gaps status to match reality.
- If the analyzer's recurring-coverage section fires (≥2 runs affected), open a known-gap row in `docs/operations/known-gaps.tsv` describing the specific missing-coverage pattern, rather than silently accepting it or fixing it ad hoc.
- Update `docs/operations/operational-readiness-audit.md`'s Monitoring metrics sufficiency row from the real findings, not from expectation — only close `monitoring-metrics-sufficiency` once real Project 8 evidence plus at least one later comparison run both exist, per that gap's own closure text.
- If a recurring pattern reveals an actual bug or a repeatedly-wrong assumption (not just missing coverage), route it through `core/learning-loop.md` as a lesson (`lessons-learned/bugs/` or `failed-solutions/`) — do not invent a new free-text findings field; `findings.md` plus the existing learning-loop schema are the two surfaces this already routes through.

## Validation checklist

- [ ] Unit test: export fails clearly when events are missing.
- [ ] Unit test: export creates manifest/events/summary bundle.
- [ ] Unit test: import rejects invalid manifest.
- [ ] Unit test: import rejects invalid JSONL.
- [ ] Unit test: import rejects banned raw fields.
- [ ] Unit test: import writes archive run path.
- [ ] Unit test: import appends `indexes/runs.jsonl`.
- [ ] Unit test: duplicate import is rejected unless `--replace` is provided.
- [ ] Unit test: analyzer reports event count, missing correlation, and command categories.
- [ ] Simulation: Project 8 sample bundle can be exported and imported.
- [ ] Simulation: GitHub Actions artifact bundle shape is compatible with import.
- [ ] Documentation: README explains manual and CI paths.
- [ ] Audit: operational-readiness-audit links to this plan while the update is in progress.

## Rollout checklist

### Phase 1: planning and archive shape

- [x] Research official docs and examples.
- [x] Define target archive layout.
- [x] Define export/import/analyzer commands.
- [x] Define privacy contract.
- [x] Add this tracking plan.
- [ ] Add audit tracking checkbox/row.

### Phase 2: implementation

- [x] Add `scripts/monitoring/export-telemetry-run.sh` (thin wrapper around `export-telemetry-run.py`).
- [x] Add `scripts/monitoring/import-telemetry-run.py`.
- [x] Add `scripts/monitoring/analyze-telemetry-archive.py`.
- [x] Add `telemetry-archive/README.md`.
- [x] Empty archive directory strategy: `telemetry-archive/indexes/` is committed with real (currently empty/near-empty) index files (`runs.jsonl`, `gaps.jsonl`, `projects.json`) rather than a `.gitkeep`, and `README.md` documents the layout — no target-project run has populated `telemetry-archive/runs/` yet.
- [x] Add tests in `scripts/enforcement/tests/test-telemetry-archive.sh`.

### Phase 3: Project 8 run

- [ ] Run Project 8 with Engineering OS main containing PR #205 or later.
- [ ] Export Project 8 telemetry bundle.
- [ ] Import Project 8 telemetry bundle into the archive.
- [ ] Write `findings.md` for Project 8.
- [ ] Identify missing coverage.
- [ ] Convert missing coverage into either implementation work or known gaps.

### Phase 4: longitudinal learning

- [ ] Import at least one additional target-project run.
- [ ] Compare Project 8 against another run.
- [ ] Track repeated failure/missing-data patterns.
- [ ] Add archive analyzer report.
- [ ] Decide if Collector mode is warranted.
- [ ] Update operational readiness only after evidence from multiple runs.

## Definition of done for the archive update

The archive update is done only when all of these are true:

- [ ] Export command works from a target project.
- [ ] Import command works from Engineering OS.
- [ ] Archive layout is documented.
- [ ] Index files are generated.
- [ ] Privacy validation rejects banned fields.
- [ ] Tests cover positive and negative cases.
- [ ] Project 8 telemetry is imported.
- [ ] Project 8 findings are written.
- [ ] At least one post-Project 8 comparison is possible.
- [ ] Audit status is updated based on evidence, not expectation.

## Non-goals for the first archive PR

- [ ] Do not build a full OpenTelemetry Collector deployment yet.
- [ ] Do not add an external database yet.
- [ ] Do not store telemetry in GitHub issues as the primary archive.
- [ ] Do not store raw text or payloads for easier debugging.
- [ ] Do not close monitoring readiness based only on local tests.

## Open decisions

- [ ] Should `telemetry-archive/runs/` live in the repo, in artifacts, or in a separate private storage location?
- [ ] What retention period should be used for local archive files?
- [ ] Should large `events.jsonl` files be compressed before archive?
- [ ] Should Project 8 telemetry be imported manually first, or through CI artifact download?
- [ ] Should archive import create a formal known-gap row when missing coverage crosses a threshold?

## Recommended next PR scope

Build the archive without over-scoping:

- [ ] Create export command.
- [ ] Create import command.
- [ ] Create archive README.
- [ ] Create one test script with positive and negative fixtures.
- [ ] Keep Collector mode as documented future path.

Only after Project 8 produces real telemetry should the project decide whether to close any monitoring gap or expand the archive into a full Collector/backend architecture.
