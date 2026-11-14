# Product experience quality gate

Use after implementation, **not** as an aesthetic judgment of a static mock. This augments existing Engineering-OS functional/security tests rather than replacing them. See [Experience routing](EXPERIENCE-ROUTING.md), [Screen content](SCREEN-CONTENT-PLAYBOOK.md), [Motion](MOTION-AND-INTERACTIONS.md), [W3C WCAG 2.2](https://www.w3.org/TR/WCAG22/) and [W3C ARIA APG](https://www.w3.org/WAI/ARIA/apg/patterns/).

## Evidence record (required)

```yaml
project: "<name>"
revision: "<commit/build version>"
environment: "<URL/device/build + backend>"
user_job: "<task>"
audience: "<persona / participants; disclose assumptions>"
platforms: ["<tested device/browser/channel>"]
date: "<UTC timestamp>"
references:
  official: ["<source URLs>"]
  observed_examples: ["<URL + reviewed date>"]
screenshots: ["<actual implementation + state + tested device>"]
video: ["<real interactions + timestamps if captured>"]
tests: ["<test names/run URLs and observed results>"]
known_gaps: ["<unknowns or blockers>"]
```

Do not mark a requirement PASS from a design file, screenshot or link alone. Only tests and observed behavior on the stated build/environment can validate it; mark NOT TESTED otherwise.

## Weighted experience rubric (100 possible points; *not* empirical business conversion proof)

Score each domain 0–5 (0: absent; 1: significant failure; 2: inconsistent; 3: usable baseline; 4: strong; 5: exemplary with representative evidence). Multiply by the weighting/5. **Weighted score is a review prioritization heuristic, not a certified UX rating.**

| Domain | Weight | Evidence and observable acceptance |
|---|---:|---|
| Audience fit & differentiation | 15 | Real intended user can identify whom product serves, outcome and what is distinct; no generic or unsupported claims |
| Content clarity & trust | 20 | Headings/labels/CTAs describe real action; price/policy/proof honest; users can explain next step |
| Task and information architecture | 20 | Representative task completes without confusion; direct navigation and expected editable steps |
| Visual hierarchy & brand expression | 10 | Coherent hierarchy, typography, asset strategy, spacing, visual identity fit, mobile/desktop adaptation |
| Interaction and motion | 10 | Meaningful feedback, no input traps; purpose, reduced-motion and responsiveness verified |
| Accessibility & localization | 15 | WCAG 2.2 AA target where applicable, keyboard/screen reader/RTL/locale tested on real implementation |
| Resilience, states and recovery | 5 | Slow/empty/error/offline/conflict/partial/async/confirmation tested; real state integrity |
| Cross-channel lifecycle and measurement | 5 | Consistent reminders/receipt/support, consent controls and analytics with privacy guardrails |

**Hard blockers** override the score: critical accessibility blockers; deceptive pricing/claims or dark patterns; leaked personal data; "confirmed" without authoritative backend state; lost work without recovery; a critical task impossible to complete. The completed journey cannot be declared qualified with any hard blocker. Also see project functional/security qualification.

## Golden path + failure matrix

Execute using the actual backend or labeled realistic isolated test fixture; never confuse mock data with live inventory.

| Case | Test | Required proof |
|---|---|---|
| New user | Discover value → primary task → first actual success | Video/screenshot and authoritative backend event |
| Returning user | Resume, identify change, complete repeat task | Restored valid data and no repeated unnecessary setup |
| Unavailable/empty | Zero inventory, filter-empty, never-initialized | Helpful message + valid next action |
| Validation | Missing value, format, conflicting input | Specific inline error, existing input preserved, keyboard and spoken output |
| Concurrent change | Slot/product/status taken by someone else | No false success; refresh/alternative/retry |
| Slow/network loss | Delayed response, loss/recovery, double tap | Honest pending, idempotent commit, no silent duplicate |
| Manage/cancel | Review, change, cancel/refund/restore where applicable | Clear policy/impact and backend state reflected across channels |
| Accessibility | Keyboard-only, screen reader, zoom, focus, contrast, reduced motion | Device/browser/version + findings + remediation |
| Localization | RTL, long text, dates, currencies, timezones | Real device captures, no clipping/meaning errors |
| Cross-channel | Confirmation email/SMS/push/in-app/deep link if supported | Actual delivered/received message and valid destinations; consent respected |
| Responsive/desktop | 320px-ish narrow viewport, mobile browser, tablet, desktop/multi-window as applicable | No obstruction, usable touch targets and form controls |
| Privacy/support | Public notification privacy, session timeout, support/refund escalation | Test results + secure escape path |

## Honest outcome measurement

Define one product-specific primary outcome (e.g. verified appointment completions ÷ eligible booking sessions), plus guardrails: failed bookings, duplicate charges, errors per step, support requests, refunds/cancellations, accessibility errors, user-reported trust and response times.

- Funnel event taxonomy: `entry_viewed`, `task_started`, `option_selected`, `review_viewed`, `submit_attempted`, `server_confirmed`, `conflict_shown`, `recovered`, `task_abandoned`. Adapt names to project and actual events, avoid PII and duplicate events.
- Segmentation: platform, first-time/returning, locale and low-bandwidth where privacy-respectful and supported.
- Compare to baseline with disclosed denominator, observation period, experiment design and uncertainty. Don't invent improvements or claim causality from an anecdote.
- Measure through user-task observation even before enough traffic for rigorous experiments. Validated **clarity** is not the same as measured **business lift**.

## Report format

```text
Revision/environment:
User task:
Verified sources/examples:
Rubric (0–100 if all domains assessed; otherwise PARTIAL):
Hard blockers:
PASS — exact tested behaviors + evidence links:
FAIL — observed failure, severity and reproduction:
PARTIAL — limited coverage:
BLOCKED — external dependency:
NOT TESTED — areas with no evidence:
Before/after copy/interaction changes:
Real user task outcomes:
Recommended next actions:
Owner sign-off / merge decision: pending
```

**Exit:** product owner can review a readable change list, real screenshots/recorded interactions and test run links; no unsupported "pixel-perfect" or "high-converting" claim. Leave merge to established repository authorization rules.
