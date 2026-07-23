from pathlib import Path
import json


def replace_once(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected exactly one source match, found {count}")
    p.write_text(text.replace(old, new, 1))


old_gap = "documentation-runtime-state-drift\tdocs-governance\topen\tP1\tActive documentation, manifests, checklists, and analyzer wording can contradict executable owners or assign the same readiness concept to multiple owners, causing an LLM or operator to act on stale runtime, inventory, review, telemetry, or lifecycle claims.\tAssign one canonical owner per runtime/readiness claim; reconcile CLAUDE, README, MANIFEST.tsv, capability state, CodeRabbit policy, telemetry plan/analyzer, and first-run versus longitudinal terminology; add bidirectional drift regressions without rewriting historical evidence.\tscripts/enforcement/tests/test-documentation-hygiene.sh\tOpen until every identified contradiction is reconciled, fixtures reject recurrence in both directions, focused/full exact-head CI and review pass, the owner approves merge, and post-merge validation confirms canonical main.\tscripts/enforcement/check-documentation-hygiene.sh\tPR #256 covered wording/inventory/reviewer reconciliation. Branch claude/operational-readiness-eos-c6ykfs (based on main df01a8fea1...) adds the MANIFEST.tsv reconciliation, telemetry-terminology guard, canonical ownership rows, and bidirectional fixtures; local full enforcement suite passes. Do not close until exact-head CI, review, owner-approved merge, and post-merge validation on main are also proven."
new_gap = "documentation-runtime-state-drift\tdocs-governance\tclosed\tP1\tActive documentation, manifests, checklists, and analyzer wording can contradict executable owners or assign the same readiness concept to multiple owners, causing an LLM or operator to act on stale runtime, inventory, review, telemetry, or lifecycle claims.\tAssign one canonical owner per runtime/readiness claim; reconcile CLAUDE, README, MANIFEST.tsv, capability state, CodeRabbit policy, telemetry plan/analyzer, and first-run versus longitudinal terminology; add bidirectional drift regressions without rewriting historical evidence.\tscripts/enforcement/tests/test-documentation-hygiene.sh\tClosed after PR #260 exact head e63a27babb09da4a7c4589cbe3e37c112f6b6e79 passed the latest required PR workflows including pr-policy 1692 and enforcement-tests 1391, all 7 review threads were resolved, owner approval comment 5063627361 authorized an expected-head protected merge, and main became identical to merge commit 105ecd0d0dc72aa847d11b193190689dbda0dda8; the canonical live-state claim requires successful post-merge push workflows.\tdocs/operations/live-state-claims.json\tPR #256 reconciled capability, inventory, and reviewer wording. PR #260 completed MANIFEST/runtime parity, telemetry terminology, canonical ownership, and bidirectional fixtures."
replace_once("docs/operations/known-gaps.tsv", old_gap, new_gap)

claims_path = Path("docs/operations/live-state-claims.json")
data = json.loads(claims_path.read_text())
claim_id = "engineering-os-pr-260-documentation-runtime-state-drift"
if any(c.get("claim_id") == claim_id for c in data.get("claims", [])):
    raise SystemExit(f"duplicate live-state claim: {claim_id}")
data["claims"].append({
    "claim_id": claim_id,
    "gap_id": "documentation-runtime-state-drift",
    "repository": "yotamfried-ux/Engineering-OS",
    "pull_number": 260,
    "base_branch": "main",
    "expected_head_sha": "e63a27babb09da4a7c4589cbe3e37c112f6b6e79",
    "expected_merge_commit_sha": "105ecd0d0dc72aa847d11b193190689dbda0dda8",
    "required_pull_request_workflows": [
        "pr-policy", "enforcement-tests", "workflow-evidence-policy",
        "connector-evidence-policy", "capability-evidence-policy",
        "documentation-asset-policy", "plan-policy",
        "semantic-cleanup-policy", "import-cleanup-policy",
        "telemetry-handoff-tests", "known-gaps-live-state"
    ],
    "required_push_workflows": [
        "enforcement-tests", "known-gaps-live-state", "post-merge-validation"
    ],
    "required_check_runs": ["enforcement-tests"]
})
claims_path.write_text(json.dumps(data, indent=2) + "\n")

audit = "docs/operations/operational-readiness-audit.md"
replace_once(audit,
    "- **Snapshot only:** Engineering OS `main` was inspected at `efb36cca413602cde3cd20aa17d32b3379f9eb53`; Project 8 `main` at `f282f5e9889d956e54fc0803938915fd86a58158`; Project 8 PR #9 at `51970629f3c3af32cb73bea0aab676874478248d`. Mutable state must always be re-fetched before a decision.",
    "- **Snapshot only:** Engineering OS `main` was inspected at `105ecd0d0dc72aa847d11b193190689dbda0dda8`; Project 8 `main` at `f282f5e9889d956e54fc0803938915fd86a58158`; Project 8 PR #9 at `51970629f3c3af32cb73bea0aab676874478248d`. Mutable state must always be re-fetched before a decision.")
replace_once(audit,
    "| documentation-runtime-state-drift | open | P1 | Active documentation and executable-owner consistency. |",
    "| documentation-runtime-state-drift | closed | P1 | Active documentation and executable-owner consistency. |")
replace_once(audit,
    "| Documentation runtime state and readiness consistency | Partially enforced | Gate: extended `check-documentation-hygiene.sh`. Owner: docs-governance. Evidence: capability, inventory, reviewer, manifest, telemetry-plan/analyzer, and terminology comparison. | gap:documentation-runtime-state-drift — PR #256 covered wording/inventory/reviewer reconciliation; this branch (`claude/operational-readiness-eos-c6ykfs`) closes the remaining MANIFEST.tsv and telemetry-terminology checklist items with bidirectional fixtures; exact-head CI, review, owner-approved merge, and post-merge validation remain before closure. |",
    "| Documentation runtime state and readiness consistency | Enforced | Gate: extended `check-documentation-hygiene.sh`. Owner: docs-governance. Evidence: PR #256 plus PR #260 exact head `e63a27babb09da4a7c4589cbe3e37c112f6b6e79`, 27 documentation-hygiene fixtures, seven resolved review threads, owner approval comment `5063627361`, expected-head merge `105ecd0d0dc72aa847d11b193190689dbda0dda8`, and `docs/operations/live-state-claims.json`. | Closed; the live-state claim must continue to verify exact pull-request and post-merge push evidence. |")
replace_once(audit,
    "- `gap:merge-readiness-exact-head-and-attempt-ordering` closed through PR #257, exact reviewed head `fedf8d069a8634085c650ea6381c1c0dabfdc368`, deterministic latest-attempt fixtures, enforcement run 1384, latest `pr-policy` run 1679, two resolved review threads, owner approval comment `5060947961`, expected-head protected merge `efb36cca413602cde3cd20aa17d32b3379f9eb53`, and the canonical live-state claim.\n\n### Phase 0 — make future merge and readiness evidence trustworthy\n\n1. `gap:documentation-runtime-state-drift`\n\nExit: merge decisions use exact-head latest-attempt evidence and active canonical descriptions agree with executable owners.",
    "- `gap:merge-readiness-exact-head-and-attempt-ordering` closed through PR #257, exact reviewed head `fedf8d069a8634085c650ea6381c1c0dabfdc368`, deterministic latest-attempt fixtures, enforcement run 1384, latest `pr-policy` run 1679, two resolved review threads, owner approval comment `5060947961`, expected-head protected merge `efb36cca413602cde3cd20aa17d32b3379f9eb53`, and the canonical live-state claim.\n- `gap:documentation-runtime-state-drift` closed through PR #256 and PR #260, exact reviewed head `e63a27babb09da4a7c4589cbe3e37c112f6b6e79`, 27 documentation-hygiene fixtures, latest exact-head CI including `pr-policy` 1692 and `enforcement-tests` 1391, seven resolved review threads, owner approval comment `5063627361`, expected-head protected merge `105ecd0d0dc72aa847d11b193190689dbda0dda8`, and the canonical live-state claim.\n\n### Phase 0 — complete\n\nAll Phase 0 gaps are closed. Merge decisions use exact-head latest-attempt evidence and active canonical descriptions agree with executable owners.\n\nExit: satisfied; proceed to Phase 1 in dependency order.")
replace_once(audit,
    "### gap:documentation-runtime-state-drift — P1",
    "### gap:documentation-runtime-state-drift — P1 — closed")
replace_once(audit,
    "- [ ] Complete exact-head focused/full CI, external review and thread reconciliation, owner-approved merge, and post-merge validation before closing this gap.",
    "- [x] PR #260 exact head `e63a27babb09da4a7c4589cbe3e37c112f6b6e79` passed focused/full exact-head CI including latest `pr-policy` 1692 and `enforcement-tests` 1391; all seven CodeRabbit/Codex threads were resolved; owner approval comment `5063627361` authorized an expected-head protected merge; PR #260 merged as `105ecd0d0dc72aa847d11b193190689dbda0dda8`; canonical `main` compares identical; and `docs/operations/live-state-claims.json` requires successful post-merge `enforcement-tests`, `known-gaps-live-state`, and `post-merge-validation`.")
replace_once(audit,
    "1. Documentation/runtime consistency — P1; PR #256 closed part of the expanded contract, while MANIFEST and telemetry semantics remain.\n2. Hard-hook fail-closed — P0.\n3. Bypass approval provenance and required-hook settings parity — P1.\n4. Telemetry archive import integrity and canonical pattern ownership — P1.\n5. Project 8 experiment blindness — P0 after deterministic Engineering OS defects.\n6. Fresh Remote and Project 8 qualification, then first-run monitoring usefulness — P1.\n7. Pattern evidence maturity and second-run reproducibility — P2.\n8. Final full-readiness semantics and assertion — terminal P1.",
    "1. Hard-hook fail-closed — P0.\n2. Bypass approval provenance and required-hook settings parity — P1.\n3. Telemetry archive import integrity and canonical pattern ownership — P1.\n4. Project 8 experiment blindness — P0 after deterministic Engineering OS defects.\n5. Fresh Remote and Project 8 qualification, then first-run monitoring usefulness — P1.\n6. Pattern evidence maturity and second-run reproducibility — P2.\n7. Final full-readiness semantics and assertion — terminal P1.")
replace_once(audit,
    "PR #256 is merged as `4ca1fd5a58fc96275ae69a1d2e573b7712d9055d`. It reconciled capability wording, README inventory references, and CodeRabbit review policy, but the expanded audit still identified documentation/runtime contradictions in `scripts/enforcement/MANIFEST.tsv` and telemetry readiness semantics. That audit refinement also registered `telemetry-archive-import-integrity`; registration alone does not close it. Branch `claude/operational-readiness-eos-c6ykfs` (based on `main` at `df01a8fea1...`) closes the remaining `documentation-runtime-state-drift` checklist items: it reconciles `scripts/enforcement/MANIFEST.tsv` wording with the active capability registry, verifies and guards first-run-vs-longitudinal telemetry terminology, assigns canonical owners for both surfaces in `docs/operations/documentation-ownership.tsv`, and adds bidirectional regression fixtures — all local focused and full enforcement suites pass. It has not yet gone through exact-head CI, review, owner approval, merge, or post-merge validation, so the gap remains `open` until that evidence exists.",
    "PR #256 is merged as `4ca1fd5a58fc96275ae69a1d2e573b7712d9055d` and reconciled capability wording, README inventory references, and CodeRabbit review policy. PR #260 exact head `e63a27babb09da4a7c4589cbe3e37c112f6b6e79` completed the remaining `documentation-runtime-state-drift` contract by reconciling `scripts/enforcement/MANIFEST.tsv` with the active capability registry, enforcing first-run-versus-longitudinal telemetry terminology, assigning canonical ownership rows, and adding bidirectional fixtures. The exact head passed the latest required PR workflows including `pr-policy` 1692 and `enforcement-tests` 1391; all seven review threads were resolved; owner approval comment `5063627361` authorized the expected-head protected merge; PR #260 merged as `105ecd0d0dc72aa847d11b193190689dbda0dda8`; canonical `main` compares identical; and the canonical live-state claim requires successful post-merge workflows. The separate `telemetry-archive-import-integrity` gap remains open.")
replace_once(audit,
    "The system is audit-complete but not fully operationally ready. Exact-head merge evidence is closed; hook safety, bypass provenance, settings parity, documentation, pattern ownership/evidence, telemetry import integrity, Project 8 boundary, and qualification gaps remain. The behavioral experiment and its prompt remain prohibited until every gap closes and the strict assertion passes on fresh canonical state.",
    "The system is audit-complete but not fully operationally ready. Exact-head merge evidence and documentation/runtime consistency are closed; hook safety, bypass provenance, settings parity, pattern ownership/evidence, telemetry import integrity, Project 8 boundary, and qualification gaps remain. The behavioral experiment and its prompt remain prohibited until every gap closes and the strict assertion passes on fresh canonical state.")
