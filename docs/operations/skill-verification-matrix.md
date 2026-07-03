# Skill Verification Matrix

> Owner: skill-governance. Inventory source of truth stays
> [`external-skills/README.md`](../../external-skills/README.md); selection/activation policy stays
> [`core/skill-orchestration-policy.md`](../../core/skill-orchestration-policy.md). This matrix
> records **verification status** per skill — what was actually proven in a real downstream
> install, and what remains manual or environment-limited — so "registered" is never silently
> presented as "working". Refresh it whenever a downstream-validation run re-executes the skill
> experiments.
>
> Last verification run: 2026-07-03, Engineering OS reference commit `54982cb` installed into
> `yotamfried-ux/Expiriens-saas-0.9` ([PR #2](https://github.com/yotamfried-ux/Expiriens-saas-0.9/pull/2)).

## Deterministic layer (verified this run — applies to every skill)

| Check | Result | Evidence |
|---|---|---|
| Registry/SIP presence: 8 active skills + accelerator + deprecations | ✅ pass | `test-capability-registry.sh` ("active skills: 8"); `enforce-skill.sh` S1/S2 gate the 4-file contract and README registration |
| Selection coverage: every skill has a routing rule or documented `NOT_AUTO_REQUIRED` (gstack, nemotron, frontend-design) | ✅ pass | `check-required-skills.sh --check-coverage` |
| Routing selection fires on realistic tasks | ✅ pass | downstream Exp 7: UI task without ui-ux-pro-max blocked; auth task without security-review blocked; correct declarations pass |
| Runtime skill evidence enforced | ✅ pass | downstream Exp 3: installed write gate blocked until superpowers evidence existed and security-review was explicitly waived with reason; heading-only waivers rejected (Exp 5) |
| Bootstrap detection in a real installed target | ✅ pass | `skill-bootstrap.sh --profile default` in Expiriens: 5/5 L2 defaults detected, 0 missing |

## Per-skill status

| Skill | Level | Registry/SIP | Routing | Downstream (Expiriens, this run) | Classification |
|---|---|---|---|---|---|
| superpowers | L2 default | ✅ | rule | **verified** — portable `/superpowers-*` commands installed and parse; runtime gate accepted superpowers evidence (verify-command read) on the positive path | available-and-verified |
| security-review | L2 default | ✅ | rule | **partially verified** — command + CI workflow installed; keyless skip path verified; runtime waiver path verified; **full Nemotron-backed review not run (no `Nemotron_api_key` in env)**. Regression found+fixed this run: generated workflow silently truncated diffs >12KB → now chunked full-diff review with fail-closed cap (`test-security-review-workflow-generator.sh`, lesson `security-gate-silent-diff-truncation.md`) | installed-not-fully-verified (engine key = manual-by-design) |
| graphify | L2 default | ✅ | rule | **partially verified** — binary present (0.9.5), bootstrap detects it, PATH-absence fallback of installed hooks verified; **graph build failed downstream: doc-bearing corpus requires an LLM API key** (`ENGINEERING_OS_SETUP.md` step "fill .env" is the documented manual step). In the OS repo itself the graph exists and G7 evidence was exercised | installed-not-fully-verified (API key = manual-by-design) |
| rtk | L2 default | ✅ | rule | **verified** — binary present (0.42.4), settings hook wired (`rtk hook claude`), PATH-absence no-crash fallback verified in installed target | available-and-verified |
| claude-mem | L2 default | ✅ | rule | **installed, not validated** — bootstrap auto-installed it (`~/.claude-mem` created); its SessionStart/Stop behavior only manifests in a fresh Claude session, which this run cannot observe from inside itself | installed-not-validated (validation needs a new session) |
| ui-ux-pro-max | L2 (UI) | ✅ | rule | not installed (plugin-marketplace skill; no UI surface in the target) — routing correctly REQUIRES it for UI tasks (Exp 7 block) | documented-only in this target; unsupported-in-env for auto-install |
| claude-code-workflows | L1/L2 | ✅ | rule/exempt per README | not installed (manual file copy by design, `activation.md`) | manual-by-design |
| gstack | L1 opt-in | ✅ | NOT_AUTO_REQUIRED (documented) | not installed (opt-in, needs Bun setup) | manual-by-design (opt-in) |
| frontend-design | L0 | ✅ (deprecated) | NOT_AUTO_REQUIRED (documented) | correctly NOT installed | deprecated — do not install |
| nemotron (accelerator, not a skill) | L1 | ✅ compat-redirect to `external-systems/nvidia-nemotron/` | NOT_AUTO_REQUIRED (documented) | MCP server not available in this environment; `.claude/agents/nemotron-*` adapters present upstream | unsupported-in-env (key/server = manual-by-design) |

## Explicit gaps found and their disposition

- **security-review diff truncation (fixed this run)** — the one genuine defect: the generated
  CI security gate reviewed only the first 12000 diff chars. Root-caused in
  `scripts/skill-bootstrap.sh`, fixed to chunked/fail-closed review, regression-tested
  bidirectionally, lesson recorded. Not an open gap.
- **Nemotron/graphify API keys absent** — environment/manual-by-design: both are the documented
  `.env` prerequisites in `core/workflow.md` `<onboarding>` and `ENGINEERING_OS_SETUP.md`'s
  required manual follow-up checklist; the system degrades loudly (setup checklist + capability
  report "Action Required"), not silently.
- **claude-mem runtime behavior** — observable only from a subsequent session; tracked here as
  installed-not-validated rather than claimed verified.
- No skill is missing from the registry, missing from routing, or waiver-gated without a
  documented waiver path in this run.
