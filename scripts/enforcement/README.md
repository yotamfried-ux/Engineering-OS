# Enforcement Manifests

This directory contains machine-readable manifests used by Engineering OS enforcement scripts.

## Shared TSV conventions

Each manifest is a tab-separated file with a commented header line as the first schema row:

```text
# column_a	column_b	...
```

Rules for all scaling manifests:

- every non-comment row must have exactly the same number of columns as the header;
- every cell must be non-empty;
- every manifest must include `status` and `exemption_state`;
- allowed `status` values are `active`, `required`, `planned`, `deferred`, and `exempt`;
- allowed `exemption_state` values are `not_exempt`, `exempt`, `waiver_required`, `waived`, and `not_applicable`;
- path-like columns ending in `_path` must point to existing repository paths when the row is `active`, `required`, or `exempt` unless the value is `NONE` or an external URL;
- `planned` and `deferred` rows may use `NONE` for paths that are intentionally not created yet.

## Scaling manifests

| Manifest | Purpose | Required columns |
|---|---|---|
| `project-type-roadmaps.tsv` | Maps each project type to roadmap coverage and template/source paths. | `project_type_id`, `status`, `roadmap_label`, `source_doc_path`, `template_path`, `target_manifest_path`, `required_evidence`, `exemption_state`, `audit_link`, `gap_link` |
| `result-loop-requirements.tsv` | Records the required Result Loop Contract fields per project type. This is a schema foundation, not the final result-loop gate. | `project_type_id`, `status`, `source_doc_path`, `target_manifest_path`, `setup_command`, `run_command`, `visible_result`, `creator_local_review`, `required_tests`, `user_simulation`, `feedback_surfaces`, `performance_monitoring`, `acceptance_metrics`, `change_impact_measurement`, `telemetry_export`, `failure_repair_loop`, `evidence_artifacts`, `exemption_state`, `audit_link`, `gap_link` |
| `documentation-sources.tsv` | Registers official or trusted documentation sources used by project-type roadmaps. | `source_id`, `status`, `project_type_id`, `source_type`, `source_url`, `freshness_note`, `target_path`, `consult_rule`, `fallback_or_waiver`, `required_evidence`, `exemption_state`, `audit_link`, `gap_link` |
| `reference-repositories.tsv` | Reserves the registry shape for approved reference repositories and validation state. | `reference_id`, `status`, `project_type_id`, `repository_url`, `owner_type`, `usage_scope`, `license_usage_note`, `validation_status`, `validation_evidence`, `target_path`, `exemption_state`, `audit_link`, `gap_link` |
| `code-example-requirements.tsv` | Reserves the registry shape for example code, run paths, and validation paths. | `example_id`, `status`, `project_type_id`, `example_path`, `run_path`, `validation_path`, `owner`, `source_reference`, `required_evidence`, `exemption_state`, `audit_link`, `gap_link` |
| `pattern-requirements.tsv` | Maps project types to pattern inventory usage expectations. | `pattern_requirement_id`, `status`, `project_type_id`, `source_path`, `target_path`, `usage_rule`, `enforcement_rule`, `required_evidence`, `exemption_state`, `audit_link`, `gap_link` |
| `skill-requirements.tsv` | Maps project types to skill-selection evidence expectations. | `skill_requirement_id`, `status`, `project_type_id`, `source_path`, `target_path`, `trigger_rule`, `evidence_rule`, `exemption_state`, `audit_link`, `gap_link` |
| `connector-workflow-requirements.tsv` | Extends connector inventory requirements with workflow evidence and fallback rules without changing `connector-requirements.tsv`. | `connector_requirement_id`, `status`, `connector_id`, `source_path`, `target_path`, `workflow_scope`, `required_evidence`, `fallback_rule`, `exemption_state`, `audit_link`, `gap_link` |

## Adding a row

1. Pick a stable lowercase id.
2. Add the row to the relevant manifest.
3. Use `active` only when referenced paths and evidence expectations are already true.
4. Use `planned` or `deferred` for registry placeholders that should not claim readiness yet.
5. Add `audit_link` and `gap_link`; use `none` only when no open gap is required.
6. Run `bash scripts/enforcement/tests/test-scaling-manifests.sh`.

## Non-goals

These manifests do not implement the final scaling gate or the final result-loop gate. They only establish the registry-backed source-of-truth layer that later gates can load.
