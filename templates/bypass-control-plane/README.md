# Engineering OS Bypass Control Plane

This template is installed into a dedicated **private** control repository. Copying the files is not qualification; the live trust boundary must be proven before runtime authorization is enabled.

## Trust boundary

Three credentials have separate jobs and must not be interchangeable:

1. **Runtime credential** — may read the control-plane metadata needed for validation and dispatch the control workflow. It must not write issues, create/edit/delete consumption markers, write repository contents, mutate workflows, or change repository settings.
2. **Consumer `GITHUB_TOKEN`** — is scoped in the trusted control repository to exactly `contents: read`, `actions: read`, and `issues: write`. It creates claim/marker evidence; it is not a protected-repository administration credential.
3. **Protected-repository verifier credential** — is supplied as `PROTECTED_REPOSITORY_READ_TOKEN` and is used only to verify protected-repository identity and collaborator permission. Runtime/control credentials are never reused as its fallback.

The control workflows run only from the trusted default branch and call the Engineering OS reusable workflows at the immutable commit `d45a8bbf56702f00cea091bf38814b2bdb44b66a`. Approval and consumption records use separate pinned issues. Provider `created_at` is canonical, edited approvals/claims/markers are rejected, duplicate or conflicting evidence fails closed, and a consumed approval cannot be replayed. Git tags are not approval or consumption records. Master bypass variables are permanently disabled authorization requests.

## Qualification

Before enabling runtime validation:

- replace every zero or blank placeholder in `scripts/enforcement/bypass-control-plane.json`;
- verify the private control repository's immutable repository ID;
- create separate approval-registry and consumption-ledger issues;
- record the exact workflow IDs, workflow paths, and default-branch SHA;
- install the GitHub App/runtime credential and the separate protected-repository verifier credential with the least privileges described above;
- execute the live allow/deny qualification matrix in `docs/operations/bypass-control-plane-runbook.md` from the Engineering OS repository;
- set `qualification.status` to `qualified` only after durable provider evidence exists.

The protected runtime uses `validate-bypass-approval.py --stage consumed`. The control workflow uses `consume-bypass-approval.py`; concurrency serializes the same approval comment plus target fingerprint so a second use cannot race past the one-shot contract.
