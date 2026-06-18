# Authorization Patterns

> Pattern library for access control and permission enforcement. See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring and lifecycle.

## Overview

Patterns for deciding what an authenticated identity is allowed to do. Covers the three dominant models (RBAC, ABAC, ReBAC), a policy engine selection guide, and the tradeoffs between them. Authentication (verifying identity) is handled in [`patterns/auth/`](../auth/README.md); this library starts after identity is confirmed.

---

## Pattern: RBAC (Role-Based Access Control)

**Problem:** Applications need a predictable, auditable way to control access to resources based on the user's function within the organization. Checking raw user IDs in code does not scale past a handful of protected routes.

**Solution:** Assign users to roles. Roles carry sets of permissions expressed as `resource:action` strings. Middleware checks whether the authenticated user's roles include the permission required by the endpoint — never checks the role name directly.

**Architecture:**
```
users
  └─ user_roles (userId, roleId, orgId, expiresAt?)
       └─ roles (id, name, orgId)
            └─ role_permissions (roleId, permissionId)
                 └─ permissions (id, name)   e.g. "posts:read", "posts:write"

Request
  → extract userId from JWT
  → load roles for (userId, orgId)
  → expand roles to permission set
  → check: permissionSet.has("posts:write") ?
       YES → allow
       NO  → 403 Forbidden
```

**Permission naming convention:** `resource:action` — e.g. `posts:read`, `posts:write`, `posts:delete`, `billing:read`, `billing:manage`. Use a wildcard `posts:*` only internally in the policy layer, never in client-facing tokens.

**Permission matrix example:**

| Resource / Action | viewer | editor | admin | super-admin |
|---|---|---|---|---|
| posts:read | YES | YES | YES | YES |
| posts:write | NO | YES | YES | YES |
| posts:delete | NO | NO | YES | YES |
| billing:read | NO | NO | YES | YES |
| billing:manage | NO | NO | NO | YES |
| users:invite | NO | NO | YES | YES |
| org:delete | NO | NO | NO | YES |

**Multi-tenant SaaS — org-level vs. workspace-level roles:**
- Org-level role: scoped to the entire organization (`orgId` on the `user_roles` row). Controls billing, member management, and org-wide settings.
- Workspace-level role: scoped to a specific workspace/project inside the org (`workspaceId` on the `user_roles` row). Controls what the user can do inside that workspace only.
- A user may have `viewer` at the org level and `admin` inside one workspace. Resolve by checking the narrowest scope first.

**DB schema (PostgreSQL):**
```sql
CREATE TABLE permissions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL UNIQUE  -- e.g. "posts:write"
);

CREATE TABLE roles (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  org_id      UUID REFERENCES orgs(id) ON DELETE CASCADE,
  UNIQUE (name, org_id)
);

CREATE TABLE role_permissions (
  role_id       UUID REFERENCES roles(id) ON DELETE CASCADE,
  permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE user_roles (
  user_id      UUID REFERENCES users(id) ON DELETE CASCADE,
  role_id      UUID REFERENCES roles(id) ON DELETE CASCADE,
  org_id       UUID REFERENCES orgs(id) ON DELETE CASCADE,
  workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE,  -- NULL = org-level
  expires_at   TIMESTAMPTZ,
  granted_by   UUID REFERENCES users(id),
  granted_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, role_id, org_id)
);
```

**Example Code:**
```typescript
// permission-loader.ts
export async function loadPermissions(
  userId: string,
  orgId: string,
  workspaceId?: string,
): Promise<Set<string>> {
  const rows = await db.userRole.findMany({
    where: {
      userId,
      orgId,
      workspaceId: workspaceId ?? null,
      OR: [{ expiresAt: null }, { expiresAt: { gt: new Date() } }],
    },
    include: { role: { include: { rolePermissions: { include: { permission: true } } } } },
  });

  const permissions = new Set<string>();
  for (const ur of rows) {
    for (const rp of ur.role.rolePermissions) {
      permissions.add(rp.permission.name);
    }
  }
  return permissions;
}

// middleware.ts
export function requirePermission(permission: string) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const { userId, orgId } = req.user!;
    const workspaceId = req.params.workspaceId ?? req.body.workspaceId;

    const permissions = await loadPermissions(userId, orgId, workspaceId);
    if (!permissions.has(permission)) {
      return res.status(403).json({ error: 'Forbidden', required: permission });
    }
    next();
  };
}

// router usage
router.post('/posts', requirePermission('posts:write'), createPostHandler);
router.delete('/posts/:id', requirePermission('posts:delete'), deletePostHandler);
```

**Common Mistakes:**
- **Role explosion:** Defining a new role for every edge case (e.g., `editor-no-delete`, `admin-readonly-billing`). Use fine-grained permissions and compose them into roles instead.
- **Checking role names in code:** `if (user.role === 'admin')` breaks the moment a second admin-tier role is added. Always check the permission, never the role name.
- **Not separating org scope from resource scope:** A user who is `admin` of org A must not automatically have access to org B's resources. Always filter by `orgId` (and `workspaceId` when relevant) on every permission query.
- **Caching permissions indefinitely:** Cache permission sets with a short TTL (e.g., 60 seconds) and invalidate on role change. Never read role state from a long-lived JWT without a short expiry.

**Security Considerations:**
- Apply the principle of least privilege: default new users to the lowest role; elevation requires explicit action with audit log.
- Log every role assignment and removal: who, what role, to whom, timestamp, reason. Store in an append-only audit table.
- Never derive effective permissions on the client — always enforce server-side.

**Testing Strategy:**
Write a boundary test per permission in the matrix: assert that a user with the role below the required level receives 403, and the user with the required level receives 200. Test role expiry: expired `user_roles` rows must be treated as absent. Test org isolation: a user from org A cannot access org B's resources even with the same role name.

**Score:** Candidate (see pattern-lifecycle.md)

---

## Pattern: ABAC (Attribute-Based Access Control)

**Problem:** RBAC roles are static assignments. When access decisions must depend on properties of the user, the target resource, or the environment at request time — such as "managers can only edit documents in their own department" — roles alone cannot express the policy without combinatorial explosion.

**Solution:** Define policies that evaluate three attribute categories at runtime: subject attributes (who is asking), resource attributes (what is being accessed), and environment attributes (when and from where). A policy evaluator runs the applicable policies and returns ALLOW or DENY.

**Architecture:**
```
Request (userId, action, resourceId)
  → fetch subject attributes:   { role: 'manager', department: 'eng', clearanceLevel: 2 }
  → fetch resource attributes:  { ownerId: 'u-42', department: 'eng', classification: 'internal' }
  → fetch environment context:  { time: '14:30 UTC', ip: '10.0.1.5', mfa: true }
  → evaluate policies top-to-bottom (first DENY wins, then first ALLOW wins, else DENY)
       Policy 1: ALLOW IF subject.role == 'admin'
       Policy 2: ALLOW IF subject.role == 'manager'
                      AND resource.department == subject.department
       Policy 3: DENY  IF resource.classification == 'secret'
                      AND subject.clearanceLevel < 3
       Default:  DENY
  → enforce decision
```

**Attribute types:**
- **Subject:** `user.role`, `user.department`, `user.clearanceLevel`, `user.mfaVerified`, `user.orgId`
- **Resource:** `document.classification`, `document.ownerId`, `document.department`, `document.status`
- **Environment:** `request.time`, `request.ip`, `request.geo`, `session.mfaAge`

**When to use ABAC over RBAC:**
- Policies depend on resource properties that vary per record (not per type).
- Policies change frequently and need to be updated without code deploys.
- Compliance requirements mandate fine-grained, auditable policy language (e.g., HIPAA, GDPR data access controls).
- The number of distinct access rules makes a static role matrix unmanageable.

**When RBAC is sufficient:** If all resources of a given type have the same access rules for a given role, RBAC is simpler and easier to audit. Prefer RBAC; reach for ABAC only when RBAC cannot express the required policy cleanly.

**TypeScript policy evaluator example:**
```typescript
// types.ts
interface SubjectAttributes {
  userId: string;
  role: string;
  department: string;
  clearanceLevel: number;
  mfaVerified: boolean;
}

interface ResourceAttributes {
  ownerId: string;
  department: string;
  classification: 'public' | 'internal' | 'secret';
}

interface EnvironmentContext {
  ip: string;
  time: Date;
}

type PolicyDecision = 'ALLOW' | 'DENY' | 'NOT_APPLICABLE';

type Policy = (
  subject: SubjectAttributes,
  resource: ResourceAttributes,
  env: EnvironmentContext,
) => PolicyDecision;

// policies.ts
const adminPolicy: Policy = (subject) =>
  subject.role === 'admin' ? 'ALLOW' : 'NOT_APPLICABLE';

const managerSameDepartmentPolicy: Policy = (subject, resource) => {
  if (subject.role !== 'manager') return 'NOT_APPLICABLE';
  return subject.department === resource.department ? 'ALLOW' : 'DENY';
};

const secretClearancePolicy: Policy = (subject, resource) => {
  if (resource.classification !== 'secret') return 'NOT_APPLICABLE';
  return subject.clearanceLevel >= 3 ? 'NOT_APPLICABLE' : 'DENY';
};

// evaluator.ts — DENY overrides ALLOW; first ALLOW wins after all policies run
const POLICIES: Policy[] = [adminPolicy, secretClearancePolicy, managerSameDepartmentPolicy];

export function evaluate(
  subject: SubjectAttributes,
  resource: ResourceAttributes,
  env: EnvironmentContext,
): 'ALLOW' | 'DENY' {
  let allowed = false;
  for (const policy of POLICIES) {
    const decision = policy(subject, resource, env);
    if (decision === 'DENY') return 'DENY';
    if (decision === 'ALLOW') allowed = true;
  }
  return allowed ? 'ALLOW' : 'DENY';
}
```

**OPA policy example (Rego):**
```rego
package authz.documents

import future.keywords.if
import future.keywords.in

default allow := false

# Admins can do anything
allow if {
  input.subject.role == "admin"
}

# Managers can read/write documents in their own department
allow if {
  input.subject.role == "manager"
  input.action in {"read", "write"}
  input.resource.department == input.subject.department
}

# No one below clearance 3 may access secret documents
deny if {
  input.resource.classification == "secret"
  input.subject.clearanceLevel < 3
}

# Final decision: permitted and not denied
final_allow if {
  allow
  not deny
}
```

**Trade-offs:**
- More expressive than RBAC: policies can reference any attribute of any entity.
- Harder to reason about: "who can access document X?" requires evaluating all policies against all possible subjects, not just a role lookup.
- Auditability: policy files can be version-controlled, but debugging why a specific request was denied requires tracing the evaluator, not reading a matrix.
- Performance: attribute fetching adds latency per request. Cache attribute bundles aggressively with short TTLs; run OPA as a local sidecar to avoid network hops.

**Common Mistakes:**
- **Attribute injection:** Accepting resource or environment attributes from the client request without server-side verification. Always fetch authoritative attributes from the DB or a trusted service — never trust `req.body.resource.classification`.
- **Not caching policy decisions under load:** Cold attribute fetches (DB round-trips per request) collapse under traffic. Cache the full attribute bundle keyed on `(userId, resourceId)` with a 30–60 second TTL and invalidate on writes.
- **Overlapping DENY policies with no priority order:** Without a clear conflict resolution rule (e.g., "DENY overrides ALLOW"), policies produce unpredictable outcomes. Define the evaluation order and document it explicitly.

**Security Considerations:**
- Validate all attributes server-side on every request. Never trust client-supplied attributes that affect the policy outcome.
- Log the policy decision along with the input attributes used — this is the audit trail. Do not log only the final ALLOW/DENY without the inputs.
- For OPA: sign and verify policy bundles before loading them into the evaluator to prevent policy tampering.

**Testing Strategy:**
Write a policy decision table test: enumerate (subject, resource, env) tuples that should ALLOW and tuples that should DENY. Assert each combination. Test attribute injection: send a request with a forged `resource.classification` in the body and verify the server fetches the real value from DB. Test caching: verify a stale cache entry does not use an attribute value that was updated after the cache was populated.

**Score:** Candidate (see pattern-lifecycle.md)

---

## Pattern: Relationship-Based Authorization (ReBAC)

**Problem:** In collaborative SaaS applications, permissions derive from dynamic relationships between users and objects (e.g., "user is a member of team, team is an editor of workspace, workspace contains document"). RBAC and ABAC cannot model this graph without replicating the relationship data into policy rules, which quickly diverges from the actual data.

**Solution:** Model authorization as a directed graph of typed relationships between entities. To check whether user X can perform action A on object Y, evaluate whether a relationship path from X to Y exists that grants A. This is the model described in Google's Zanzibar paper; OpenFGA is the primary open-source implementation.

**Architecture:**
```
Relationship store (tuples):
  user:alice  →  member          →  team:eng
  team:eng    →  viewer          →  project:backend
  project:backend  →  parent     →  document:spec-v2

Authorization check:
  "Can user:alice view document:spec-v2?"
  → Direct tuple for alice on document:spec-v2? NO
  → Traverse: alice -[member]-> team:eng -[viewer]-> project:backend -[parent]-> document:spec-v2
  → document:spec-v2 inherits viewer from parent project:backend
  → team:eng has viewer on project:backend; alice is member of team:eng
  → ALLOW
```

**OpenFGA authorization model (DSL):**
```
model
  schema 1.1

type user

type team
  relations
    define member: [user]

type project
  relations
    define viewer: [user, team#member]
    define editor: [user, team#member]
    define owner:  [user]

type document
  relations
    define parent:  [project]
    define viewer:  [user, team#member] or viewer from parent
    define editor:  [user, team#member] or editor from parent
    define owner:   [user] or owner from parent
    define can_view: viewer or editor or owner
    define can_edit: editor or owner
    define can_delete: owner
```

**TypeScript SDK example:**
```typescript
import { OpenFgaClient, CredentialsMethod } from '@openfga/sdk';

const fga = new OpenFgaClient({
  apiUrl: process.env.FGA_API_URL!,
  storeId: process.env.FGA_STORE_ID!,
  credentials: {
    method: CredentialsMethod.ClientCredentials,
    config: {
      clientId: process.env.FGA_CLIENT_ID!,
      clientSecret: process.env.FGA_CLIENT_SECRET!,
      apiTokenIssuer: process.env.FGA_TOKEN_ISSUER!,
      apiAudience: process.env.FGA_AUDIENCE!,
    },
  },
});

// Write relationship tuples (e.g. on team membership change)
export async function addTeamMember(userId: string, teamId: string): Promise<void> {
  await fga.write({
    writes: {
      tuple_keys: [{ user: `user:${userId}`, relation: 'member', object: `team:${teamId}` }],
    },
  });
}

// Remove relationship tuple (e.g. on team membership removal)
export async function removeTeamMember(userId: string, teamId: string): Promise<void> {
  await fga.write({
    deletes: {
      tuple_keys: [{ user: `user:${userId}`, relation: 'member', object: `team:${teamId}` }],
    },
  });
}

// Check permission (called on every request)
export async function canUserPerformAction(
  userId: string,
  action: 'can_view' | 'can_edit' | 'can_delete',
  documentId: string,
): Promise<boolean> {
  const { allowed } = await fga.check({
    tuple_key: { user: `user:${userId}`, relation: action, object: `document:${documentId}` },
  });
  return allowed ?? false;
}

// Middleware
export function requireRelation(
  relation: 'can_view' | 'can_edit' | 'can_delete',
  getObjectId: (req: Request) => string,
) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const { userId } = req.user!;
    const objectId = getObjectId(req);
    const allowed = await canUserPerformAction(userId, relation, objectId);
    if (!allowed) return res.status(403).json({ error: 'Forbidden' });
    next();
  };
}

// Router usage
router.get(
  '/documents/:id',
  requireRelation('can_view', (req) => req.params.id),
  getDocumentHandler,
);
router.delete(
  '/documents/:id',
  requireRelation('can_delete', (req) => req.params.id),
  deleteDocumentHandler,
);
```

**Common SaaS use cases:**
- **Team workspace permissions:** `user -[member]-> team -[editor]-> workspace`
- **Shared resources:** `user:alice -[shared_with]-> document:X` — single direct tuple; no group needed
- **Folder hierarchy:** `folder:A -[parent]-> folder:B -[parent]-> folder:C` — permissions propagate through `parent` relations
- **Organization membership:** `user -[member]-> org -[owner]-> project`

**When ReBAC beats RBAC:**
- Permissions are determined by a graph of relationships that changes at runtime (users join/leave teams, resources are moved between folders).
- The same resource can be shared with different users through different relationship paths.
- You need to answer "list all documents user X can view" efficiently — OpenFGA's `ListObjects` endpoint traverses the graph server-side.

**When RBAC is sufficient:** If your access model is flat — "users in role Y can always access resource type Z" — ReBAC adds unnecessary infrastructure. Start with RBAC; migrate to ReBAC when relationship-based rules start appearing in code as ad-hoc DB joins.

**Common Mistakes:**
- **Modeling too many relation types upfront:** Start with the minimum viable relations the product needs (viewer, editor, owner). New relation types require authorization model updates and can affect existing check logic.
- **Not using direct relations when the relationship is simple:** If a specific user has a direct grant to a specific resource, write the direct tuple (`user:alice → viewer → document:X`). Do not route it through an intermediate group to fit the graph model.
- **Forgetting to delete tuples on membership removal:** Stale tuples grant access indefinitely. Write tuple deletions in the same transaction or event handler as the DB change that removes the relationship.
- **Calling check() per item in a list response:** N+1 checks per list item destroy throughput. Use `ListObjects` for bulk authorization or cache check results for the request lifetime.

**Security Considerations:**
- Tuple writes must be server-side only. Never accept a tuple write from an unauthenticated or under-privileged client.
- Audit all tuple writes and deletes: who wrote, what tuple, timestamp. OpenFGA does not provide this natively — wrap tuple write calls with an audit log insertion.
- Validate object IDs before writing tuples to prevent malformed objects from corrupting the authorization model.

**Testing Strategy:**
Define a relationship graph fixture (a set of tuples) and assert expected check() outcomes across the matrix of users, relations, and objects. Test negative cases: a user with no path to an object receives DENY. Test inheritance: deleting a tuple from a parent stops access through that path for all descendants. Test `ListObjects` returns the correct set when membership changes.

**Score:** Candidate (see pattern-lifecycle.md)

---

## Pattern: Policy Engine Selection Guide

**Problem:** Several mature policy engines exist (OpenFGA, OPA, Cedar, Permit.io). Picking the wrong one creates lock-in, performance problems, or a model that cannot express the required policies.

**Solution:** Select the engine based on the authorization model your application needs, your operational preferences (self-hosted vs. managed), and SDK requirements. The comparison below covers the four most common choices.

**Comparison table:**

| | OpenFGA | OPA | Cedar | Permit.io |
|---|---|---|---|---|
| **Model** | ReBAC (relationship graph) | ABAC / general policy language | ABAC with type system | RBAC + ABAC + ReBAC (multi-model) |
| **Policy language** | Authorization model DSL + tuples | Rego | Cedar language | Visual policy editor + API |
| **Best for** | SaaS with dynamic team/resource graphs | Infrastructure policy (k8s, API gateways, Terraform) | AWS IAM-style policies with compile-time verification | Teams wanting a hosted policy control plane with no infra |
| **Self-hosted** | Yes (Docker image) | Yes (binary) | Yes (library, no server required) | No (managed SaaS only) |
| **Managed** | Yes (Auth0 FGA) | Yes (Styra DAS) | Yes (AWS Verified Permissions) | Yes (core product) |
| **TypeScript SDK** | Official (`@openfga/sdk`) | Official (`@open-policy-agent/opa-wasm`) | Official (`@cedar-policy/cedar-wasm`) | Official (`@permitio/permit-fe-sdk`) |
| **Performance** | Sub-millisecond check with in-process tuple cache | Sub-millisecond with OPA sidecar + bundle cache | Microsecond — evaluates in-process via WASM | Network-bound per check (local PDP sidecar available) |
| **Auditability** | Tuple-level (who has what relation to what) | Policy-level (OPA structured decision log) | Policy-level (structured decision log) | Policy + API-level (dashboard + logs) |

**OpenFGA**

Best choice when permissions are derived from dynamic object relationships: team memberships, shared folders, org hierarchies. Implements the Zanzibar model with a dedicated relationship tuple store. The `check()` call traverses the authorization graph — no policy code needs to change when a new user joins a team, only a new tuple is written. The `ListObjects` API answers "what can user X see?" without scanning all objects in application code.

Weakness: the server is a stateful dependency; tuple consistency under high write load requires careful design. The authorization model DSL has a learning curve.

Do not use when authorization needs are purely role-based and static — RBAC is simpler and has no external dependency.

**OPA (Open Policy Agent)**

Best choice for infrastructure and API gateway policies where the input is well-structured JSON: k8s admission webhooks, Envoy external authorization, Terraform Sentinel. Rego is expressive and testable (`opa test`). Policies are deployed as versioned bundles, supporting GitOps workflows. OPA runs as a sidecar and caches policy bundles in memory, giving sub-millisecond evaluation.

Weakness: Rego has a steep learning curve and complex policies become hard to read. Not ideal for user-facing SaaS authorization where relationship traversal is needed — you would end up reimplementing Zanzibar in Rego.

Do not use as the primary authorization layer for a multi-tenant SaaS product unless the team has strong Rego expertise and the authorization model is attribute-based rather than relationship-based.

**Cedar**

Best choice when policies must be verified at compile time for correctness and there is no tolerance for policy logic errors: healthcare, finance, compliance-heavy products. Cedar is a purpose-built policy language with formal verification properties — the engine can statically analyze policies for safety before deployment. AWS Verified Permissions is the managed offering. The `cedar-wasm` package evaluates policies in-process with no network hop.

Weakness: the ecosystem is smaller than OPA's; community tooling is still maturing. Not a good fit if you need relationship graph traversal — Cedar evaluates individual policy checks, not graph paths.

Do not use if your primary need is relationship-based access (e.g., team sharing). Cedar can represent some relationships via attributes but is not designed for dynamic graph traversal.

**Permit.io**

Best choice for teams that want a hosted policy control plane with a UI for non-engineers to manage roles and permissions without code changes. Supports RBAC, ABAC, and ReBAC behind a single API. A local PDP (Policy Decision Point) sidecar is available to cache decisions and reduce latency.

Weakness: without the local PDP, every authorization check is a network call to Permit.io's cloud. Creates a vendor dependency on a critical path. Local PDP adds operational overhead similar to self-hosting OpenFGA.

Do not use if data residency, air-gapped deployment, or avoiding SaaS vendor lock-in on the authorization layer is a requirement.

**Decision flowchart:**
```
Does access depend on dynamic object relationships (teams, folders, shares)?
  YES → OpenFGA (or Auth0 FGA for managed)

Is this an infrastructure / API gateway / k8s admission policy problem?
  YES → OPA

Do you need compile-time policy verification or AWS-native managed service?
  YES → Cedar (or AWS Verified Permissions)

Do you need a hosted policy UI and want to avoid managing policy infrastructure?
  YES → Permit.io (with local PDP sidecar for performance)

Is your model simple and static (flat roles, no relationship traversal needed)?
  → Implement RBAC directly in your DB (see RBAC pattern above);
    no external engine required.
```

**Common Mistakes:**
- Adopting a policy engine before the authorization model is stable. Define the model (RBAC vs. ABAC vs. ReBAC) first, then choose the engine that implements it.
- Running OPA or OpenFGA as a synchronous remote call in the hot path without a local cache or sidecar. Authorization must add less than 5ms to p99 latency — treat it as a dependency that must be colocated or cached.
- Mixing authorization engines in the same application (e.g., OpenFGA for user resources, RBAC in DB for admin routes). Dual enforcement leads to policy divergence. Consolidate to a single source of truth.

**Security Considerations:**
- The policy engine is a critical security component. Apply the same hardening standards as the main application: no unauthenticated access to the admin API, mTLS between app and sidecar, signed policy bundles.
- For managed services (Auth0 FGA, Permit.io), verify that the vendor's SLA and data residency commitments match your compliance requirements before adopting.
- Test that the engine returns DENY — not NOT_FOUND or an error — on unknown objects and unknown relations. An untested unknown-object path can become an authorization bypass.

**Testing Strategy:**
For every engine: write a decision table test that enumerates all combinations of subject, action, and object that should ALLOW or DENY. Run these tests in CI against the actual engine binary or WASM module — do not mock the engine. For OPA: use `opa test` with the Rego test framework. For OpenFGA: use the model testing DSL (tuples + check assertions in YAML). For Cedar: use the Cedar policy testing utilities in the SDK. For Permit.io: test against the local PDP in CI, not the production cloud API.

**Score:** Candidate (see pattern-lifecycle.md)

---

## Official References

- [OpenFGA documentation](https://openfga.dev/docs) — Official Documentation
- [OpenFGA TypeScript SDK](https://github.com/openfga/js-sdk) — Official Repository
- [OPA documentation](https://www.openpolicyagent.org/docs/latest/) — Official Documentation
- [NIST RBAC standard (SP 800-162)](https://csrc.nist.gov/publications/detail/sp/800-162/final) — Trusted Reference Repository
- [Cedar language documentation](https://docs.cedarpolicy.com) — Official Documentation
- [OWASP Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html) — Trusted Reference Repository
- [Zanzibar: Google's Consistent Global Authorization System](https://research.google/pubs/zanzibar-googles-consistent-global-authorization-system/) — Trusted Reference Repository
