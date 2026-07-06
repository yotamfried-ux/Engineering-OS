# Engineering OS Telemetry Archive

This directory stores metadata-only telemetry exports from target projects that use Engineering OS.

It is not a monitoring-readiness claim. It is a place to keep evidence so real runs can be compared over time.

## Layout

```text
telemetry-archive/
  README.md
  runs/YYYY-MM-DD/<project_slug>/<run_id>/
    manifest.json
    events.jsonl
    latest-summary.md
    findings.md
  indexes/
    runs.jsonl
    projects.json
    gaps.jsonl
```

## Export

Run from the target project root:

```bash
bash /path/to/Engineering-OS/scripts/monitoring/export-telemetry-run.sh --out telemetry-export/project-8 --project project-8
```

The export bundle contains only:

```text
manifest.json
events.jsonl
latest-summary.md
```

A missing or empty `events.jsonl` fails unless `--empty-run` is passed explicitly.

## Import

Run from Engineering OS:

```bash
python3 scripts/monitoring/import-telemetry-run.py telemetry-export/project-8 --archive telemetry-archive
```

The importer validates the manifest, JSONL shape, required event fields, metadata-only contract, and duplicate run handling.

## Analyze

```bash
python3 scripts/monitoring/analyze-telemetry-archive.py telemetry-archive --project project-8
```

The analyzer compares event counts, session/turn/transcript/cwd coverage, command categories, and repeated missing coverage patterns.

## Data contract

Allowed data is metadata: ids, event names, hook/tool names, command categories and hashes, path metadata with hashes, repo/branch/SHA fields, session/turn/transcript/cwd hashes, response/error presence and hashes, and derived counts.

Do not archive original conversation text, original command text, original file paths, file contents, connector bodies, tool response bodies, environment dumps, or private transcript locations.

## Retention

Keep compact metadata and summaries in git only while they help Engineering OS improvement and readiness evidence. Move large historical bundles elsewhere if repository size becomes a maintenance risk.

## GitHub Actions artifacts

Target-project CI can upload an export bundle as an artifact. Artifacts are transport only; download and import them into this archive after review.

## Future Collector/backend mode

Do not build an OpenTelemetry Collector/backend pipeline before the local export/import/analyze path is proven on real target-project runs.
