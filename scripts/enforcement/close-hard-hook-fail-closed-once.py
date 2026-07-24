#!/usr/bin/env python3
import json
from pathlib import Path

HEAD = "5ee5d9fe51ddd8b9b490fe60424be4ea37cad9b3"
MERGE = "e405938ebe5fcbc7e5b7bf635ef50a9c10cbddb6"
APPROVAL = "5074786377"


def replace_once(path: str, old: str, new: str) -> None:
    target = Path(path)
    text = target.read_text(encoding="utf-8")
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one match, found {count}: {old[:100]!r}")
    target.write_text(text.replace(old, new, 1), encoding="utf-8")


def update_gap() -> None:
    path = Path("docs/operations/known-gaps.tsv")
    lines = path.read_text(encoding="utf-8").splitlines()
    matches = [i for i, line in enumerate(lines) if line.startswith("hard-hook-fail-closed\t")]
    if len(matches) != 1:
        raise SystemExit(f"expected one hard-hook gap row, found {len(matches)}")
    index = matches[0]
    fields = lines[index].split("\t")
    if len(fields) != 10 or fields[2] != "open":
        raise SystemExit("hard-hook gap row is not the expected open 10-column row")
    fields[2] = "closed"
    fields[7] = (
        f"Closed after PR #262 exact head {HEAD} passed all 10 required exact-head workflows "
        "including pr-policy 1770 and enforcement-tests 1463, all 11 review threads were resolved, "
        f"owner approval comment {APPROVAL} authorized an expected-head protected merge, and main "
        f"became identical to merge commit {MERGE}; the canonical live-state claim requires successful "
        "post-merge push workflows."
    )
    fields[8] = "docs/operations/live-state-claims.json"
    fields[9] = (
        "The implementation owns failure semantics after a hard hook is required; settings parity "
        "remains tracked separately by eos-repo-boundary-sync-drift."
    )
    lines[index] = "\t".join(fields)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def update_claims() -> None:
    path = Path("docs/operations/live-state-claims.json")
    root = json.loads(path.read_text(encoding="utf-8"))
    claim_id = "engineering-os-pr-262-hard-hook-fail-closed"
    if any(claim.get("claim_id") == claim_id for claim in root["claims"]):
        raise SystemExit(f"duplicate claim: {claim_id}")
    root["claims"].append(
        {
            "claim_id": claim_id,
            "gap_id": "hard-hook-fail-closed",
            "repository": "yotamfried-ux/Engineering-OS",
            "pull_number": 262,
            "base_branch": "main",
            "expected_head_sha": HEAD,
            "expected_merge_commit_sha": MERGE,
            "required_pull_request_workflows": [
                "pr-policy",
                "enforcement-tests",
                "workflow-evidence-policy",
                "connector-evidence-policy",
                "capability-evidence-policy",
                "documentation-asset-policy",
                "plan-policy",
                "semantic-cleanup-policy",
                "import-cleanup-policy",
                "telemetry-handoff-tests",
            ],
            "required_push_workflows": ["enforcement-tests", "post-merge-validation"],
            "required_check_runs": ["enforcement-tests"],
        }
    )
    path.write_text(json.dumps(root, indent=2) + "\n", encoding="utf-8")


def update_audit() -> None:
    path = "docs/operations/operational-readiness-audit.md"
    replace_once(path, "- **Last verified:** 2026-07-23 America/Panama / 2026-07-23 UTC", "- **Last verified:** 2026-07-24 Asia/Jerusalem / 2026-07-24 UTC")
    replace_once(path, "Engineering OS `main` was inspected at `105ecd0d0dc72aa847d11b193190689dbda0dda8`", f"Engineering OS `main` was inspected at `{MERGE}`")
    replace_once(path, "| hard-hook-fail-closed | open | P0 | Hard hook infrastructure failure semantics. |", "| hard-hook-fail-closed | closed | P0 | Hard hook infrastructure failure semantics. |")
    replace_once(path, "Required nested dependency behavior is tracked by hard-hook fail-closed.", "Required nested dependency behavior is enforced by the closed hard-hook contract.")
    replace_once(path, "Missing required nested enforcement is tracked by hard-hook fail-closed.", "Required nested enforcement failure is covered by the closed hard-hook contract.")
    replace_once(
        path,
        "| Hard-hook blocking semantics | Missing enforcement | Gate: hook classification and wrapper tests. Owner: hooks-governance. Evidence: `hook-criticality.tsv`, wrappers, nested validators, and Claude Code hook semantics. | gap:hard-hook-fail-closed — infrastructure uncertainty can still allow a protected action. |",
        f"| Hard-hook blocking semantics | Enforced | Gate: hook classification, canonical hard/soft wrappers, static contract validation, installed-target regressions, exact-head CI, and live-state reconciliation. Owner: hooks-governance. Evidence: PR #262 exact head `{HEAD}`, ten successful exact-head workflows, 11 resolved review threads, approval comment `{APPROVAL}`, merge `{MERGE}`, and `docs/operations/live-state-claims.json`. | Closed; the live claim must continue to verify required pull-request and post-merge push evidence. |",
    )
    anchor = "- `gap:documentation-runtime-state-drift` closed through PR #256 and PR #260, exact reviewed head `e63a27babb09da4a7c4589cbe3e37c112f6b6e79`, 27 documentation-hygiene fixtures, latest exact-head CI including `pr-policy` 1692 and `enforcement-tests` 1391, seven resolved review threads, owner approval comment `5063627361`, expected-head protected merge `105ecd0d0dc72aa847d11b193190689dbda0dda8`, and the canonical live-state claim."
    replace_once(
        path,
        anchor,
        anchor + f"\n- `gap:hard-hook-fail-closed` closed through PR #262, exact reviewed head `{HEAD}`, source and installed-target negative regressions, ten successful exact-head workflows including `pr-policy` 1770 and `enforcement-tests` 1463, 11 resolved review threads, owner approval comment `{APPROVAL}`, expected-head protected merge `{MERGE}`, and the canonical live-state claim.",
    )
    replace_once(
        path,
        "1. `gap:hard-hook-fail-closed`\n2. `gap:bypass-approval-provenance`\n3. `gap:eos-repo-boundary-sync-drift`\n4. `gap:pattern-registry-canonical-drift`\n5. `gap:telemetry-archive-import-integrity`",
        "1. `gap:bypass-approval-provenance`\n2. `gap:eos-repo-boundary-sync-drift`\n3. `gap:pattern-registry-canonical-drift`\n4. `gap:telemetry-archive-import-integrity`",
    )
    checklist_start = "### gap:hard-hook-fail-closed — P0\n\nOfficial basis: <https://code.claude.com/docs/en/hooks>.\n\n"
    next_heading = "\n\n### gap:bypass-approval-provenance — P1"
    audit = Path(path).read_text(encoding="utf-8")
    if audit.count(checklist_start) != 1 or audit.count(next_heading) != 1:
        raise SystemExit("hard-hook checklist boundaries are not unique")
    prefix, rest = audit.split(checklist_start, 1)
    _, suffix = rest.split(next_heading, 1)
    checklist = f"""### gap:hard-hook-fail-closed — P0 — closed

Official basis: <https://code.claude.com/docs/en/hooks>.

- [x] Missing hard enforcer, wrapper, interpreter, required registry/settings input, nested validator, or dependency blocks instead of returning success or silently skipping; focused and installed-target fixtures cover the required chain.
- [x] Deny-conversion, malformed JSON, unexpected subprocess status, signal termination, and runtime failure block with Claude Code's event-specific deny semantics and exit-2 fallback.
- [x] Fail-open remains only for explicitly advisory or recorder units through `soft-hook-gate.sh`, with observable warnings and no fabricated evidence.
- [x] Every hard registry row maps to one checked-in and installed settings command; source and installed settings share `check-hard-hook-contract.py`.
- [x] Required validators and dependencies reject missing, unreadable, symlinked, untrusted, wrong-target, sibling-contaminated, or unavailable infrastructure.
- [x] Full enforcement run 1463 / ID `30115055846` passed the complete positive and negative suite on exact head `{HEAD}`.
- [x] PR #262 passed all ten required exact-head workflows, reconciled 11 review threads, recorded owner approval comment `{APPROVAL}`, merged with expected-head protection as `{MERGE}`, and the live claim requires successful `enforcement-tests` and `post-merge-validation` push workflows."""
    Path(path).write_text(prefix + checklist + next_heading + suffix, encoding="utf-8")
    replace_once(
        path,
        "1. Hard-hook fail-closed — P0.\n2. Bypass approval provenance and required-hook settings parity — P1.\n3. Telemetry archive import integrity and canonical pattern ownership — P1.\n4. Project 8 experiment blindness — P0 after deterministic Engineering OS defects.\n5. Fresh Remote and Project 8 qualification, then first-run monitoring usefulness — P1.\n6. Pattern evidence maturity and second-run reproducibility — P2.\n7. Final full-readiness semantics and assertion — terminal P1.",
        "1. Bypass approval provenance and required-hook settings parity — P1.\n2. Telemetry archive import integrity and canonical pattern ownership — P1.\n3. Project 8 experiment blindness — P0 after deterministic Engineering OS defects.\n4. Fresh Remote and Project 8 qualification, then first-run monitoring usefulness — P1.\n5. Pattern evidence maturity and second-run reproducibility — P2.\n6. Final full-readiness semantics and assertion — terminal P1.",
    )
    replace_once(path, "semantic cleanup; live-state reconciliation.", "semantic cleanup; hard-hook fail-closed; live-state reconciliation.")
    scope_anchor = "The separate `telemetry-archive-import-integrity` gap remains open."
    scope_addition = f"""The separate `telemetry-archive-import-integrity` gap remains open.

PR #262 exact head `{HEAD}` implemented the canonical hard-hook registry, event-specific fail-closed wrapper, explicit observable soft wrapper, source/installed contract validation, and negative regressions for missing infrastructure, nested dependencies, symlinks, malformed input/output, signals, false evidence, token boundaries, and sibling isolation. All ten required exact-head workflows succeeded, including `pr-policy` 1770 / ID `30115981865` and `enforcement-tests` 1463 / ID `30115055846`; all 11 review threads were resolved; owner approval comment `{APPROVAL}` authorized the expected-head protected merge; PR #262 merged as `{MERGE}`; canonical `main` compares identical; and the canonical live-state claim requires successful post-merge `enforcement-tests` and `post-merge-validation`."""
    replace_once(path, scope_anchor, scope_addition)
    replace_once(
        path,
        "Exact-head merge evidence and documentation/runtime consistency are closed; hook safety, bypass provenance, settings parity, pattern ownership/evidence, telemetry import integrity, Project 8 boundary, and qualification gaps remain.",
        "Exact-head merge evidence, documentation/runtime consistency, and hard-hook safety are closed; bypass provenance, settings parity, pattern ownership/evidence, telemetry import integrity, Project 8 boundary, and qualification gaps remain.",
    )


update_gap()
update_claims()
update_audit()
