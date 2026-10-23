# Product Experience, Growth & Premium UI — Knowledge Map

**Purpose:** Agent-facing, use-oriented references for building compelling, measurable, accessible digital products. This is a knowledge catalog, not an instruction to install all libraries. Read the specific section relevant to the task.

## Route by task

| User intent | Start here | Deliverable |
|---|---|---|
| Visually distinctive startup-grade landing page | [Premium motion & visual systems](premium-motion-and-design-systems.md) | Art direction, tokens, responsive prototype, motion plan |
| Onboarding, navigation, forms, booking | [UX, research and conversion](ux-research-conversion.md) | Journey, evidence-backed flow, usability test |
| Improve purchases, signup, retention | [Measurement and growth](analytics-experimentation-growth.md) | Event taxonomy, funnel, experiment plan |
| Make UI accessible and fast | Premium motion + measurement guides | WCAG, reduced-motion, Web Vitals checks |
| Human, natural customer-facing copy and UX writing | [Human-centered UX writing](human-centered-ux-writing.md) | Voice principles, clear interface copy, error and onboarding language |
| Product launch strategy | UX and growth guides | Positioning, messaging, acquisition/activation metrics |

## Suggested agent workflow (advisory, adapt to task scope)

Use judgment: these steps are a menu for substantial user-facing product work, not a compulsory checklist for every small change. No hooks or enforcement are implied.

1. Define audience, user problem, value proposition, primary conversion, constraints and brand direction.
2. Inspect existing design system and user flows before introducing new dependencies.
3. Choose an intentional visual direction; avoid generic gradient/card-template design. Provide 2–3 concrete references and explain what is being adapted rather than copying.
4. Create a component/token system with mobile, desktop, RTL and Hebrew support where applicable.
5. Design motion around hierarchy, feedback and narrative; prefer transform/opacity and respect `prefers-reduced-motion`.
6. Instrument a privacy-conscious event taxonomy; define funnel and guardrail metrics before optimization.
7. Validate keyboard/screen-reader support, contrast, loading, responsiveness and Core Web Vitals.
8. Test with real users where feasible; use controlled experiments rather than claiming a color or animation necessarily increases sales.
9. Record decisions, source URLs, dates checked, licensing and measurable outcomes.

## Source trust & usage rules

- **Official documentation**: source of truth for APIs, compatibility and implementation.
- **Established research organizations**: guidance for UX behavior, usability and conversion; distinguish evidence from opinion.
- **Vendor guides**: useful for implementing their products; not neutral evidence of business uplift.
- **Inspiration galleries**: visual references, not proof of conversion effectiveness.
- Link to external research rather than copying proprietary or paywalled reports. Verify package license, maintenance and versions before installation.
- No dark patterns: no fake scarcity, forced continuity, hidden costs or misleading consent.
- Accessibility, performance and privacy are launch gates, not optional polish.

## Other relevant existing library sections

Consult `docs/official-docs/`, `docs/frameworks/`, `docs/reference-repositories/`, `patterns/`, `templates/`, `docs/architecture-guides/` and `patterns/testing/` before duplicating content.

## Catalog maintenance

These guides are curated pointers, not vendored copies. Recheck official links and package maintenance before each project adoption. Keep this directory task-oriented, not a dumping ground for unreviewed resources.
