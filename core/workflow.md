# workflow.md

> Engineering OS workflow policy loaded from `CLAUDE.md`.

---

## <agent_loop>

Work in small loops: read source-of-truth files, plan, make a small change, verify, record state, and repeat.

</agent_loop>

---

## <workflow>

1. Planning: create or update a Notion spec or `.claude/plans/<name>.md` before code.

   Route Plan plus Result Loop requirement: for software/project work, the plan must name `selected_project_type`, `selected_template`, `selected_roadmap`, `selected_result_loop_contract`, `required_user_simulation`, `local_creator_review_path`, `telemetry_export_path`, and `evidence_redaction_rule` before implementation writes. Missing template, roadmap, or contract coverage requires an explicit waiver or known gap. A new project type must go through `docs/operations/scaling-extension-procedure.md`.

2. Evidence pass: read relevant templates, patterns, docs, existing code, and runtime evidence. Do not guess.

3. Tool and skill selection: select connectors and skills by task, and record the decision in the Route Plan.

4. Implementation plan: write 3 to 5 concrete steps.

   Write-entry gate: implementation starts only after requirements are understood, a trustworthy source and example exist, and the Route Plan has selected a result path or explicit waiver.

5. Iterative implementation: make small branch-scoped changes.

6. Result verification: CI is not enough when the project type requires visible, runtime, or output evidence. Verify using the selected tests, user simulation, local creator review, output evidence, monitoring/performance signal, change-impact comparison, and metadata-only telemetry export.

7. Cleanup and pre-commit review.

8. Commit using the git policy.

9. Spec loop: compare the result with the plan and close gaps.

10. Merge only after verification and user approval.

</workflow>

---

## <evidence_backed_planning>

Every plan must declare `Plan Scope: simple|standard|project`.

### Route Plan Result Loop Contract

For `standard` or `project` software/project work, a plan must include:

- `selected_project_type`
- `selected_template`
- `selected_roadmap`
- `selected_result_loop_contract`
- `required_user_simulation`
- `local_creator_review_path`
- `telemetry_export_path`
- `evidence_redaction_rule`

These fields enforce route selection or waiver before code. They do not replace the full Result Loop Contract gate. The field checker is `scripts/enforcement/check-route-plan-contract.py`; full manifest enforcement remains a separate audit item.

</evidence_backed_planning>

---

## <project_scaffold>

Use an approved template for an existing project type. A new project type must use `docs/operations/scaling-extension-procedure.md` before code.

</project_scaffold>

---

## <spec_loop>

At the end, compare the result with the plan before merge.

</spec_loop>

---

## <refactor_loop>

Refactor only when scoped by the task or required for a fix, and verify behavior before and after.

</refactor_loop>
