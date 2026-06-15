# UI/UX Library

## Overview

This library is the authoritative reference for UX patterns and UI implementation decisions in this engineering system. It covers both the *thinking layer* (user flows, information architecture, accessibility requirements, conversion principles) and the *building layer* (component libraries, forms, data grids, navigation, responsive patterns). Consult it before designing any user-facing surface — whether a web app, mobile screen, dashboard, or onboarding sequence.

---

## UX Patterns

### User Flows

A user flow is a sequence of steps a person takes to complete a goal. Document flows as a directed graph before writing any code.

- Start from a **trigger** (entry point: link, notification, direct URL) not from the home screen.
- Map every **decision branch**: success path, error path, empty state, and unauthenticated redirect.
- Annotate each step with the **data required** — if you need data that hasn't been collected yet, the flow has a gap.
- Keep the critical path (most common case) visually distinct from edge-case branches.
- Validate flows with at least one real user before building — a 15-minute hallway test catches structural problems cheaply.

**Key rule:** If a user needs more than 3 clicks to reach the core value of the product, the flow is too deep. Flatten it.

### Journey Mapping

Journey maps document the full experience across time and touchpoints, including emotion and context — not just screen interactions.

- Include pre-product touchpoints (search engine, referral link, word of mouth).
- Identify **moments of delight** (unexpected positive surprises) and **friction points** (where users hesitate or drop off).
- Map the emotional arc: awareness → consideration → first use → habit → advocacy.
- Use real data (Hotjar, Mixpanel funnels, session recordings) to validate where the map diverges from reality.
- Revisit the journey map when adding major features — new surfaces change the whole arc.

### Information Architecture

Information architecture (IA) is the structure of content and how users navigate through it.

- Group content by **user mental model**, not by internal team ownership or database schema.
- Use **card sorting** (open or closed) to discover how users categorize your content before fixing the nav structure.
- Limit top-level navigation items to 5–7. Beyond that, users cannot hold them in working memory.
- Breadcrumbs are mandatory for anything deeper than 2 levels.
- Use **progressive disclosure**: show the minimal set of options first, reveal advanced settings on demand. Every additional field or option visible by default increases cognitive load.
- Search becomes necessary when content exceeds ~200 items or when users arrive knowing what they want but not where it is.

### Onboarding

Onboarding is the bridge between signing up and experiencing first value. Poor onboarding is the primary driver of early churn.

- Define the **Aha Moment** — the specific action or result where a user first understands the product's value. Design onboarding to reach it as fast as possible.
- Defer non-essential setup (profile photo, integrations, notifications) until after the Aha Moment.
- Use **progressive onboarding**: teach features in context when the user first encounters them, not in an upfront tour.
- Show a **progress indicator** for multi-step setup (e.g., "Step 2 of 4") — it reduces abandonment.
- Checklist-style onboarding (with completion percentage) drives return visits and activation better than linear tours.
- Never require users to read documentation to understand your product.
- Provide **sample data** or a demo mode so users can explore without needing to import their own data first.

### Empty States

An empty state is any screen or section that has no content yet. It is one of the highest-leverage design moments in the product.

- Every empty state must answer three questions: **Why is it empty? What can the user do here? How do they get started?**
- Include a **primary CTA** that directly creates the first piece of content (not a link to documentation).
- Use illustrations sparingly — they should reinforce the message, not distract from the CTA.
- Distinguish between: first-run empty (user hasn't done anything yet), filtered-empty (search/filter returned no results), and error-empty (data failed to load). Each needs a different response.
- For filtered-empty: show what filter is active and offer a one-click way to clear it.
- For error-empty: show a human-readable error message and a retry button. Never show a raw error code to the user.

### Error States

Errors are inevitable. How they are communicated determines whether a user recovers or abandons.

- **Be specific:** "Invalid email" is better than "An error occurred." "Password must be at least 8 characters" is better than "Password is invalid."
- **Be constructive:** every error message must include a resolution path or next step.
- **Place errors in context:** inline field validation errors belong next to the field, not in a banner at the top of the page.
- **Distinguish severity:** informational (blue), warning (yellow), error (red), success (green). Use color consistently and never rely on color alone (use icons + text for accessibility).
- **HTTP errors with user-facing screens:**
  - 404: Offer search and top navigation links. Do not just show the code.
  - 500/503: Acknowledge the problem is on your side, not the user's. Provide a status page link.
- **Form submission errors:** Re-populate the form with the user's input. Never reset a form after a failed submission.
- Log all errors server-side for debugging. Surface a correlation ID to users so support can trace the issue.

### Accessibility (WCAG 2.1 AA)

WCAG 2.1 AA is the baseline legal and ethical standard. These are the non-negotiables:

- **Color contrast:** text on background must meet 4.5:1 ratio (AA). Large text (18pt+ or 14pt bold) requires 3:1. Use a contrast checker (e.g., https://webaim.org/resources/contrastchecker/) before finalizing brand colors.
- **Keyboard navigation:** every interactive element must be reachable and operable with keyboard alone. Tab order must follow visual reading order. Modals must trap focus while open and restore focus when closed.
- **Screen reader support:** all images need `alt` text. Decorative images use `alt=""`. Interactive elements need visible labels (prefer `<label>` over `aria-label`). Use semantic HTML elements (`<button>`, `<nav>`, `<main>`, `<h1>`–`<h6>`) before reaching for `role=`.
- **Focus visibility:** never use `outline: none` without a replacement focus indicator. The default browser outline is not beautiful but it is functional — replace it with a visible custom style, not nothing.
- **Motion:** respect `prefers-reduced-motion`. Animations that auto-play for more than 5 seconds must have pause controls. Never use content that flashes more than 3 times per second (seizure risk).
- **Target size:** interactive touch targets must be at least 44×44 CSS pixels (Apple HIG) / 48×48dp (Material). This matters most on mobile but applies to desktop too.
- **Forms:** each input has an associated `<label>`. Error messages are linked to their field with `aria-describedby`. Required fields are marked programmatically (`required`), not just with a red asterisk.
- **Testing:** run axe DevTools or Lighthouse accessibility audit on every new page before shipping. Manual keyboard-only navigation test on every interactive flow.

### Conversion Optimization

Conversion optimization is the practice of increasing the percentage of users who complete a desired action.

- **Reduce friction on the critical path:** every extra field in a signup form costs conversions. Every additional confirmation dialog before checkout reduces completions. Audit what is truly required.
- **Social proof:** testimonials, user counts, logos of known customers, and review scores increase trust at decision points. Place them near the CTA, not at the bottom of the page.
- **Urgency and scarcity:** genuine time limits or limited availability (e.g., "3 seats left") increase conversion. Fake urgency destroys trust permanently when users notice.
- **A/B test one variable at a time:** change one thing per experiment, run until statistical significance (p < 0.05, minimum 95% confidence), then apply the winner before testing the next variable.
- **CTA copy:** action verbs outperform generic labels. "Start your free trial" outperforms "Submit." "Get my dashboard" outperforms "Sign up."
- **Above the fold:** the primary value proposition and CTA should be visible without scrolling on the most common device width. Do not assume users scroll.
- **Loading speed is a conversion variable:** every additional second of page load reduces conversion rates. Target < 2.5 s LCP (Largest Contentful Paint) on mobile on a 4G connection.

---

## UI Patterns

### Design Systems

A design system is a shared library of components, tokens (color, spacing, typography), and guidelines that ensures visual and behavioral consistency across an entire product.

- Prefer adopting an established system (Shadcn/UI, MUI, Ant Design) over building one from scratch unless the product has genuinely unique design requirements.
- Design tokens (CSS variables or JS theme objects) must be the single source of truth for color, spacing, and type scale. Never hard-code hex values in components.
- Document component usage: what it is for, when not to use it, and its accessible behavior. A component without documentation gets misused.
- Establish a versioning and deprecation policy before the system grows large.

### Component Libraries

When evaluating or using component libraries:

- Confirm that all interactive components (buttons, inputs, modals, tooltips) have correct ARIA roles and keyboard behavior before adopting.
- Understand how the library handles theming — CSS-in-JS, CSS variables, or CSS Modules — and ensure it is compatible with your build system.
- Check bundle size impact. UI libraries are common sources of bloat; use tree-shaking and check what actually lands in production.
- For Radix UI primitives (the basis of Shadcn/UI): they are unstyled, fully accessible, and composable — good for custom design systems.

### Forms

Forms are the primary mechanism through which users input data. Poor forms are the most common source of abandonment.

- **Label every field.** Placeholder text is not a label — it disappears on input and fails accessibility requirements.
- **Validate on blur, not on every keystroke.** Real-time validation while typing is disruptive; validate when the user leaves the field.
- **Show errors inline and immediately** after submit. Do not make users scroll to find which field is invalid.
- **Mark required fields explicitly.** Convention: asterisk (*) + a legend explaining it. Better: mark optional fields instead if most fields are required.
- **Use the correct input type:** `type="email"` triggers the right mobile keyboard. `type="tel"` for phone numbers. `type="number"` for numeric values. `type="date"` for dates (with a custom picker fallback for cross-browser consistency).
- **Group related fields** visually with fieldsets or section dividers. Address fields belong together. Date ranges belong together.
- **Multi-step forms** (wizards): show progress, allow backward navigation without losing data, validate each step before advancing.
- See [patterns/frontend/README.md](../../patterns/frontend/README.md) for the React Hook Form + Zod implementation pattern.

### Tables & Data Grids

Tables display structured datasets. Data grids add sorting, filtering, pagination, and inline editing.

- Use tables only for truly tabular data (multiple attributes per row). Do not use a table to display a list of items with one attribute.
- **Columns:** right-align numbers, left-align text, center icons. Use consistent decimal precision within a column.
- **Sorting:** clicking a column header sorts by that column. Clicking again reverses the direction. Indicate current sort with an arrow icon.
- **Pagination vs. infinite scroll:** pagination is better for tasks where users need to return to a known position (e.g., admin lists). Infinite scroll works for feeds where the absolute position does not matter.
- **Row actions:** use a `...` overflow menu for actions that apply to a single row. Use bulk-select checkboxes for multi-row operations.
- **Empty state:** a table with no rows must show an empty state, not just column headers over blank space.
- **Sticky headers:** on tables taller than the viewport, freeze the header row so users always know which column they are reading.
- **Responsive:** on mobile, tables with many columns either collapse to a card layout per row, hide less important columns, or allow horizontal scroll. Choose based on the relative importance of the columns.
- For large datasets (10 000+ rows): use virtual scrolling to avoid rendering all rows in the DOM. See [patterns/frontend/README.md](../../patterns/frontend/README.md) for the virtual list pattern.

### Dashboards

Dashboards surface aggregated data so users can monitor status and make decisions.

- Lead with the most important metric. Do not present 20 equal-weight numbers — prioritize.
- Use **progressive levels of detail:** summary number → trend chart → breakdown table. Let users drill down rather than showing everything at once.
- Always show **time ranges** and let users adjust them. "Active users: 1 234" is meaningless without a period.
- **Charts:** use line charts for trends over time, bar charts for category comparison, pie/donut charts only when the parts-of-a-whole relationship is the primary message (and only with ≤5 segments).
- **Loading states:** each widget should have an independent loading skeleton so partial data appears fast. Do not block the whole dashboard on the slowest query.
- **Refresh behavior:** auto-refresh dashboards should indicate the last-updated timestamp and allow manual refresh. Auto-refreshing every few seconds while the user is editing a filter is disruptive.
- Avoid dark patterns: do not cherry-pick metrics that make numbers look better than they are. Include context (comparison to prior period, target lines).

### Navigation Patterns

Navigation is the skeleton of the information architecture made visible.

- **Top navigation bar:** best for sites with 4–7 primary sections. Horizontal space is limited — do not add items to avoid reorganizing content.
- **Side navigation (sidebar):** best for applications with many sections and sub-sections. Can show hierarchy. Collapsible on mobile.
- **Tab navigation:** best for switching between views of the same content (e.g., "Overview / Members / Settings" for a project). Do not use tabs for top-level navigation.
- **Breadcrumbs:** mandatory for content more than 2 levels deep. Place above the page title. Clickable links for all ancestor levels.
- **Mobile navigation:** hamburger menu (off-canvas sidebar) or bottom tab bar. Bottom tabs are preferred for apps because the thumb reaches the bottom of a phone screen more naturally than the top.
- **Active state:** the current page's navigation item must be visually distinct. Never make users guess where they are.
- **Destructive actions** (delete, archive, leave team) must be separated from non-destructive navigation and require confirmation.

### Responsive Design

Responsive design ensures the interface functions correctly at any viewport width.

- **Breakpoints (Tailwind defaults, used throughout this system):**
  - `sm`: 640px — large phones landscape
  - `md`: 768px — tablets
  - `lg`: 1024px — small laptops
  - `xl`: 1280px — desktops
  - `2xl`: 1536px — large monitors
- Design and test at the breakpoints, not just the extremes.
- Use `min-width` media queries (mobile-first) rather than `max-width` (desktop-first). It is easier to progressively enhance than to progressively strip.
- Avoid fixed pixel widths for containers. Use `max-w-*` with `w-full` so layouts breathe at all sizes.
- Images: always set `width` and `height` attributes (or use `aspect-ratio` in CSS) to prevent cumulative layout shift (CLS). Use `srcset` or Next.js `<Image>` for responsive images.
- Test on real devices, not just resized browser windows. iOS Safari and Chrome Android have quirks the desktop browser does not reproduce.

### Mobile First

Mobile-first means designing the smallest screen experience first, then scaling up — not shrinking a desktop design to fit a phone.

- On mobile: one primary action per screen. Navigation is hidden by default. Content takes full width.
- Touch targets: 44×44 px minimum. Sufficient spacing between adjacent targets (8px minimum) to prevent mis-taps.
- Avoid hover-dependent interactions on mobile — hover does not exist on touch screens.
- Use native inputs where possible: `<select>`, `<input type="date">`, number pickers. Native controls are accessible and familiar.
- Optimize for thumb reach: primary actions in the bottom half of the screen. Destructive actions in corners or behind a confirmation step.
- Network conditions on mobile may be slow (3G). Keep initial page payloads under 200 KB compressed. Lazy-load images and below-the-fold content.

---

## Design Frameworks & Systems

### Shadcn/UI

A collection of copy-paste React components built on top of Radix UI primitives and styled with Tailwind CSS. Components are added directly to the project codebase (not installed as a black-box dependency), so they are fully customizable.

**Best for:** Next.js / React projects that use Tailwind CSS and want accessible, unstyled-at-the-primitive-level components with full design control. Ideal when you need a custom look without building accessibility from scratch.

**URL:** https://ui.shadcn.com

### Tailwind UI

A premium library of professionally designed HTML/CSS/JSX component examples built exclusively with Tailwind CSS. Provides copy-paste templates for marketing pages, application UI, and e-commerce.

**Best for:** teams that already use Tailwind CSS and need production-quality layouts and components quickly. Particularly strong for marketing sites, landing pages, and admin UIs.

**URL:** https://tailwindui.com

### Material Design (MUI)

Google's open-source design system implemented for React as MUI (formerly Material-UI). Provides a complete component library with a strongly opinionated visual style, theming via a JS theme object, and built-in accessibility.

**Best for:** internal tools, admin panels, data-heavy applications, or teams that want a complete ready-to-ship component library with minimal visual customization. Strong TypeScript support and a large ecosystem of additional packages.

**URL:** https://mui.com | Design spec: https://m3.material.io

### Ant Design

A comprehensive React UI library from Ant Group, heavily used in enterprise and data-heavy applications. Provides a very wide range of components including complex ones (date pickers, tree selects, data tables, charts via Ant Design Charts).

**Best for:** enterprise internal tools, back-office applications, and complex data management interfaces. Strong internationalization (i18n) support. Less suitable when you need a custom visual brand, as overriding Ant Design's aesthetic requires significant effort.

**URL:** https://ant.design

### Human Interface Guidelines (Apple)

Apple's official design guidelines for iOS, iPadOS, macOS, watchOS, and tvOS. The authoritative reference for native look, feel, and behavior expectations on Apple platforms.

**Best for:** React Native / Expo apps that need to align with platform conventions on iOS. Even if using cross-platform components, understanding HIG ensures iOS users feel at home: navigation patterns, tab bars, sheets, alerts, and haptic feedback all have prescribed behaviors.

**URL:** https://developer.apple.com/design/human-interface-guidelines

---

## Reference Resources

- [Nielsen Norman Group Articles](https://www.nngroup.com/articles/) — Research-backed UX guidelines; canonical source for usability best practices
- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/) — Full W3C accessibility success criteria with techniques
- [Refactoring UI (Book)](https://www.refactoringui.com) — Practical visual design guidance written for developers by the creators of Tailwind CSS
- [Laws of UX](https://lawsofux.com) — Summary of cognitive psychology principles applied to interface design (Fitts's Law, Hick's Law, Miller's Law, etc.)
- [Radix UI Primitives](https://www.radix-ui.com/primitives) — Unstyled, accessible component primitives; used by Shadcn/UI
- [Storybook](https://storybook.js.org) — Industry-standard tool for developing and documenting UI components in isolation
- [Figma](https://www.figma.com) — Collaborative design tool; integrate with the Figma MCP server in this system for design-to-code workflows
- [Lucide Icons](https://lucide.dev) — Open-source icon set; used by Shadcn/UI; consistent stroke-based icon style
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/) — Fast WCAG contrast ratio validation tool

---

## Related Patterns

- [frontend patterns](../../patterns/frontend/README.md)
- [mobile patterns](../../patterns/mobile/README.md)
- [ui patterns](../../patterns/ui/README.md)
