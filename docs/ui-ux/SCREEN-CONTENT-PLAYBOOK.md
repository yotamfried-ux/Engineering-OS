# Screen-content & conversion copy playbook

**Purpose:** prevent AI-generated products from shipping generic lorem-ipsum-esque headlines, vague buttons, empty dashboards, missing edge-case messages, manipulative marketing or inconsistent brand voice. Apply to **all user-facing channels**: websites, web/mobile/desktop apps, kiosks, games, assistants, emails, push, SMS, support/help and transactional service journeys.

**Read first:** [source atlas](SOURCE-ATLAS.md). Platform-specific behavior takes priority over generic advice. Examples below are *original, illustrative copy*, not assertions that the pictured feature exists.

## 1. Required context before writing a single label

For the project, produce a **content brief**:
- **Audience:** who the user is; language, context, motivation, fears, level of expertise, accessibility needs and whether they're a first-time/returning user.
- **Product promise:** "For [audience] trying to [job], [product] helps [outcome], unlike [alternative], because [credible differentiator]." If differentiator cannot be substantiated, keep it as a design hypothesis.
- **Primary journey and action:** what successful user behavior actually is; success must be observable, not "engagement" alone.
- **Proof inventory:** only verified facts (real pricing, real reviews with consent, policies, qualifications, timings, customer logos with authorization). Never invent testimonials, counts, timers or guarantees.
- **Voice/tone:** three observable adjectives with examples and anti-examples (e.g. calm, direct, encouraging; **not** "innovative game-changing solution").
- **Naming:** canonical nouns and verbs; consistent service labels and button terminology, with localization and RTL rules when relevant.
- **Constraints:** regulatory context, ages, locale, data consent, screen size, speed, access needs, offline and user permissions.

**AI guardrail:** Never produce "Your journey starts here", "Unlock your potential", "Elevate your experience", "Seamless solution", "Revolutionize [domain]", "Submit", "Learn more" or fake social proof as a default. Such copy needs evidence of user relevance and purpose.

## 2. Content spec for each screen / touchpoint

Each screen record must contain: `screen_id`, platform/channel, audience and entry condition, **user question**, one-sentence promise or utility, title, secondary explanatory line (if needed), primary CTA and precise result, secondary/escape action, inputs/outputs with labels & examples, trust/proof source, privacy and cost disclosure, empty/loading/error/success states, keyboard/touch/screen-reader behavior, motion intent, analytics events, and test conditions. When no CTA is appropriate (passive status display), record **none** explicitly.

A page is **not complete** because its sunny-day screenshot looks good. Write microcopy for *every* state and transition.

## 3. Screen and interaction catalog (selection, not a mandatory feature list)

| Surface / screen | User's actual question | Must-have content, features & states | CTA pattern and common failure |
|---|---|---|---|
| Marketing home / landing hero | "Is this for me; why care now?" | Specific audience + outcome + proof/credible differentiation; product preview; clear single primary conversion; supporting objections, pricing path, FAQ | `Book a 15-minute demo` instead of `Get started` if a demo is actually the action. Avoid generic stock SaaS gradients/copy. |
| Service / professional profile | "Why this provider, and can I trust them?" | Services, specialism, location, languages, verified experience/portfolio, availability, pricing, policies, authentic review provenance | `Choose this specialist`; do not fabricate qualifications or reviews. |
| Services/catalog | "What fits my need and budget?" | Plain names, duration, what is included/not included, total price and currency, useful comparisons, filters, bookable availability | `Choose 45-minute session`; no unexplained jargon. |
| Search, discovery & filter | "How do I narrow this down?" | Search scope, helpful hint, result count, applied filters, clear filters, sort explanation, no-results alternatives, loading | `Clear filters` for zero results, not `Try again` unless loading failed. |
| Pricing / plans | "What will I really pay and receive?" | Exact currency/billing cadence, taxes/fees when known, limitations, trial terms, cancellation policy, plan comparison, FAQs, real trust evidence | `Start 14-day trial` only if trial exists; avoid preselected expensive plans or hidden conditions. |
| Signup / login / recovery | "How can I start or return safely?" | Password/passkey/social paths supported, privacy note, validation, forgotten password, recovery, session state and consent | `Continue with email`; no forced account if task can reasonably be completed as guest. |
| Onboarding / role selection | "What should I do first?" | One immediate value step; permissions just in time; progress only if needed, skip/return paths, educational empty state | `Add my first appointment`; don't force lengthy slideshow/profile setup. |
| Dashboard / overview | "What's changed and what should I do?" | Relevant prioritized tasks, status freshness, context, data provenance, anomalies/alerts, direct next action, sparse meaningful default | `Review 2 pending bookings` *only with live count*. Avoid decorative vanity KPI cards. |
| Calendar / availability | "Which real slot can I choose?" | Timezone and locale, provider/location, available vs unavailable, loading, updated-at/hold/expiry if applicable, calendar keyboard behavior | `Choose 14:30` when slot confirmed as selectable; don't invent availability or imply a hold. |
| Booking / reservation details | "What am I booking?" | Service, provider, location/method, duration, date/time+timezone, full fee/deposit, reschedule/cancel terms, contact preference | `Continue to review`, not premature `Confirm` if not final. |
| Review / consent / irreversible action | "Am I about to make a commitment?" | Human-readable summary, edit actions, exact charge/commitment, explicit consent, receipt method | `Confirm appointment` or `Pay ₪120` only for actual action. Never bury terms. |
| Confirmation / receipt | "Did it work? What's next?" | Unambiguous final status from backend, reference/transaction ID if exists, details, next step, changes/cancellation path, receipt/calendar | `Add to calendar`; no success message until authoritative confirmation. |
| Empty-first-run state | "Why is there nothing here?" | State reason, benefit of first action, short instructions, one prominent CTA | `Create first service`, not `Nothing to show`. |
| Empty-filter/no results | "Why didn't I find anything?" | Applied filters/search query, zero-result explanation, reset path, related alternatives | `Show all dates` rather than invented inventory. |
| Loading / async / long-running job | "Is it working; will my work be lost?" | Honest stage/progress (not fabricated %), elapsed/next step if known, cancel/retry/back, background continuation and notification | `Keep working` / `View upload status`; distinguish uploading vs processing. |
| Error / partial failure | "What failed and how do I recover?" | Specific impact, what is preserved, correctable action, retry or escalation, accessible presentation; trace ID if useful | `Retry upload` / `Choose another time` not `Oops!` or raw stack traces. |
| Payment / checkout | "Can I finish safely, without surprises?" | Total and tax/fees, accepted methods, security/privacy explanation, status, editable order summary, retries, refund policy | `Pay ₪120` if verified; avoid double submissions and unclear failures. |
| Profile / settings / permission | "What will change if I choose this?" | Clear current value and consequences; privacy/delete/export settings; accessible toggles, save feedback | `Save notification preferences`; don't use manipulative opt-out wording. |
| Collaboration / invites | "Who can see or change this?" | Roles/permissions, invite expiry, accepted/pending states, revoke access and accountability | `Invite as editor`; don't share hidden permissions. |
| Notifications / inbox | "What's important and is action needed?" | Event significance, actor/source, timestamp/timezone, deep link, deduplication/frequency, preferences | `Review request`; avoid actionless "Something happened" messages. |
| AI assistant / generation | "What can it do; what is reliable?" | Sample intents, scope and limits, in-progress state, provenance when needed, review/undo, handoff, error and privacy | `Review draft` before publishing; don't present speculative outputs as confirmed. |
| Help / contact / escalation | "How can I resolve this?" | Searchable FAQ, support channel, hours/SLAs if verified, ticket status, retry without repeating context, human escalation | `Contact support` / `View request`. |
| Cancellation / refund / deletion | "What do I lose, and can I undo it?" | Effect, deadline, fee/refund policy, irreversible warning if true, data retention, receipt, alternatives offered neutrally | `Cancel booking` vs `Keep booking`; no guilt traps. |
| Offline / unavailable / maintenance | "What is accessible right now?" | Last synced info, what works offline, unsynced changes, retry and conflict handling, honest expected restoration if known | `Try syncing again`; never claim "saved" if only queued locally. |
| Kiosk / public touch-screen | "Can I complete this securely and privately?" | Language, clear large touch controls, timeouts/warnings, privacy between users, accessible alternatives, receipt/exit | `Finish and clear my session`; auto-reset and hide prior PII. |
| Email transactional | "What happened, and do I need to act?" | Specific subject and preheader, essential details high in body, primary deep link, help, footer, sender identity | `Manage appointment`; no decorative-only email. |
| SMS / push / in-app message | "Why did I receive this, what next?" | Product identity, relevant fact, time, deep link only if valid, consent/preferences, minimal sensitive details on lock screen | `Appointment tomorrow at 14:30` with real data; no false urgency or sensitive public preview. |
| Voice/chat interaction | "Can I say what I need naturally?" | Supported intents, examples, clarification, confirmation before irreversible action, repair prompts, escalation and exit | `I found two times. Which one works?`; don't claim human identity or capabilities. |
| Games / educational flow | "How do I act and know I improved?" | Contextual first-task, controls, progress and rewards, feedback, accessible pause/settings, recoverable failure | Short contextual action prompts instead of textbook tutorials. |

## 4. Rewrite examples — generic AI product to task-oriented writing

All examples below are original. Replace placeholders with verified project values; do not imply that a service or slot exists.

| Surface | Generic / weak | Contextual, clear and useful |
|---|---|---|
| Booking landing | "Welcome to our innovative platform" | "Choose a service and find a time that works for you." |
| Booking CTA | "Get Started" | "See available appointments" |
| Booking form | "Enter Details" | "Where should we send your booking confirmation?" |
| Search empty | "No data found" | "No appointments match these filters. Try another day or clear your filters." |
| First-run dashboard | "Nothing here yet" | "Your schedule starts here. Add a service so customers can book it." |
| Save button | "Submit" | "Save opening hours" |
| Async pending | "Success!" after click | "We're checking this time. Your booking isn't confirmed yet." |
| Backend-confirmed success | "Operation completed" | "Your appointment is confirmed for [verified date and time]. You can change it from My bookings." |
| Slot collision | "Error 409" | "Someone just booked that time. Choose another available slot." |
| Checkout | "Continue" | "Review booking and total" before commitment; "Pay [verified amount]" for actual charge. |
| Consent | "By continuing you accept..." hidden | "Send me appointment reminders" as an optional, clearly explained setting. |
| AI assistant failure | "AI response failed" | "I couldn't finish the summary. Your original file is safe. Try again or open the source." |

### Localized/RTL sample (Hebrew appointment-booking system)

- **Hero title:** `תור שמתאים ליום שלך`
- **Hero supporting line:** `בוחרים שירות, בודקים שעות פנויות ומקבלים אישור במקום אחד.`
- **CTA:** `לצפייה בתורים הפנויים`
- **Selection heading:** `איזה טיפול תרצו לקבוע?` with exact service duration and verified price.
- **Date heading:** `מתי נוח לכם להגיע?` followed by localized calendar/timezone.
- **Review heading:** `לפני שמאשרים — אלה פרטי התור` with date/time/provider/address/total/terms.
- **Pending:** `בודקים שהתור עדיין פנוי…`; no invented commitment.
- **Success (only after server acknowledgement):** `התור נקבע!` and dynamic verified details + `הוספה ליומן` + `שינוי או ביטול תור`.
- **Conflict:** `השעה שבחרתם כבר נתפסה. בחרו שעה אחרת.`
- **No times:** `לא מצאנו תורים פנויים ביום שבחרתם.` + `הצגת ימים נוספים`.
- **Reminder subject:** `תזכורת לתור שלך ב-[תאריך]` with verified details, calendar link and opt-out per channel requirements.

Choose a tone appropriate to the actual business; calm healthcare UX, playful hobby booking, and premium hospitality should **not** sound the same. This sample is not mandatory wording.

## 5. Brand differentiation without fake design sophistication

Before visuals, make a small **creative direction board** with 3 contrastive concepts and one chosen direction:
1. **Positioning:** one audience insight + one differentiator backed by product reality.
2. **Voice:** chosen 3 adjectives; dictionary of preferred verbs and banned buzzwords.
3. **Visual grammar:** deliberate typography, shape, spacing, illustration/photo strategy, real content density; own hierarchy rather than default purple-gradient + glass cards.
4. **Interaction personality:** meaningful transitions, state feedback and a single memorable signature moment on a key user journey, not everywhere.
5. **Trust:** total price, authentic policies, evidence, accessible error recovery and stable performance.
6. **Locality:** localized idiom, formats, plural/gender choices, RTL mirroring where appropriate; avoid translating English CTA metaphors literally.

For every directional concept describe **what to omit** and **why it fits users**, not just what looks impressive. Distinctiveness is subordinate to accessibility and task success.

## 6. Ethical conversion/content guidelines

- Use **true** claims and proofs, verifiable testimonials with consent, transparent plans, genuine availability and real scarcity only.
- Don't coerce with pre-checked add-ons, guilt-filled unsubscribe language, obstruction, false urgency, hidden fees or disguised advertising.
- Track funnel completion **and** guardrails: successful task completion, trust/complaints, errors, support contacts, accessibility defects, refund/cancel anomalies.
- A/B tests need pre-defined hypothesis, success metric, guardrails, sample/power plan and stopping rules. A simple `p < 0.05` alone is NOT proof that a variant is better. If no meaningful traffic, use moderated task tests instead.
- There is no universal "3-click rule", "5–7 navigation items" rule or compulsory "all content above the fold" for every context: prioritize user findability and comprehension; test representative journeys.
- Copy is part of the **state machine**: never label a queued request "confirmed", a sync attempt "saved", or estimated pricing "final".

## 7. Definition of done — content

- [ ] Every journey step has a real, user-centered headline/action; no filler or placeholders remain.
- [ ] Every interactive action explains what will happen; destructive actions are unambiguous.
- [ ] Every screen defines loading/empty/error/success, even if a state is not visible in happy-path mocks.
- [ ] Dates, timezone, currency, fees, policies, trust evidence and status originate from authoritative project data.
- [ ] Copy works in the product's real locales, including RTL, screen readers and narrow/mobile layouts.
- [ ] Messaging across in-app/email/SMS/push is consistent, consensual, privacy-aware and actionable.
- [ ] Copy reviewed against the actual user task and at least one representative test, not solely AI preference.
