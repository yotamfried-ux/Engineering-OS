# Human-Centered UX Writing, Content Design & Product Voice

**Status:** curated reference; advisory, not a mandatory hook or automated enforcement. **Scope:** interface copy, transactional messages, onboarding, empty/error states, notifications, settings, support, marketing-to-product transitions and AI-generated customer-facing text.

## Why this is a product discipline

Good product copy helps people understand what is happening, what they can do next, what a choice costs and what to expect. It affects trust, task completion, comprehension, accessibility and sometimes conversion. Do not optimize clicks at the expense of informed consent or long-term trust.

## Authoritative guidance and reusable inspiration

| Source | Official link | What to learn |
|---|---|---|
| GOV.UK Content Design | https://www.gov.uk/guidance/content-design | Plain language, user needs, scannability, content patterns |
| GOV.UK Style Guide | https://www.gov.uk/guidance/style-guide | Clear, consistent, direct writing |
| GOV.UK Design System | https://design-system.service.gov.uk/ | Form labels, hints, validation and error content in context |
| Microsoft Writing Style Guide | https://learn.microsoft.com/en-us/style-guide/welcome/ | Warm, clear, inclusive product voice and terminology |
| Google Material Design — Writing | https://m3.material.io/foundations/content-design/overview | UI language within a design system (verify current path) |
| Apple Human Interface Guidelines | https://developer.apple.com/design/human-interface-guidelines/ | Platform labels, alerts, clarity and tone |
| Shopify Polaris Content | https://polaris.shopify.com/content | Merchant-facing product voice, terminology and UI patterns |
| IBM Carbon — Content | https://carbondesignsystem.com/guidelines/content/overview/ | Enterprise UI writing and component guidance |
| Mailchimp Content Style Guide | https://styleguide.mailchimp.com/ | Human voice, humor boundaries and inclusive language |
| Nielsen Norman Group | https://www.nngroup.com/articles/ | Usability research on readability, errors, clarity and trust |
| W3C WCAG 2.2 | https://www.w3.org/TR/WCAG22/ | Accessible labels, instructions, error identification |

Links are pointers to the publisher's documentation, not copies of proprietary content. Verify current paths and relevant editions when implementing.

## Principles for writing like a person, not a generic AI

1. **Be specific, not grandiose.** Replace vague praise, inflated adjectives and promises with what the user can actually do.
2. **Say what happens next.** Button labels and confirmations should describe the action or result.
3. **Use everyday language.** Prefer familiar words, active voice and short sentences; retain technical terms only where users need them.
4. **Match emotional context.** Errors need calm, helpful instructions; success needs clarity, not confetti in prose; billing and privacy need precision.
5. **Respect attention.** Avoid repeated welcomes, needless exclamation marks, filler, excessive emojis and decorative text.
6. **Sound human without pretending to be human.** Do not invent personal experiences, empathy, urgency, guarantees or testimonials.
7. **Build trust.** Explain costs, deadlines, consequences, data use and irreversible actions before commitment.
8. **Use humor sparingly.** Never joke about money, access, safety, errors or distress.
9. **Stay consistent.** Define a brand voice, terminology, person of address and tone variation by situation.
10. **Adapt to culture and language.** Hebrew RTL, gender-inclusive natural phrasing, mixed Hebrew/English UI, numerals and dates require editorial review, not word-for-word translation.

## Copy types and questions to ask

| Surface | Editorial question |
|---|---|
| Navigation | Can people predict where this takes them? |
| CTA | Is the action concrete, honest and distinguishable from alternatives? |
| Form label/hint | Can users complete the field without guessing? |
| Validation/error | What happened, why if known, and how can the user recover? |
| Empty state | Why is it empty, and is there a meaningful next action? |
| Onboarding | Does each sentence reduce uncertainty and speed time-to-value? |
| Notification | Is this useful now, actionable and respectful of attention? |
| Consent/billing | Are the choices and consequences understandable and non-deceptive? |
| Confirmation | Is the outcome clear and any next step explicit? |
| Cancellation/deletion | Are consequences and recovery options clear without guilt? |

## Voice system: reusable across products

For each product record:
- Audience, literacy/accessibility considerations, locale and user intent.
- **Voice attributes:** e.g. clear, calm, confident, approachable — with definitions, not just adjectives.
- **Tone by situation:** routine, celebratory, confusing, high-stakes, error, urgent.
- Preferred terminology and words to avoid; casing, punctuation, numbers, dates, pronouns.
- Reading level, brevity and localization standards.
- Approved factual claims and escalation path for legal, medical or financial copy.

Voice is stable; tone adapts to context. A playful brand can still be serious during an account lockout.

## AI copy editing pass

Draft -> remove generic AI patterns -> verify facts -> check user intent and next action -> assess accessibility/translation -> test with users.

Common AI artifacts to edit out:
- “We're thrilled to announce”, “unlock the power”, “seamless experience”, “revolutionary”, “elevate your journey” without concrete substance.
- Redundant apologies or congratulatory statements.
- Excessively symmetric lists, unnatural over-explanation and repeated benefit claims.
- Fake personalization (“I know exactly how you feel”), unearned confidence and invented social proof.
- Vague CTAs such as “Learn more” when a more precise action is possible.

These are **signals to review, not banned phrases**; context and brand voice matter more than a mechanical word blacklist.

## Neutral, reusable illustration (not a product-specific template)

| Less helpful | More helpful | Why |
|---|---|---|
| “An unexpected error occurred” | “We couldn't save your changes. Try again.” | Gives outcome and recovery; only if retry is actually possible |
| “Submit” | “Save changes” | Names the action |
| “Success! Your amazing journey begins!” | “Your changes are saved.” | Confirms what happened without hype |
| “No data available” | “Nothing here yet.” + a relevant next action when one exists | Explains the state without blaming the user |

Examples are deliberately generic; adapt to the actual workflow, locale and product facts. Do not paste them indiscriminately.

## Review and measurement

- Review actual UI screenshots or flows, not isolated strings alone.
- Check comprehension, time-to-complete, error recovery, support contacts and user trust.
- A/B test when traffic and instrumentation permit; do not assume one voice converts better universally.
- Include localization QA, screen-reader announcement, truncation at mobile widths and RTL.
- Ensure legal/consent language is reviewed by appropriate specialists where necessary.

## Lightweight agent usage

When asked to write or improve user-facing text, inspect the product voice (if present), screen context and intended action; use this guide and selectively follow authoritative sources. Propose wording with a short rationale and flag unknown facts. Do not force unrelated tasks to load this guide, run tests or produce reports. This is a knowledge aid, not a hook.
