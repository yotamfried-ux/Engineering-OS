# Product experience source atlas — official guidance + real-world examples

**Scope:** any product with a human-facing touchpoint: public website, SaaS, mobile app, desktop tool, kiosk, conversational assistant, email, SMS/push, service transaction, creator tool, game, and embedded/IoT UI.  
**Verified:** 2026-10-13 (public landing pages/docs; downstream pages, access tiers, licenses and API behavior can change).  
**Use with:** [Experience routing](EXPERIENCE-ROUTING.md), [Screen content](SCREEN-CONTENT-PLAYBOOK.md), [Motion](MOTION-AND-INTERACTIONS.md) and [Product qualification](PRODUCT-EXPERIENCE-QUALITY-GATE.md).

This is a **curated link index, not a copy of third-party documentation or screenshots**. Source tiers follow [SOURCE-POLICY](../../capability-registry/SOURCE-POLICY.md). A = primary vendor/standards guidance; B = established research or first-party maintained demos; C = inspiration/community showcases (NOT evidence that a pattern improves outcomes). Search at the **task/flow level** first, not just "beautiful landing page."

## A. Platform behavior, interaction, content, accessibility

| Need | Primary reference | When to use / concrete material to extract |
|---|---|---|
| iOS/iPadOS/macOS/visionOS interactions | [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/) (A) | Platform conventions for native controls, typography, navigation and adaptation. |
| Teaching product value | [Apple: Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding) (A) | Fast, optional, interactive first-run education rather than a mandatory slideshow. |
| Feedback/animation | [Apple: Motion](https://developer.apple.com/design/human-interface-guidelines/motion) (A) | Functional feedback; avoid gratuitous motion and provide alternatives. |
| Important interruptions | [Apple: Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts) (A) | When *not* to block the task with a modal; actionable critical alerts. |
| Android UI visual and motion system | [Material Design 3](https://m3.material.io/) and [Material motion](https://m3.material.io/styles/motion/overview/how-it-works) (A) | Android-native states, components, continuity, responsive behavior. Some docs require JavaScript. |
| Desktop/Windows UI | [Microsoft Windows design guidelines](https://learn.microsoft.com/en-us/windows/apps/design/guidelines-overview) (A) | Windows navigation, commands, layouts, windowing, writing and desktop controls. |
| Motion rationale & choreography | [Fluent 2 Motion](https://fluent2.microsoft.design/motion) (A) | Purpose, enter/exit, choreography, stagger, reduced motion. |
| Interface text | [Microsoft Writing style](https://learn.microsoft.com/en-us/windows/apps/design/style/writing-style) (A) | Buttons, dialogs, errors, tone, localization and concise action-led writing. |
| Writing across apps | [Atlassian content design](https://atlassian.design/get-started/content-design) (A) | Voice, tone, language, button/content guidance, date and time conventions. |
| Enterprise interface text | [IBM Carbon: content](https://www.carbondesignsystem.com/building-blocks/foundations/content) (A) | Content foundations, terminology, inclusive and accessible product copy. |
| Commerce/admin empty state | [Shopify Polaris component docs](https://shopify.dev/docs/api/polaris) (A) | Component guidance; look for empty-state composition and action-oriented CTAs. |
| Form field errors & validation | [GOV.UK error message](https://design-system.service.gov.uk/components/error-message/) (A) | Exact examples and copy for missing, malformed and other user-correctable inputs. |
| Transaction receipt & next steps | [GOV.UK confirmation page](https://design-system.service.gov.uk/patterns/confirmation-pages/) (A) | Confirmation, reference, what happens next, support, saved record. |
| Review before action | [GOV.UK check answers](https://design-system.service.gov.uk/patterns/check-answers/) (A) | Review/change each item before submission. |
| Complete service journeys | [GOV.UK patterns](https://design-system.service.gov.uk/patterns/) and [USWDS patterns](https://designsystem.digital.gov/patterns/) (A) | Capture details, multistep flows, errors, identification, trust. |
| Semantic interactive widgets | [W3C ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/patterns/) (A) | Keyboard/focus/ARIA patterns for comboboxes, dialogs, grids, date pickers, etc. |
| Accessibility acceptance criteria | [W3C WCAG 2.2](https://www.w3.org/TR/WCAG22/) (A) and [WAI tutorials](https://www.w3.org/WAI/tutorials/) (A) | Text contrast, reflow, labels, target sizing, focus, motion and accessible interaction. |
| Multimodal/chat interactions | [Microsoft conversational UX](https://learn.microsoft.com/en-us/azure/bot-service/bot-service-design-principles?view=azure-bot-service-4.0) (A, **legacy SDK context**) | Conversation planning, reduced back-and-forth, errors and handoff; check modern channel/platform docs separately before implementation. |

## B. Evidence and observed usability

| Source | Why it matters | Limits |
|---|---|---|
| [Nielsen Norman Group: Microcontent](https://www.nngroup.com/articles/microcontent-how-to-write-headlines-page-titles-and-subject-lines/) (B) | Titles, labels, subjects and short standalone text that communicate meaning. | Research/context must be interpreted for your audience. |
| [NN/g: Error-message guidelines](https://www.nngroup.com/articles/error-message-guidelines/) (B) | Recovery wording and appropriate error presentation. | Not a substitute for platform-specific patterns. |
| [NN/g: Onboarding tutorials vs contextual help](https://www.nngroup.com/articles/onboarding-tutorials/) (B) | Decide what to teach immediately vs when the user needs it. | Different user groups may prefer different supports. |
| [Baymard: Product page research](https://baymard.com/research/product-page) (B) | Real product-page screenshots and observed buying friction. | Some guidelines/research are paywalled; consumer commerce context. |
| [Baymard: Checkout UX guide](https://baymard.com/blog/checkout-flow-ux-optimization) (B) | Account entry, order review, cost transparency, checkout recoverability. | Test applicability to subscriptions/bookings. |
| [Baymard: Commerce UX research articles](https://baymard.com/research-articles) (B) | Research-backed inspiration by categories (search, product, checkout, account, mobile). | Not universally applicable to every product. |

## C. Visual references, recorded journeys, and interactive demos

| Gallery / official demo | Type | What to inspect, not blindly copy |
|---|---|---|
| [Mobbin](https://mobbin.com/) (C) | Shipped mobile/web **screens and flows** | Search by feature (booking/calendar, login, pricing, paywall, referrals, settings, empty state); compare 3+ products; access may require an account/payment. |
| [Page Flows](https://pageflows.com/) (C) | Recorded UX journeys | Study transition order, wording, permission timing, branching, not just hero screenshots; access may vary. |
| [SaaSFrame](https://www.saasframe.io/) (C) | SaaS marketing and product UI | Hero, pricing, settings, dashboard, account, onboarding; verify each current product. |
| [Awwwards](https://www.awwwards.com/) (C) | Editorial/experimental web motion | Distinctive art direction, scroll interactions and storytelling; **not** automatic evidence of accessibility/performance/conversion. |
| [SiteInspire](https://www.siteinspire.com/) (C) | Curated websites | Information hierarchy and art direction across industries. |
| [Lapa Ninja](https://www.lapa.ninja/) (C) | Landing pages | Hero headlines, offer, feature sequencing and proof; assess claims and accessibility. |
| [Really Good Emails](https://www.reallygoodemails.com/) (C) | Transactional/lifecycle email inspiration | Structure, subject/preheader ideas, confirmations, renewals, reactivation; don't reuse brands/copy. |
| [Hover.dev](https://www.hover.dev/) (C) | Animated React component demos | Hover/press/hover-card ideas and concrete implementations; check licensing, keyboard and reduced motion. |
| [React Bits](https://reactbits.dev/) (C) | Open-visual animated components | Text/entry/decoration patterns; review dependencies, responsiveness and accessibility. |
| [Motion for React](https://motion.dev/docs/react) (A vendor API) | Animation library API + examples | Gestures, layout, presence, scroll, transitions; read current docs before coding. |
| [GSAP documentation](https://gsap.com/docs/v3/) (A vendor API) | Timelines and custom motion | Complex choreography; inspect bundle/runtime/license. |
| [Rive documentation](https://rive.app/docs/) (A vendor API) | Interactive vector animations | State machines, interaction, runtime compatibility, motion alternatives. |
| [Adobe Spectrum motion](https://spectrum.adobe.com/page/motion/) (A) | Product motion guidelines | Function-first motion in creative tools and enterprise contexts. |

### Selection and extraction protocol (mandatory for AI agents)

1. **Name the task + audience + platform + conversion/success event** before searching: e.g., "first appointment booking, iPhone, first-time customer, booking confirmed".
2. Pull **two A-tier behavior/content references**, **one B-tier research source** (if appropriate) and **three contrasting C-tier examples**. If a paid resource is inaccessible, mark NOT INSPECTED; don't fabricate its screen.
3. Record for each example: product name and link, capture date, platform, journey start/end, explicit H1/subtitle/primary CTA, information architecture, validation/empty/error/loading/success behavior, notable interaction, and **why it helps this audience**.
4. Extract **principles and original proposals**. Do not clone another brand's illustration, layout 1:1, copyrighted text, photos, fonts or paid templates. Third-party galleries are discovery, not permission to redistribute their content.
5. Rate candidates for differentiation, clarity, task success, accessibility, performance and implementation cost. Show options and trade-offs; choose one visual direction intentionally.
6. Verify the **actual live implementation** on supported devices/assistive input; examples and library docs do not prove the finished product works.
7. Recheck material sources at implementation time. Track paywall/access status, broken link, site changes and upstream terms; don't present marketing promises as experimentally proven results.

### Search ideas by surface

- **Booking / service:** scheduling, availability, service card, staff selection, location, date/time, booking review, confirmation, reschedule, cancellation, reminder, no available slots.
- **Product-led SaaS:** role-based onboarding, checklist, first value, integration setup, permission, empty dashboard, upgrade, account, collaboration and billing.
- **Store / marketplace:** category, search/filter, product details, trust, basket, shipping, pricing, checkout, refund/support.
- **Creator or AI tool:** prompt composer, progress, streaming, drafts, undo, version history, provenance, export, regenerate, latency and partial failure.
- **Desktop / technical tool:** keyboard navigation, shortcuts, dense tables, bulk actions, undo, file-picker, multi-window, offline save and recovery.
- **Kiosk / public terminal:** touch target and reach, timeout, language, privacy, screen reader/physical access, session reset and printed/digital receipt.
- **Chat / voice:** greetings, supported intents, clarifications, confirmation, error recovery, escalation, transcript/privacy.
- **Lifecycle channel:** email, SMS, push, in-app messaging, permission timing, preview text, deep linking, opt-out, frequency.
- **Games / learning:** tutorials, first reward, progression, feedback, controls, settings, accessibility and return prompts.
