# Bypass Control Plane Qualification Runbook

This runbook qualifies the provider-backed bypass trust boundary. Template installation alone is not evidence that the control plane is safe to use.

## Preconditions

- Use a dedicated private repository for the control plane; do not reuse a product repository.
- Install `templates/bypass-control-plane/` on the trusted default branch.
- Keep the reusable-workflow references pinned to the immutable Engineering OS commit recorded by the template.
- Create two separate issues: **Approval Registry** and **Consumption Ledger**.
- Record the control repository name and immutable repository ID, issue numbers, consumer/finalizer workflow IDs and paths, and the exact trusted default-branch SHA.
- Configure `scripts/enforcement/bypass-control-plane.json` with those exact provider identities before changing `qualification.status`.

## One-shot authorization model

An `EOS_BYPASS_*` environment value is a request only. `validate-bypass-approval.py --stage consumed` never grants authorization by re-reading an old claim or marker. Every invocation delegates to `authorize-bypass-once.py`, which must create a **fresh GitHub deployment object** in the private control repository.

The deployment is an attempt identity, not consumption state. It is bound to the exact approval digest, protected repository, bypass, gate, action, surface, target, target fingerprint, target commit, policy SHA, and trusted control-repository default-branch SHA.

The deployment triggers the trusted `consume-bypass` workflow. That workflow serializes the same approval comment plus target fingerprint, validates the human approval again against provider state, and creates the authoritative durable **claim** before it publishes a trusted deployment status for that fresh attempt. A second consumer invocation for the same approval is denied if the durable claim already exists. The finalizer creates the durable marker only after the trusted consumer run succeeds.

The runtime may authorize only when all of these are true for its **own fresh deployment ID**:

1. the deployment resolved to the configured trusted default-branch SHA;
2. exactly one canonical authorization status exists for that deployment;
3. the status was written by the pinned `github-actions[bot]` immutable user ID;
4. the referenced consumer run is the configured workflow/path/repository, `event=deployment`, `run_attempt=1`, and the exact trusted SHA;
5. that exact run reaches terminal `success` within the bounded poll timeout;
6. exactly one durable claim exists and is bound to that same run.

A status that becomes visible before the run is terminal is not authorization; the authorizer polls the exact bound run until terminal success or timeout. Provider timeout, ambiguous status, cancellation, terminal non-success, wrong identity, or wrong binding fails closed.

### Consumption point

A successful durable claim reserves the approval permanently for one authorization attempt. This is intentionally security-biased: if the protected operation fails **after** authorization was issued, the approval is still consumed and cannot be retried. A new human approval is required. Local process/session restart does not reset provider state.

The marker is durable post-consumer evidence. It is not the replay lock; the claim is. Therefore deleting or recreating a deployment/status cannot make an already-claimed approval usable again.

## Credential contract

### Runtime credential

The runtime credential is a GitHub App installation token scoped to the dedicated control repository with only the provider capabilities needed by the request path:

- repository metadata read;
- Issues read for approval/ledger evidence;
- Actions read for exact workflow/run verification;
- Deployments write so it can create a fresh authorization-attempt deployment and read its statuses.

It does **not** receive Actions write. Therefore it cannot dispatch/enable/disable workflows through the Actions API. It must also be denied Issues write, Contents write, Administration write, and every repository-settings mutation permission.

`Deployments: write` can mutate deployment objects/statuses. That does not grant authorization because runtime-authored statuses have the GitHub App identity rather than the pinned Actions-bot identity, and deployment objects/statuses are not authoritative consumption state. Qualification must also prove that deleting a runtime-created deployment cannot erase the durable claim/marker ledger.

### Consumer `GITHUB_TOKEN`

The trusted consumer declares only:

- `contents: read`
- `actions: read`
- `deployments: write`
- `issues: write`

`deployments: write` is used only to attest the fresh deployment attempt after the claim is created. Do not use `write-all`.

### Finalizer `GITHUB_TOKEN`

The trusted finalizer declares only:

- `contents: read`
- `actions: read`
- `issues: write`

It does not need deployment write. It writes the durable marker after the successful first-attempt consumer run.

### Protected-repository verifier credential

Supply `PROTECTED_REPOSITORY_READ_TOKEN` separately. It may read protected-repository identity and collaborator permission. Prove that it cannot mutate the protected repository. The validator fails closed when this credential is missing; it does not reuse the runtime token.

Do not print credential values during qualification.

## Approval payload

An approval must be created by an eligible human `User`; the runtime requesting authorization must not create its own approval. The approval body uses the canonical schema and binds repository ID/name, gate, bypass, action, surface, target, target fingerprint, target commit, policy SHA, expiry, consumer/finalizer identities, and the trusted control-repository default-branch SHA.

The authored body must **not** contain `approval_comment_id` or `approval_created_at`. GitHub assigns both only when the comment is published, and edited approvals are rejected. The validator binds them from the provider envelope, which keeps provider `created_at` authoritative. `expires_at` is an absolute time checked against provider `created_at` and may not exceed four hours.

Before the live approval step, construct the exact payload from the pending request and have the repository owner publish it manually in the Approval Registry. Record the provider comment ID and provider `created_at`. Edited approval comments are invalid.

Approvals are the only canonical approval objects in the Approval Registry. Claims and markers are consumption evidence and are written to the Consumption Ledger; a claim found outside the Consumption Ledger is not durable consumption evidence.

## One-shot invariants

- **Fresh attempt required.** Every runtime authorization call creates a new provider deployment ID. Old marker/status evidence cannot be read again to authorize.
- **One durable reservation.** The first successful consumer creates one claim. Any later same-approval consumer sees the claim and denies before creating another usable authorization status.
- **Concurrency is defense-in-depth, not the replay state.** GitHub Actions concurrency serializes same approval/fingerprint consumers. The durable claim remains the authoritative one-shot state across process restarts and future sessions.
- **Runtime cannot reset consumption.** The runtime has no Issues write permission. Deleting or modifying deployment objects/statuses cannot remove the claim/marker ledger.
- **Ambiguity burns safe.** If a claim may have been created but the status/API response is ambiguous, the caller receives DENY. The approval may be unusable afterward; this is preferred to a second authorization.
- **Master bypasses remain disabled.** Master-classified environment variables can never become authorization surfaces.

## Live qualification matrix

Run the matrix only against the exact configured provider identities and trusted default-branch SHA.

1. **Bounded one-shot success** — one exact request creates a fresh deployment, one verified claim, a successful exact consumer run, and then the finalizer marker; the runtime receives one authorization success only.
2. **Immediate replay denial** — invoke the exact same approval/request again before expiry; the fresh second attempt must deny.
3. **Restart replay denial** — repeat from a new process/session; the provider claim still denies.
4. **Different invocation replay denial** — same approval and exact request from another runtime invocation must deny.
5. **Post-expiry replay denial** — the consumed approval remains unusable after expiry.
6. **Concurrent same-request attempts** — launch at least two identical requests concurrently; exactly one may authorize and every other attempt must fail closed. Verify one internally consistent durable claim/marker chain.
7. **Malformed request/evidence denial** — malformed approval, claim, marker, attempt payload, or canonical deployment status fails closed.
8. **Duplicate/conflicting evidence denial** — duplicate or conflicting claims/markers/statuses fail closed rather than selecting one.
9. **Wrong binding denial** — wrong repository/name/ID, issue, workflow ID/path, trusted SHA, run ID, actor, triggering actor, action, gate, surface, target, target commit, target fingerprint, or policy SHA fails closed.
10. **Rerun denial** — `run_attempt != 1` fails closed for consumer and finalizer evidence.
11. **Issuer/role denial** — Bot issuers, non-`User` issuers, and users below maintain/admin fail closed.
12. **Edited evidence denial** — edited approval, claim, marker, or trusted authorization status fails closed.
13. **Provider failure/ambiguity denial** — missing provider objects, malformed values, pagination ambiguity, timeout, cancellation, or terminal failed runs fail closed.
14. **Credential-substitution denial** — missing/separated verifier credentials fail closed; runtime credentials cannot substitute for the protected-repository verifier.
15. **Runtime mutation denial** — prove the runtime cannot create/edit/delete issue comments, write contents, mutate workflows, or change repository settings. Prove runtime-authored deployment statuses cannot authorize. Prove deployment deletion does not reset a durable claim.
16. **Trusted-SHA mismatch denial** — a deployment or workflow run not resolved to the configured trusted default-branch SHA fails closed.

## Evidence to retain

Retain provider-backed evidence without secrets:

- control repository name and immutable repository ID;
- approval and consumption issue numbers;
- consumer/finalizer workflow IDs and paths;
- trusted default-branch SHA;
- runtime GitHub App identity and tested permission allow/deny matrix;
- approval comment ID, immutable issuer ID/type/role, provider `created_at`, and edit state;
- fresh deployment IDs and trusted status IDs;
- claim and marker comment IDs and their verified run bindings;
- exact consumer/finalizer run IDs and attempts;
- exact request digest, policy SHA, target commit, target fingerprint, and expiry;
- allow/deny result for every qualification case above;
- exact Engineering OS implementation SHA and exact-head CI status.

Only after every required case is proven may `qualification.status` become `qualified`. A local fixture, copied template, PR description, or chat approval is never a substitute for live provider evidence.
