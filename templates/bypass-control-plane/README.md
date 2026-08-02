# Engineering OS Bypass Control Plane

This template is installed into a dedicated **private** control repository. Copying the files is not qualification; the live trust boundary must be proven before runtime authorization is enabled.

## Trust boundary

Three credentials have separate jobs and must not be interchangeable:

1. **Runtime GitHub App token** — may read repository metadata, Issues evidence, and Actions run/workflow metadata, and has `Deployments: write` only so it can create a fresh authorization-attempt deployment. It must not have Actions write, Issues write, Contents write, Administration write, or repository-settings mutation permissions.
2. **Consumer `GITHUB_TOKEN`** — is scoped in the trusted control repository to `contents: read`, `actions: read`, `deployments: write`, and `issues: write`. It creates the durable claim and attests the fresh deployment attempt with a provider status.
3. **Protected-repository verifier credential** — is supplied as `PROTECTED_REPOSITORY_READ_TOKEN` and is used only to verify protected-repository identity and collaborator permission. Runtime/control credentials are never reused as its fallback.

The finalizer uses only `contents: read`, `actions: read`, and `issues: write` and creates the durable marker after the successful first-attempt consumer run.

The control workflows run only from the trusted default branch and call the Engineering OS reusable workflows at immutable commit `72709cd3be89204d46b92ee81239829c71d5cd1b`. Approval and consumption records use separate pinned issues. Provider `created_at` is canonical, edited approvals/claims/markers are rejected, duplicate or conflicting evidence fails closed, Git tags are not approval/consumption state, and master bypass variables remain permanently disabled authorization requests.

## True one-shot flow

The protected runtime still calls `validate-bypass-approval.py --stage consumed`, but that stage no longer re-authorizes by re-reading an old marker. It delegates to `authorize-bypass-once.py`, which creates a **fresh deployment ID for every invocation**.

The deployment payload binds the exact approval digest, protected repository, bypass, gate, action, surface, target, target fingerprint, target commit, policy SHA, and trusted control-repository SHA. The `deployment` event starts `consume-bypass`.

The consumer serializes identical approval/fingerprint attempts, verifies the human approval from provider state, rejects an already-claimed approval, writes the durable claim, and then publishes a canonical deployment status. The runtime accepts that status only when its creator is the pinned `github-actions[bot]` immutable user ID and its exact consumer run reaches terminal success on the configured workflow/path/repository/SHA with `run_attempt=1`.

A second runtime call necessarily creates a different deployment ID, but the trusted consumer sees the existing durable claim and denies it. Restarting the process/session does not reset the ledger. Runtime-authored deployment statuses cannot authorize because their creator identity is not the pinned Actions identity. Deleting a deployment cannot reset consumption because the claim/marker ledger lives in Issues and the runtime has no Issues write permission.

Authorization consumes the approval at the durable reservation point. If the downstream protected operation later fails, that approval is still spent; obtain a new human approval rather than replaying it.

## Qualification

Before enabling runtime validation:

- replace every zero or blank placeholder in `scripts/enforcement/bypass-control-plane.json`;
- verify the private control repository's immutable repository ID;
- create separate **Approval Registry** and **Consumption Ledger** issues;
- record the exact consumer/finalizer workflow IDs, workflow paths, and trusted default-branch SHA;
- install the runtime GitHub App token and the separate protected-repository verifier credential with the least privileges above;
- prove the runtime cannot write Issues/Contents, mutate Actions workflows, or change repository settings;
- prove runtime-authored deployment statuses cannot authorize and deployment deletion cannot reset a durable claim;
- execute the live success/replay/restart/concurrency/malformed/wrong-binding/rerun/issuer/edit/provider-failure/mutation/SHA-mismatch matrix in `docs/operations/bypass-control-plane-runbook.md` from the Engineering OS repository;
- set `qualification.status` to `qualified` only after durable provider evidence exists.

The required concurrency result is exactly one authorization success and DENY for every duplicate attempt. Concurrency serialization is defense-in-depth; the durable claim is the authoritative one-shot state.
