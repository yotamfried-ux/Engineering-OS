# Notification UX, human writing, accessibility and localization

Authoritative foundations: [Nielsen Norman Group](https://www.nngroup.com/articles/), [GOV.UK Design System](https://design-system.service.gov.uk/), [Microsoft Writing Style Guide](https://learn.microsoft.com/en-us/style-guide/welcome/), [Material Design](https://m3.material.io/), [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/), [WCAG 2.2](https://www.w3.org/TR/WCAG22/), [WAI-ARIA live regions](https://www.w3.org/WAI/ARIA/apg/).

## High-quality interaction principles

- **Inline feedback:** errors close to the field; preserve input; explain how to fix it; summarize errors for screen readers.
- **Toast/snackbar:** brief, nonblocking, appropriate for low-risk outcomes; never the only record of critical information; accessible announcement.
- **Banner:** persistent but dismissible where appropriate, useful for system-wide or page-wide conditions.
- **Dialog:** reserved for consequential decisions or blockers, with explicit action labels, focus management and keyboard escape behavior where safe.
- **Inbox/activity feed:** durable, searchable, read/unread, actionable, paginated, permission-scoped; distinguish status from audit log.
- **Outbound push/email/SMS:** use only when user is away or timeliness warrants; deep link to authenticated destination; respect preferences and sensitive lock-screen previews.

## Content model

Use a concise title, outcome, resource/context, time when material, single primary next action and fallback help. For errors, explain what failed, whether changes were saved, and what retry actually does. Distinguish “request received”, “booking confirmed” and “reminder delivered”. Never fabricate a reason or guarantee.

**Voice:** calm, human, concrete and respectful. Serious tone for billing, access and safety; warm but restrained for routine successes. Avoid AI clichés, vague “Something went wrong”, manipulative urgency and redundant apologies. Reuse [human-centered UX writing](../product-experience/human-centered-ux-writing.md).

## Hebrew / RTL / accessibility

- Test mixed RTL Hebrew with LTR names, email addresses, links, numbers and times; use locale-aware date formatting and bidi isolation.
- Prefer natural inclusive Hebrew over awkward forced gender; test truncation, pluralization, screen readers and push lock-screen previews.
- Use semantic roles and appropriate live region politeness; prevent repeated announcements; manage focus in dialogs.
- Never convey severity only by color, animation or sound; provide text equivalents, readable contrast and reduced-motion options.
- Support quiet hours, do-not-disturb, granular preferences and digest options without silencing essential security messages.

## Anti-patterns

Do not show a success toast before the server commits. Do not send multiple channels for every event. Do not hide important errors in a toast that disappears. Do not use notification count as a vanity engagement target. Do not include sensitive customer data in notification previews by default.
