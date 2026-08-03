# Engineering OS Bypass Control Plane Reference Template

This template is an **optional reference deployment** for legitimate provider-backed bypass operation after PR #264 is merged. It is not required to merge or close the implementation work for `gap:bypass-approval-provenance`.

If this template is not installed or its provider configuration is incomplete, Engineering OS must remain fail-closed: a truthy `EOS_BYPASS_*` variable cannot authorize anything by itself.

## Trust boundary

The reference deployment separates three roles:

1. **Runtime provider credential** — reads the required control metadata/evidence and creates a fresh authorization-attempt deployment. It must not be able to create/edit/delete the authoritative Issues claim/marker ledger, mutate repository contents/workflows, or change repository settings.
2. **Consumer `GITHUB_TOKEN`** — scoped to `contents: read`, `actions: read`, `deployments: write`, and `issues: write`. It creates the durable claim and attests the fresh attempt.
3. **Protected-repository verifier credential** — supplied as `PROTECTED_REPOSITORY_READ_TOKEN` and used only to verify protected-repository identity and collaborator permission.

The implementation does not require the runtime credential to be a GitHub App specifically. A GitHub App is one possible deployment choice when a narrowly scoped installation token is desired; credential selection is an operational concern, not a PR #264 merge gate.

The finalizer uses only `contents: read`, `actions: read`, and `issues: write` and creates the durable marker after the successful first-attempt consumer run.

## One-shot reference flow

`validate-bypass-approval.py --stage consumed` never authorizes by re-reading an old marker. It delegates to `authorize-bypass-once.py`, which creates a fresh provider attempt for each invocation.

The trusted consumer validates the provider-backed human approval, rejects an already-claimed approval, creates the durable claim, and only then publishes trusted attempt status. The runtime accepts authorization only for its own fresh attempt when the trusted consumer run and claim bindings match exactly.

A second invocation using the same approval is denied by the durable claim. Restarting a process does not reset that state. The requesting runtime cannot reset consumption because it has no authoritative Issues write permission.

## Optional operational enablement

If legitimate bypasses need to be enabled later:

- populate the real provider repository/issue/workflow identities in `scripts/enforcement/bypass-control-plane.json`;
- provision least-privilege runtime and protected-repository verifier credentials;
- keep reusable-workflow references pinned to immutable Engineering OS commits;
- verify one bounded approval succeeds once and replay/forgery/wrong-scope/provider-failure cases deny;
- keep authorization evidence metadata-only and never store secret values or conversation content.

Operational enablement is separate from the audit-defined merge bar. PR #264 itself is evaluated by the canonical bypass fixtures, installed-target behavior, full tests, exact-head CI, review reconciliation, explicit owner approval, protected merge, and post-merge validation.
