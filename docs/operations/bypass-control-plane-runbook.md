# Optional Bypass Provider Enablement Runbook

PR #264 is an Engineering OS enforcement hardening change. Its merge/closure contract is owned by `docs/operations/known-gaps.tsv` and `docs/operations/operational-readiness-audit.md` under `gap:bypass-approval-provenance`.

This runbook is **not** a PR #264 merge prerequisite. It exists only for an operator who later chooses to enable legitimate provider-backed bypasses. With provider infrastructure absent or unconfigured, Engineering OS must fail closed: `EOS_BYPASS_*` values remain requests and cannot authorize anything.

## Security contract

The operational provider must preserve the implementation invariants already enforced by PR #264:

- approval comes from provider state the requesting process cannot fabricate in the same operation;
- approval binds the human issuer, provider timestamp, reason, exact bypass/gate/action/surface/target/fingerprint/target commit, policy digest, and bounded expiry;
- edited, malformed, ambiguous, wrong-scope, expired, forged, or master-substitution evidence denies;
- durable consumption is authoritative outside local process state;
- every successful authorization consumes the approval exactly once;
- replay, restart, duplicate attempts, and conflicting consumption evidence deny;
- the requesting runtime cannot create or delete the authoritative consumption ledger;
- missing provider configuration or credentials denies rather than falling back to an environment/local bypass.

## Reference GitHub implementation

The repository includes a reference GitHub-backed implementation and template. It uses a fresh GitHub deployment as an authorization-attempt identity, a trusted consumer workflow to create the durable claim, and a finalizer to record post-consumer evidence. The claim is the replay lock; a deployment/status is not consumption state.

This reference architecture is one way to satisfy the audit contract. PR #264 does not require an operator to deploy or live-qualify it before merging the anti-forgery enforcement.

## Credentials

`EOS_BYPASS_PROVIDER_TOKEN` is the runtime provider credential. The implementation does not require a particular credential product. If the GitHub reference implementation is enabled later, provision the narrowest credential that can read required control metadata/evidence and create the fresh deployment attempt, while denying authoritative ledger writes, repository contents/workflow mutation, and administration/settings mutation.

`PROTECTED_REPOSITORY_READ_TOKEN` is a separate read-only verifier for protected-repository identity and collaborator permission. If it is absent, validation fails closed.

The trusted consumer/finalizer use narrowly declared `GITHUB_TOKEN` permissions in their reusable workflows. Do not replace them with `write-all`.

Never print or commit credential values.

## Optional enablement sequence

Only when legitimate bypass operation is actually needed:

1. Create or select a provider location whose authoritative approval/consumption state is outside the requesting runtime's write authority.
2. Configure exact immutable repository/workflow/issue identities in `scripts/enforcement/bypass-control-plane.json`.
3. Provision least-privilege runtime and protected-repository read credentials.
4. Verify one bounded valid approval succeeds exactly once.
5. Verify replay/restart/concurrency, wrong binding, expiry, issuer, edit, provider failure, and runtime ledger-mutation attempts fail closed.
6. Retain metadata-only evidence; never retain secrets or conversation content.

These steps qualify optional operational enablement. They do not replace the canonical PR merge gates: focused/full/install tests, exact-head CI, review reconciliation, explicit owner approval, protected merge, and post-merge validation.

## Approval and consumption records

The authored approval must not contain provider-assigned fields such as the comment ID or provider creation timestamp. The validator binds those values from provider state and rejects edited approvals.

A durable claim reserves the approval. If downstream work fails after the claim is created, the approval remains spent. A new approval is required; retrying the same approval is not permitted.

Local ledgers, environment values, Git tags, PR prose, chat messages, copied fixtures, or self-authored runtime evidence are never authoritative bypass authorization.
