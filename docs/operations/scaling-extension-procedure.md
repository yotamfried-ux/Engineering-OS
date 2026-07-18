# Scaling Extension Procedure

Purpose: make Engineering OS scalable when adding new project types, documentation sources, reference repositories, templates, patterns, skills, or code examples.

The goal is that adding a new project type, such as a computer game, should not require reinventing the OS. The addition must fit a fixed structure and then become part of routing, planning, result-loop contracts, roadmap selection, CI evidence, and enforcement.

This procedure is not a readiness claim. Enforcement work is tracked in `docs/operations/result-loop-contract-audit-checklist.md`.

## Scaling principle

Every new extension must be added through a registry-backed path.

Do not add one-off guidance that only exists in a conversation, pull request body, or free-form document. If a new asset affects how software is built, it must be discoverable by the workflow and enforceable by CI or an explicit waiver.

## Extension types

| Extension type | Examples | Required registry or source of truth |
|---|---|---|
| Project type | game-development, IoT app, XR app, plugin, SDK/library | `templates/README.md`, `scripts/enforcement/template-requirements.tsv`, `docs/operations/project-type-roadmaps.md`, result-loop contract manifest. |
| Template | `templates/game-development/` | Template directory plus template requirement row and result-loop contract row. |
| Official documentation source | Unity docs, Unreal docs, Android docs, OpenTelemetry docs | `docs/operations/project-type-roadmaps.md` or a future docs-source manifest. |
| Reference repository | official sample repo, framework example, starter project | `docs/reference-repositories/` entry or future reference-repository manifest. |
| Pattern | architecture/testing/UI/observability pattern | pattern directory plus required-pattern rule or explicit exemption. |
| Skill | specialized workflow or tool-use skill | skills inventory plus required-skill rule or explicit exemption. |
| Code example | starter code, example workflow, CI sample | template README, examples directory, or reference repo entry with test evidence. |
| Connector | GitHub, Notion, monitoring backend, deployment provider | connector inventory plus connector requirement rule and evidence policy. |

## Required workflow for adding a new project type

A new project type is not complete until all of these are done:

1. Define the project type id.
2. Add or explicitly defer the template.
3. Add a `templates/README.md` row or a Known Gap row.
4. Add a `scripts/enforcement/template-requirements.tsv` rule or explicit exemption.
5. Add a project roadmap entry in `docs/operations/project-type-roadmaps.md`.
6. Add official source references for creation, local run, testing, user simulation, monitoring, performance, and deployment where relevant.
7. Add result-loop contract fields for local creator review, user simulation, feedback artifacts, performance metrics, change-impact measurement, telemetry export, and repair loop.
8. Add or link reference repositories or example code when available.
9. Add positive and negative enforcement fixtures.
10. Wire the new rule into CI or confirm it is already covered by a manifest coverage test.
11. Update the audit checklist and known gaps honestly.
12. Run CI and do not close the gap until enforcement and real-run evidence exist.

## Required workflow for adding documentation

A documentation source is not complete until it has:

- official or clearly trusted source URL;
- reason it applies to a specific project type or workflow stage;
- freshness/version notes when the source is versioned;
- target path where the source is referenced;
- rule for when the AI must consult it;
- fallback or waiver behavior when the source is unavailable;
- audit entry if the source is required for readiness.

## Required workflow for adding reference repositories

A reference repository is not complete until it has:

- repository URL and owner/source type;
- reason it is relevant;
- supported project type/template;
- what should be copied, adapted, or only studied;
- license/usage note;
- test or evidence proving the example still runs, or an explicit stale/unverified label;
- result-loop evidence path if it is used as a starter.

## Required workflow for adding templates and code examples

A template or code example is not complete until it has:

- README with scope, stack, local setup, local run, tests, deployment, security, observability, and result-loop requirements;
- starter commands or links to official scaffolders;
- testing checklist and at least one negative-path requirement;
- telemetry/export instructions;
- roadmap entry;
- template requirement manifest row;
- fixture coverage for selection, missing-template, and waiver behavior;
- no claim of production readiness without an actual target-project run.

## Game-development example

If adding `game-development`, the fixed path should be:

- add `game-development` to `templates/README.md` or Known Gaps;
- add `game-development` to `scripts/enforcement/template-requirements.tsv`;
- add a roadmap row using official engine docs such as Unity Manual, Unity Profiler, Unreal Engine docs, Godot docs, and engine-specific testing/profiling docs;
- define local creator run path: editor play mode, local build, simulator/device, or packaged game;
- define user simulation path: engine test runner, input playback, bot/playtest script, or automation framework;
- define performance metrics: frame time, FPS, memory, load time, hitching, input latency, crash/error rate;
- define visual/gameplay evidence: screenshots, videos, replay files, logs, profiler traces;
- define before/after comparison for gameplay, visual, and performance changes;
- define telemetry export into the archive;
- add fixtures proving CI fails when any required part is missing.

## Enforcement requirements

The scaling gate must fail when:

- a new template directory is added without a template requirement row;
- a new project type is named in docs or plans but has no roadmap entry or explicit exemption;
- a roadmap entry is added without official sources;
- a template is added without local run, creator review, tests, user simulation, monitoring, telemetry, and repair loop fields;
- a reference repository is added without source, license/usage note, relevance, and freshness status;
- a code example is added without a way to run or validate it;
- an audit checklist marks a scaling item complete before the enforcement artifact exists.

## Minimum scalable architecture

The long-term target is manifest-driven extension:

- `scripts/enforcement/template-requirements.tsv` for template routing.
- A future `scripts/enforcement/project-type-roadmaps.tsv` for roadmap coverage.
- A future `scripts/enforcement/result-loop-requirements.tsv` for required contract fields per project type.
- A future `scripts/enforcement/reference-repositories.tsv` for approved example repos.
- CI fixtures for every new row.

When these manifests exist, adding a new project type should mostly mean adding rows and a template folder, not writing new one-off logic.
