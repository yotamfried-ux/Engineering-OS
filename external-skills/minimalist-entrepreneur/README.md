# Minimalist Entrepreneur — founder advisory skills (catalog only)

**Canonical upstream:** https://github.com/slavingia/skills
**Upstream author:** Sahil Lavingia; based on *The Minimalist Entrepreneur*.
**Source tier:** A for the upstream skill implementation and its own stated behavior; not independent validation of its business claims.
**Status:** CANDIDATE / NOT INSTALLED / NOT QUALIFIED (2026-11-14).

## What it is and when to use

Ten advisory Claude Code skills, not a connected CRM, lead database, outbound mailer, or autonomous sales engine. The canonical upstream README lists: `find-community`, `validate-idea`, `mvp`, `processize`, `first-customers`, `pricing`, `marketing-plan`, `grow-sustainably`, `company-values`, `minimalist-review`.

| Task | Candidate skill | Human-verifiable outcome |
| --- | --- | --- |
| Acquire initial paying users | `first-customers` | Named *user-supplied or legitimately researched* prospects, tailored outreach drafts, follow-up log and weekly target |
| Set initial SaaS price | `pricing` | Unit economics, competitive alternatives, willingness-to-pay research plan and assumptions |
| Test an idea | `validate-idea` | Interview plan and falsifiable demand criteria |
| Create channel strategy | `marketing-plan` | Audience, channel experiments, budget and measurement plan |
| Control scope/cost | `mvp`, `grow-sustainably` | MVP boundaries, runway and measurable decision gates |

**First-customer workflow from upstream:** contact existing relationships, then relevant communities, then carefully targeted strangers; create two 10-person outreach lists, a personalized draft, initial pricing, and a weekly sales target. The upstream is a planning aid: it does **not** discover verified private contacts, send messages, guarantee customers, or prove conversion rates.

## Overlap and do-not-use

- Before opening this reference, use `docs/product-experience/analytics-experimentation-growth.md` for general measurement and experimentation, and existing product/UX research routes for validation.
- Use this only for founder-specific **sales coaching and decision frameworks**; do not substitute for platform documentation, evidence-based market research, CRM data, consent/privacy compliance, or production analytics.
- Do not infer that the creator's illustrative numbers (e.g. 200 × $10) are a profit forecast: they are **gross revenue before churn, fees, taxes and costs**.
- Do not bulk-send outreach, scrape restricted data, invent leads or testimonials, or automate communications without explicit authorization and applicable compliance review.
- Treat claims such as fixed percentages of growth from manual sales as author opinions, not validated universal benchmarks.

## Implementation, installation and security

Upstream documented Claude Code plugin commands:
```
/plugin marketplace add slavingia/skills
/plugin install minimalist-entrepreneur
```
Do **not** execute these during discovery. Installation changes the agent's behavior and requires review. The source is plain-text skill prompts; no live API or service connection is evidenced by the inspected README and sampled `first-customers`/`pricing` skill files. License must be checked from the repository's actual license file or explicit grant before copying/repackaging: a plugin manifest label alone is not sufficient.

**Verification performed:** GitHub upstream repository, README, and two skill files (`skills/first-customers/SKILL.md`, `skills/pricing/SKILL.md`) were read on 2026-11-14. This proves existence and documented behavior of those files **only**. It does not verify all ten files, prompt safety, licensing, host compatibility, business effectiveness, or actual installation.

**Promotion gate:** inspect all 10 skill files, permission/license and security posture, compare overlaps, test representative founder scenarios, then if adopted create the standard `external-skills/<name>/` four-file contract (`README.md`, `integration.md`, `policy.md`, `activation.md`) and update the registry. Keep catalog-only until then.

## Primary sources

- https://github.com/slavingia/skills
- https://github.com/slavingia/skills/blob/main/README.md
- https://github.com/slavingia/skills/blob/main/skills/first-customers/SKILL.md
- https://github.com/slavingia/skills/blob/main/skills/pricing/SKILL.md
