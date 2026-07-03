# Connector Verification Matrix

> Owner: connector-governance. Inventory source of truth stays
> [`external-systems/README.md`](../../external-systems/README.md) /
> [`core/capability-registry.yaml`](../../core/capability-registry.yaml); selection policy stays
> [`core/connector-policy.md`](../../core/connector-policy.md). This matrix records **verification
> status** per inventory entry — what was actually proven, where, and how — so "documented" is
> never silently presented as "ready". Refresh it whenever a downstream-validation run re-executes
> the connector experiments.
>
> Last verification run: 2026-07-03, session validating Engineering OS reference commit `54982cb`
> against a real downstream install in `yotamfried-ux/Expiriens-saas-0.9`
> ([PR #2](https://github.com/yotamfried-ux/Expiriens-saas-0.9/pull/2)). Evidence commands and
> outputs are recorded in `.claude/plans/pr-e-regression-and-downstream-validation.md` and the
> downstream PR body.

## Status vocabulary

- **verified** — exercised in this run with a concrete call/output.
- **available-unexercised** — tool/server registered and reachable in the verification session but
  no call was made; not claimed as verified.
- **approval-gated** — reachable but each call requires interactive user approval in this
  environment; usable, not autonomously verifiable.
- **documented (manual-by-design)** — inventory guide + integration doc exist; authentication and
  activation are deliberately per-project manual steps (`mcp_auto_install_allowed: false`,
  `broad_mcp_toolsets_allowed_by_default: false` in the capability registry), so no install is
  expected to exist until a project opts in.
- **knowledge-layer** — service guide consulted during routing (docs, recommendations, patterns);
  it has no runtime endpoint of its own to verify.

## Deterministic layer (verified this run — applies to every connector)

| Check | Result | Evidence |
|---|---|---|
| Registry presence: 47 service + 12 MCP entries, categories intact | ✅ pass | `core/capability-registry.yaml` coverage contract (min 26 total / 12 MCP) + `test-capability-registry.sh` |
| Owner dir + README for every entry (59/59) | ✅ pass | scripted scan of every registry `path:` for `README.md` |
| Routing rule for every MCP connector (12/12 `auto` rows + 5 policy-level rows: context7, sentry, vercel, expo, postman) | ✅ pass | `check-required-connectors.sh --check-coverage` |
| Evidence requirement enforced (declared connector without usage evidence blocks) | ✅ pass | downstream Exp 4: installed `check-connector-evidence.sh` blocked a supabase-declaring plan with no usage evidence |
| Routing selection fires on realistic tasks | ✅ pass | downstream Exp 6: DB task without supabase/postgres blocked; UI task without figma blocked; correct declarations pass |
| Downstream preservation: connector guides reachable read-only from installed target; no MCP config auto-copied (by design) | ✅ pass | Exp 1 + `next_pr_contract.must_not_do` in the registry |

## MCP connectors (12)

| Connector | Owner dir | Routing | Session availability (this run) | Downstream (Expiriens) | Classification |
|---|---|---|---|---|---|
| github | ✅ | auto | **verified** — PR/branch/file reads, PR create/update, review replies all succeeded | used for push/PR through git remote + MCP | verified |
| notion | ✅ | auto | available-unexercised (server connected; progress-validation waiver path exercised instead) | not installed | documented (manual-by-design) |
| slack | ✅ | auto | not connected in this session | not installed | documented (manual-by-design) |
| linear | ✅ | auto | not connected in this session | not installed | documented (manual-by-design) |
| jira | ✅ | auto | not connected in this session | not installed | documented (manual-by-design) |
| stripe | ✅ | auto | not connected in this session | not installed | documented (manual-by-design) |
| supabase | ✅ | auto | available-unexercised (server connected) | not installed | documented (manual-by-design) |
| postgres | ✅ | auto | not connected in this session | not installed | documented (manual-by-design) |
| google-drive | ✅ | auto | available-unexercised (server connected) | not installed | documented (manual-by-design) |
| google-sheets | ✅ | auto | not connected in this session | not installed | documented (manual-by-design) |
| figma | ✅ | auto | available-unexercised (server connected) | not installed | documented (manual-by-design) |
| discord | ✅ | auto | not connected in this session | not installed | documented (manual-by-design) |

## Policy-level connectors (core-fixed / project-dependent in `core/connector-policy.md`)

| Connector | Policy role | Session availability (this run) | Classification |
|---|---|---|---|
| GitHub | core-fixed | **verified** (see above) | verified |
| Context7 | core-fixed | **approval-gated** — `resolve-library-id` call returned "requires approval"; server reachable | approval-gated (environment limitation, not a system gap) |
| Sentry | core-fixed | available-unexercised (tools loaded; no error data existed to query in either repo) | available-unexercised |
| Vercel / Expo / Postman / Composio | project-dependent | Vercel + Postman + Composio servers connected, unexercised; Expo not connected | documented (manual-by-design) |

## Service connectors (47 — knowledge layer)

All 47 entries across 11 categories (llm_providers_ai_apis ×7, ai_agent_frameworks ×5,
vector_databases_search ×7, databases_data_pipelines ×3, authentication_identity ×3,
payments_commerce ×3, observability_analytics ×7, feature_flags_experimentation ×3,
communication_media ×5, scheduling_events ×3, crm ×1) verified for: registry entry, owner
directory with README integration guide, and reachability from an installed downstream target via
the read-only reference path. These are **knowledge-layer** entries by design: they are consulted
during routing (step 4 of the routing algorithm) and carry setup instructions, but have no runtime
endpoint Engineering OS could probe. None is classified "installed" anywhere until a project's
own Route Plan selects and authenticates it — exactly the `authenticate only the connectors
selected for this project` contract in `ENGINEERING_OS_SETUP.md`.

## Explicit non-gaps and their reasons

- **MCP connectors not installed downstream** — by design: `mcp_auto_install_allowed: false`;
  install is a per-project opt-in with the fallback ladder in `core/connector-policy.md`.
- **Context7 approval gating** — a property of this verification environment's MCP permission
  mode, not of the connector definition; the installer's connectivity check and the documented
  `claude mcp add` path were verified present.
- **No connector is "broken" or "missing from the registry"** in this run; the one regression
  found and fixed this run (nemotron security workflow diff truncation) is a **skill** artifact,
  tracked in the skill matrix.
