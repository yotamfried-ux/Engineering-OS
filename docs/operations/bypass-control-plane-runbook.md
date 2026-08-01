# Bypass Control Plane Qualification Runbook

This runbook qualifies the provider-backed bypass trust boundary. Template installation alone is not evidence that the control plane is safe to use.

## Preconditions

- Use a dedicated private repository for the control plane; do not reuse a product repository.
- Install `templates/bypass-control-plane/` on the trusted default branch.
- Keep the reusable-workflow references pinned to the immutable Engineering OS commit recorded by the template.
- Create two separate issues: **Approval Registry** and **Consumption Ledger**.
- Record the control repository name and immutable repository ID, issue numbers, consumer/finalizer workflow IDs and paths, and the exact trusted default-branch SHA.
- Configure `scripts/enforcement/bypass-control-plane.json` with those exact provider identities before changing `qualification.status`.

## Credential contract

### Runtime credential

Allowed capabilities are limited to the metadata reads needed by the validator and Actions workflow dispatch. Prove that the credential cannot write issues, create/edit/delete marker comments, write repository contents, mutate workflows, or change repository settings.

### Consumer `GITHUB_TOKEN`

The trusted consumer/finalizer workflows declare only:

- `contents: read`
- `actions: read`
- `issues: write`

Do not use `write-all`. This token is the claim/marker writer in the control repository.

### Protected-repository verifier credential

Supply `PROTECTED_REPOSITORY_READ_TOKEN` separately. It may read protected-repository identity and collaborator permission. Prove that it cannot mutate the protected repository. The validator fails closed when this credential is missing; it does not reuse the runtime token.

Do not print credential values during qualification.

## Approval payload

An approval must be created by an eligible human `User`; the runtime requesting authorization must not create its own approval. The approval body uses the canonical schema and binds repository ID/name, gate, bypass, action, surface, target, target fingerprint, target commit, policy SHA, expiry, and a concrete reason.

Before the live approval step, construct the exact payload from the pending request and have the repository owner publish it manually in the Approval Registry. Record the provider comment ID and provider `created_at`. Edited approval comments are invalid.

## Live qualification matrix

Run the matrix only against the exact configured provider identities and trusted default-branch SHA.

1. **Bounded success** — one exact request consumes one valid approval and produces one verified claim followed by one verified marker after the consumer run succeeds.
2. **Replay denial** — the same request and approval cannot authorize a second time.
3. **Concurrent same-digest requests** — launch concurrent requests with the same approval/fingerprint; exactly one may create the usable consumption chain.
4. **Malformed request/evidence** — malformed approval, claim, or marker bodies fail closed.
5. **Duplicate/conflicting evidence** — duplicate or conflicting claims/markers fail closed rather than selecting one.
6. **Wrong binding** — wrong workflow, workflow ID/path, default-branch SHA, actor, repository, target commit, target fingerprint, or policy SHA fails closed.
7. **Rerun denial** — `run_attempt != 1` fails closed for consumer and finalizer evidence.
8. **Issuer/role denial** — Bot issuers, non-`User` issuers, and users below the configured maintain/admin threshold fail closed.
9. **Edited evidence denial** — edited approval, claim, or marker comments fail closed.
10. **Provider ambiguity/failure** — missing provider objects, ambiguous values, pagination ambiguity, timeout, cancellation, or failed runs fail closed.
11. **Marker mutation denial** — prove with the runtime credential that marker creation/edit/delete operations are denied. Separately prove the protected-repository verifier cannot mutate the protected repository.

## Evidence to retain

Retain provider-backed evidence without secrets:

- control repository name and immutable repository ID;
- approval and consumption issue numbers;
- consumer/finalizer workflow IDs and paths;
- trusted default-branch SHA;
- approval comment ID, immutable issuer ID/type/role, provider `created_at`, and edit state;
- claim and marker comment IDs and their verified run bindings;
- the exact request digest, policy SHA, target commit, target fingerprint, and expiry;
- allow/deny result for every qualification case above;
- exact Engineering OS implementation SHA and exact-head CI status.

Only after every required case is proven may `qualification.status` become `qualified`. A local fixture, a copied template, a PR description, or chat approval is never a substitute for live provider evidence.
