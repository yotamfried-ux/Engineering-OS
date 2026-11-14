# Experience routing — AI agent fast path

This route supplements the existing [UI/UX library](README.md), [UI patterns](../../patterns/ui/README.md) and [UI UX Pro Max skill](../../external-skills/ui-ux-pro-max/README.md). Do not replace or reinstall those capabilities. **Engineering-OS is knowledge, not runtime**: this document tells agents what to read and produce, but does not imply an automatic hook currently enforces it.

## When to activate

Any feature or project with a human-facing result: web/app screens, marketing website, desktop app, kiosk, email, notification, chatbot, assistant, game, documentation, customer-facing API portal or service flow. Trigger on **new feature design, redesign, new audience, new channel, copy audit or conversion/engagement issue**, not only when user explicitly asks "UI/UX".

## Choose the smallest route

| Task | Read first | Read next (if needed) | Deliverable |
|---|---|---|---|
| Product from concept / new user journey | [Content playbook](SCREEN-CONTENT-PLAYBOOK.md) §1–3 | [Source atlas](SOURCE-ATLAS.md), [Quality gate](PRODUCT-EXPERIENCE-QUALITY-GATE.md) | Audience/positioning brief, flow map, 3 design directions, content inventory |
| New page/screen or UI redesign | [Screen content](SCREEN-CONTENT-PLAYBOOK.md) §2–4 | [Atlas](SOURCE-ATLAS.md), `patterns/ui`, `ui-ux-pro-max` | Real content with states, visual decisions and interaction spec |
| Landing page / conversion | [Content playbook](SCREEN-CONTENT-PLAYBOOK.md) §1, §3–6 | NN/g microcontent, Baymard if commerce, inspiration in [atlas](SOURCE-ATLAS.md) | Specific promise, proof, objections, CTAs and event instrumentation |
| Form, workflow, account or checkout | [Content playbook](SCREEN-CONTENT-PLAYBOOK.md) §3–4 | GOV.UK patterns, Baymard and official platform patterns in [atlas](SOURCE-ATLAS.md) | Complete success/error/retry/cancellation/review path |
| Animation/interactivity | [Motion playbook](MOTION-AND-INTERACTIONS.md) | Apple/Fluent/W3C/vendor API docs in [atlas](SOURCE-ATLAS.md) | Before/after behavior, accessible reduced-motion variant and capture |
| Email/SMS/push/chat/kiosk/voice | [Content playbook](SCREEN-CONTENT-PLAYBOOK.md) §3 | Channel-native standards + source atlas | Channel-specific copy, consent, deep-link and privacy/exit behavior |
| Existing project audit | [Quality gate](PRODUCT-EXPERIENCE-QUALITY-GATE.md) | Only relevant source links | Findings by severity, concrete before/after and retest evidence |
| Booking system end-to-end | [Booking example](EXAMPLE-BOOKING-EXPERIENCE.md) | Source atlas + actual `templates/booking-system` | Full booking journey + dynamic copy + real backend contract |

## Seven-step workflow — no generic AI UI

**0. Retrieve existing project truth.** Product requirements, actual entities/pricing/status, supported devices, locale, logo/brand, constraints, analytics, permissions. Avoid guessing. This library gives patterns; it does not contain customer facts.

**1. Diagnose audience and outcome.** Write user jobs and objections, competitive differentiation *hypothesis*, one measurable primary outcome, and 1–2 guardrails (trust/support/accessibility). Identify first-time vs power users and possible assistive needs.

**2. Sample authoritative and inspiring references.** Read 2 Tier A official content/behavior sources + one research reference if pertinent + inspect three diverse actual flows. Produce a short evidence table and note uninspected/paywalled items. Don't treat appearance as success evidence.

**3. Produce three directional concepts.** Different art direction, typographic hierarchy, content tone and interaction personality; each with a rationale, constraints and non-goals. Avoid replacing a brand with an off-the-shelf palette; allow user/owner decision when available.

**4. Design flow AND write finished words before coding.** Map entry → choice → review/consent → async/pending → authoritative success → manage/undo/support; include filtered-empty, slow, offline, invalid and conflict states. Write actual headings, actions, labels, helper text and cross-channel messages with placeholders *only for dynamic data*.

**5. Prototype representative states.** One mobile and one desktop/adaptive viewport where relevant, plus at least one end-to-end interactive path. If animation adds value, specify why, when and the no-motion version. Use project's existing component architecture/skill; don't introduce unneeded UI packages.

**6. Implement, observe and verify.** Test real backend results, accessibility (WCAG 2.2 target), screen readers/keyboard/touch, RTL and localization, performance, mobile safe areas, browser/native behavior, errors/retry and truthful event logging. Capture actual before/after screenshots and representative interaction video if possible.

**7. Evaluate and learn.** Compare to the [quality gate](PRODUCT-EXPERIENCE-QUALITY-GATE.md), test primary task with representative users, report evidence and uncertainties, and record what should become reusable product knowledge in Engineering-OS. A rendered mock isn't proof that an entire journey works.

## Expected agent artifacts

For any significant new user-facing journey, produce these five lightweight files in the **project being built** (not automatically in this central library):

1. `product-experience-brief.md`: target audience, task, differentiator, tone, proof and constraints.
2. `journey-map.md`: steps/branches/channels + authoritative states.
3. `screen-content-matrix.md`: title, CTA, microcopy, data source and 4 states per screen.
4. `visual-interaction-spec.md`: three alternatives, one selected, examples, tokens, motion/accessibility.
5. `experience-qualification.md`: automated and manual tests, screenshots, real user feedback, outcome metrics, PASS/PARTIAL/NOT TESTED.

These are a **recommended artifact contract**, not files that currently exist. For a small one-screen change, combine them into one concise review document.

## Constraints / escalation

- On missing brand evidence or an unknown target user, mark assumptions and present alternatives, instead of claiming a proven design.
- Don't merge a visually appealing design based solely on generated screenshots; confirm implementation and usability.
- Third-party screenshots and galleries are reference links, not assets to import without permission.
- Continue to respect [source provenance](../../capability-registry/SOURCE-POLICY.md) and [agent execution routing](../../capability-registry/EXECUTION-FAST-PATH.json).
