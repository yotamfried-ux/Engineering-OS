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

Responsibilities:

- [ ] Locate the target project root using `git rev-parse --show-toplevel` with a safe fallback to `pwd`.
- [ ] Locate `.engineering-os/telemetry/events.jsonl`.
- [ ] Locate `.engineering-os/telemetry/latest-summary.md`.
- [ ] Read `.engineering-os/telemetry/run_id` if present.
- [ ] Create an export bundle directory.
- [ ] Copy events and summary into the bundle.
- [ ] Generate `manifest.json`.
- [ ] Count events.
- [ ] Fail clearly if no events file exists unless an explicit empty-run mode is provided.
- [ ] Avoid copying unrelated local files.

Initial command shape:

```bash
bash scripts/monitoring/export-telemetry-run.sh --out telemetry-export/project-8
```

## Required import command

Create:

```text
scripts/monitoring/import-telemetry-run.py
```

Responsibilities:

- [ ] Read an export bundle.
- [ ] Validate `manifest.json`.
- [ ] Validate `events.jsonl` is valid JSONL.
- [ ] Validate every event has `schema_version`, `trace_id`, `span_id`, `name`, `timestamp`, `resource`, and `attributes`.
- [ ] Validate no banned raw fields are present.
- [ ] Copy bundle into `telemetry-archive/runs/<date>/<project>/<run_id>/`.
- [ ] Create or update `findings.md` placeholder.
- [ ] Append a row to `telemetry-archive/indexes/runs.jsonl`.
- [ ] Avoid duplicate import unless `--replace` is explicitly used.

Initial command shape:

```bash
python3 scripts/monitoring/import-telemetry-run.py telemetry-export/project-8 --archive telemetry-archive
```

## Required analyzer command

Create:

```text
scripts/monitoring/analyze-telemetry-archive.py
```

Responsibilities:

- [ ] Read `telemetry-archive/indexes/runs.jsonl`.
- [ ] Compare event counts by project.
- [ ] Compare missing session/turn/transcript/cwd coverage.
- [ ] Compare command category distribution.
- [ ] Surface repeated missing coverage patterns.
- [ ] Produce a markdown report that can become or update `findings.md`.

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

- [ ] Add `scripts/monitoring/export-telemetry-run.sh`.
- [ ] Add `scripts/monitoring/import-telemetry-run.py`.
- [ ] Add `scripts/monitoring/analyze-telemetry-archive.py`.
- [ ] Add `telemetry-archive/README.md`.
- [ ] Add `.gitkeep` or documented empty archive directory strategy.
- [ ] Add tests in `scripts/enforcement/tests/test-telemetry-archive.sh`.

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
