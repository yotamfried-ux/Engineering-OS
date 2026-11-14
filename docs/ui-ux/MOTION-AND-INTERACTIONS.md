# Motion & interaction playbook — purpose before spectacle

Read [source atlas](SOURCE-ATLAS.md) and [screen copy](SCREEN-CONTENT-PLAYBOOK.md) first. **Motion is not a proxy for quality.** A premium interface often has fewer, better-coordinated effects. Separate **functional feedback** from **expressive brand moments**.

## Selection matrix

| Pattern | Purpose | Interaction / demonstration | Don't use when |
|---|---|---|---|
| Press/hover/focus | Confirm control is interactive and was activated | Slight press scale/elevation, focus ring, state change; [Motion for React gestures](https://motion.dev/docs/react-animation) | Hover is the sole affordance; keyboard/touch users can't see effect |
| Shared-element / container transition | Show continuity between list item and detail | Selected service card transforms into appointment details; [Fluent motion](https://fluent2.microsoft.design/motion) | It obscures task hierarchy or causes layout shift |
| Staggered list entry | Reveal grouped results in reading order | Short offset for appointment cards; [Motion stagger](https://motion.dev/docs/stagger) | Large/infinite lists, repeat navigation, delayed accessibility |
| Progress morph | Show a real state transition | `Checking availability → awaiting confirmation → confirmed`; not fake progress | Status is unknown or backend has not confirmed |
| Inline validation | Clarify corrective action at field | Label/error reveal next to failed input; announce accessibly | Every-keystroke shake/jump, punitive motion |
| Loading / skeleton | Establish expected structure while loading | Stable placeholder geometry; replace with content without layout jump | Skeleton pretends data loaded or obscures stalled request |
| Success confirmation | Give closure and receipt, not confetti overload | One restrained checkmark and complete next-step content | Critical/business workflows where celebration is inappropriate |
| Undo/restore | Support recoverable actions | Brief snackbar with **Undo**, keyboard-operable and accessible | A truly irreversible action lacks confirmation/recovery |
| Drag and drop | Make movement and target clear | Lift, move, settle, live destination feedback + keyboard alternative | Only pointer users can complete reorder |
| Scroll/section reveal | Direct attention to narrative | One visual transformation for product story; [GSAP](https://gsap.com/docs/v3/) | Scroll hijacking, reduced-motion preference, reading disrupted |
| Interactive art/character | Brand personality linked to task | State machine animation reacting to choices; [Rive docs](https://rive.app/docs/) | Decoration distracts or state is unintelligible without animation |
| Gesture/haptic | Reinforce touch interaction | Native, reversible action response, reduced-motion-aware where possible | Gesture has no visible button/menu alternative |
| Data change | Show relevant updates with provenance | Highlight changed row or value, timestamp, clear stale indicator | Real-time updates steal focus or reorder items unexpectedly |
| Permission disclosure | Explain impact before system prompt | Brief bottom sheet explaining why permission is useful **now** | Mandatory pre-permission nagging, misleading control |

### Motion budget (starting hypotheses, not standards)

- **Micro feedback:** generally quick enough to feel immediate; begin testing around **100–200 ms**.
- **Local container transitions:** begin around **180–300 ms** with natural easing; adjust for travel distance, platform and user tests.
- **Large expressive sequences:** optional, skippable and rare; never postpone the primary action for the reveal.
- **No arbitrary 100ms/300ms compliance rule:** choose per platform, task and hardware; test actual frame rate and clarity.
- Prefer transform and opacity when feasible, but ensure changes in visual order/position don't cause focus or accessibility conflicts.

## Interaction design contract (for every animation)

1. **Trigger:** click/tap/focus/scroll/state update; document exactly.
2. **Before → after state:** describe semantic transition independent of motion.
3. **Meaning:** What does the user learn? If nothing, omit or downgrade.
4. **Timing/easing:** measured hypothesis with speed rationale and testing criteria.
5. **Reduced motion:** alternative preserves functionality and meaning; no autoplay-dependent instruction.
6. **Input alternatives:** touch, keyboard, switch, screen reader, pointer; don't hide actions behind hover.
7. **Performance:** slow device, low battery, data loading, long lists; avoid main-thread blocking.
8. **Failure and interruption:** mid-animation navigation, back, cancellation, re-render, duplicate click.
9. **Completion evidence:** capture short video of representative animation and verify observed state change + user task success.

## Copy/paste implementation example — native CSS

The following is **illustrative**, not a production-ready booking component. The same semantics must work without animation.

```css
.booking-action {
  transition: transform 150ms ease-out, box-shadow 150ms ease-out;
}
.booking-action:hover { transform: translateY(-1px); }
.booking-action:active { transform: translateY(0) scale(.985); }
.booking-action:focus-visible { outline: 3px solid currentColor; outline-offset: 3px; }

/* The fallback retains focus indication, status text, and all functionality. */
@media (prefers-reduced-motion: reduce) {
  .booking-action { transition: none; }
  .booking-action:hover, .booking-action:active { transform: none; }
}
```

## Copy/paste example — React state-driven feedback

Adapt to the project's actual state machine. The backend must control when a booking is confirmed.

```tsx
import { motion, useReducedMotion } from "motion/react";

type BookingPhase = "idle" | "checking" | "confirmed" | "unavailable";

export function BookingStatus({ phase }: { phase: BookingPhase }) {
  const reduced = useReducedMotion();
  const messages: Record<BookingPhase, string> = {
    idle: "Choose a time to continue.",
    checking: "Checking if that time is still available…",
    confirmed: "Your appointment is confirmed.",
    unavailable: "That time is no longer available. Choose another.",
  };
  return (
    <motion.p
      role="status"
      aria-live="polite"
      aria-atomic="true"
      key={phase}
      initial={reduced ? false : { opacity: 0, y: 4 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: reduced ? 0 : 0.18 }}
    >
      {messages[phase]}
    </motion.p>
  );
}
```

**Important:** The illustration above assumes `phase === "confirmed"` is set only after authoritative server acknowledgement; this must be verified in the application's control flow. If a changing keyed live region causes repeated announcements with a given screen reader, use a stable live-region element and test it manually. Adjust code to the library version; don't silently install Motion in projects using another stack.

## Visual anti-pattern checklist

- One-click AI-style output: same purple gradient, glass cards, vague hero, giant animation library, generic iconography.
- Jarring scroll hijack, text reveal that prevents reading, excessively slow stagger, parallax on every section.
- Animation plays forever, flashes, auto-scrolls, shifts a selected item, hides focus or causes nausea.
- Interactions work only through hover or gestures without visible alternatives.
- Decorative confetti for sensitive actions (e.g. medical, financial, destructive).
- Progress percentages invented without measurable backend work; success animation before data is saved.
- Heavy Rive/GSAP bundle for effects that CSS can accomplish; check licensing and deployment constraints.
- Design chosen from a screenshot without watching the full real interaction or evaluating content/task outcome.

## Cross-platform adaptation

- **Native iOS:** prefer native gestures, transitions, dynamic type, haptics and reduced-motion accommodations; [Apple motion](https://developer.apple.com/design/human-interface-guidelines/motion).
- **Android:** match Material behavior and device adaptive constraints; [Material 3](https://m3.material.io/).
- **Windows/desktop:** pointer, focus, menus, compact datasets, window resizing and shortcut responses; [Fluent 2 motion](https://fluent2.microsoft.design/motion).
- **Web:** measure Core Web Vitals and interaction latency; verify `prefers-reduced-motion`, focus management and mobile scrolling.
- **Kiosk:** immediate visible feedback, clear timeouts and task completion; avoid idle animation distracting from legibility.
- **Voice/chat/email/SMS:** motion may be absent entirely. The "interaction design" is still pacing, sequencing, clear confirmation, and graceful recovery.

## Test acceptance

- [ ] Keyboard, touch and screen-reader users can finish all tasks without depending on animation.
- [ ] Reduced-motion mode preserves action clarity and no forced scroll movement.
- [ ] Time-based changes never contradict authoritative application state.
- [ ] Long data lists and low-end devices remain responsive.
- [ ] Screenshots/video show all relevant transitions and before/after states.
- [ ] At least one representative user successfully understands what each important animation means.
