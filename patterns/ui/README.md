# UI Patterns

> Pattern library for UI component architecture, design system integration, and UX-critical interaction patterns. See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring and lifecycle.
>
> **Scope:** Generic UI/UX patterns that apply regardless of framework — component composition, loading and error states, accessibility, and design token usage. For React/Next.js-specific implementation patterns (Server Components, optimistic updates, infinite scroll, form state), see [`../frontend/README.md`](../frontend/README.md).

## Overview

Patterns for building consistent, accessible, and maintainable user interfaces. The failure modes these patterns address: inconsistent visual language when components are built ad-hoc, inaccessible interfaces that exclude keyboard and screen reader users, confusing loading states that cause users to double-click or abandon, and empty/error states that leave users stranded with no path forward.

---

## Pattern: Compound Component

**Problem:** A complex UI component (tabs, accordion, dropdown, modal) needs to share internal state between its parts — but prop-drilling from a single parent component creates an inflexible, hard-to-customize API that forces specific markup structure.

**Solution:** Use the Compound Component pattern: the parent holds state in a React Context, and child components consume it. The user composes the components freely with any markup in between.

**Implementation Notes:**
- Expose the parent and child components as named exports from the same file, or under a namespace (`Tabs.Root`, `Tabs.List`, `Tabs.Panel`).
- The parent creates a Context with the shared state; children read from it via a custom hook that throws a useful error if used outside the parent.
- Accept a `defaultValue` prop for uncontrolled mode and an `onChange` + `value` pair for controlled mode.
- Never hardcode the number of children or their order — the pattern's value is layout flexibility.

**Example:**
```tsx
import { createContext, useContext, useState, ReactNode } from "react";

interface TabsContextValue {
  activeTab: string;
  setActiveTab: (id: string) => void;
}

const TabsContext = createContext<TabsContextValue | null>(null);

function useTabs() {
  const ctx = useContext(TabsContext);
  if (!ctx) throw new Error("Tabs components must be used inside <Tabs.Root>");
  return ctx;
}

function Root({ defaultValue, children }: { defaultValue: string; children: ReactNode }) {
  const [activeTab, setActiveTab] = useState(defaultValue);
  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      <div>{children}</div>
    </TabsContext.Provider>
  );
}

function List({ children }: { children: ReactNode }) {
  return <div role="tablist">{children}</div>;
}

function Tab({ id, children }: { id: string; children: ReactNode }) {
  const { activeTab, setActiveTab } = useTabs();
  return (
    <button
      role="tab"
      aria-selected={activeTab === id}
      onClick={() => setActiveTab(id)}
    >
      {children}
    </button>
  );
}

function Panel({ id, children }: { id: string; children: ReactNode }) {
  const { activeTab } = useTabs();
  if (activeTab !== id) return null;
  return <div role="tabpanel">{children}</div>;
}

export const Tabs = { Root, List, Tab, Panel };

// Usage — completely flexible markup:
// <Tabs.Root defaultValue="overview">
//   <Tabs.List>
//     <Tabs.Tab id="overview">Overview</Tabs.Tab>
//     <Tabs.Tab id="details">Details</Tabs.Tab>
//   </Tabs.List>
//   <Tabs.Panel id="overview">...</Tabs.Panel>
//   <Tabs.Panel id="details">...</Tabs.Panel>
// </Tabs.Root>
```

**Common Mistakes:**
- Putting all logic in one monolithic component with many boolean props — `showHeader`, `showFooter`, `collapsible` — instead of composing.
- Not providing a controlled mode — parent components can't synchronize tab state with routing.
- Forgetting `role="tab"`, `aria-selected`, and `role="tabpanel"` — required for keyboard navigation and screen readers.

**Security Considerations:**
- `id` props used as DOM `id` attributes must not come from untrusted user input to avoid DOM clobbering.

**Testing:**
Render the full compound in a test, click a Tab, and assert the corresponding Panel is visible and others are not. Test keyboard navigation: focus a Tab, press Arrow Right, assert the next Tab receives focus. Test the controlled mode: assert `onChange` fires with the correct id.

**Score:** Validated (see pattern-lifecycle.md)

---

## Pattern: Loading, Empty, and Error States (LEE Triad)

**Problem:** UI components handle data fetching but only design the "happy path" — loaded data. When data is loading, empty, or errored, the UI shows nothing, crashes, or confuses users.

**Solution:** Every data-driven component must handle all four states explicitly: loading, empty, error, and success. Codify this as a required structure, not an afterthought.

**Implementation Notes:**
- Use a discriminated union type for data state: `{ status: 'loading' | 'empty' | 'error' | 'success', data?, error? }`.
- **Loading:** Show a skeleton that matches the shape of the loaded content — not a spinner in the center. This reduces layout shift and sets accurate expectations.
- **Empty:** Show an actionable empty state — an illustration or icon, a message explaining why it's empty, and a primary CTA ("Create your first project"). Never just show a blank area.
- **Error:** Show the error message, an action to retry, and if possible a way to report the issue. Do not show raw error objects or stack traces.
- **Success:** Normal content.

**Example:**
```tsx
type DataState<T> =
  | { status: "loading" }
  | { status: "empty" }
  | { status: "error"; message: string }
  | { status: "success"; data: T };

function ProjectList({ state }: { state: DataState<Project[]> }) {
  if (state.status === "loading") return <ProjectListSkeleton />;
  if (state.status === "empty") return (
    <EmptyState
      icon={<FolderIcon />}
      title="No projects yet"
      description="Create your first project to get started."
      action={<Button>New project</Button>}
    />
  );
  if (state.status === "error") return (
    <ErrorState
      message={state.message}
      onRetry={() => refetch()}
    />
  );
  return <ul>{state.data.map((p) => <ProjectRow key={p.id} project={p} />)}</ul>;
}
```

**Common Mistakes:**
- Using `data?.length === 0` to detect empty after loading is complete — does not cover the case where the initial fetch has not resolved yet.
- Showing a full-page spinner instead of a skeleton — maximizes perceived latency and causes layout shift on load.
- Empty state with no CTA — leaves users stranded with no next action.

**Security Considerations:**
- Never render raw `error.message` from API responses in the UI without sanitization — server error messages can contain path information or stack details.

**Testing:**
Render the component with each of the four states. Assert: loading shows a skeleton (not the content); empty shows the CTA button; error shows the error message and the retry button; success renders the list items.

**Score:** Validated (see pattern-lifecycle.md)

---

## Pattern: Design Token Usage

**Problem:** Colors, spacing, typography, and border radii are hardcoded as literal values (`#1a1a2e`, `16px`, `font-size: 14px`) across components. When the design system changes, updating is a find-and-replace across hundreds of files, and components drift from the spec.

**Solution:** Define all visual primitives as design tokens (CSS custom properties or Tailwind theme values). Components reference only token names — never raw values.

**Implementation Notes:**
- Define tokens at three levels: **primitive** (raw values: `--color-blue-600: #2563eb`), **semantic** (intent: `--color-brand-primary: var(--color-blue-600)`), **component** (role: `--button-bg: var(--color-brand-primary)`).
- In Tailwind projects, define semantic tokens in `tailwind.config.ts` under `theme.extend.colors` referencing CSS variables. This enables both `bg-brand-primary` classes and `var(--color-brand-primary)` in arbitrary styles.
- Never use a primitive token directly in a component — always use a semantic or component token. This allows theming without changing component code.
- Dark mode: swap semantic tokens at `:root.dark {}` scope — components require no changes.

**Example:**
```css
/* tokens.css — primitive + semantic layers */
:root {
  /* Primitives */
  --color-blue-500: #3b82f6;
  --color-blue-600: #2563eb;
  --space-4: 1rem;
  --space-8: 2rem;
  --radius-md: 0.375rem;

  /* Semantics */
  --color-brand-primary: var(--color-blue-600);
  --color-brand-primary-hover: var(--color-blue-500);
  --space-component-padding: var(--space-4);
}

:root.dark {
  --color-brand-primary: var(--color-blue-500);
}
```

```tsx
// tailwind.config.ts
export default {
  theme: {
    extend: {
      colors: {
        brand: {
          primary: "var(--color-brand-primary)",
          "primary-hover": "var(--color-brand-primary-hover)",
        },
      },
    },
  },
};

// Component — uses only token names
function PrimaryButton({ children }: { children: React.ReactNode }) {
  return (
    <button className="bg-brand-primary hover:bg-brand-primary-hover rounded-md px-4 py-2 text-white">
      {children}
    </button>
  );
}
```

**Common Mistakes:**
- Defining tokens without the semantic layer — theming requires changing every component that uses a primitive.
- Using `text-blue-600` directly in component classes instead of a semantic Tailwind token — breaks when the brand color changes.
- Tokens defined in JS objects instead of CSS custom properties — cannot be overridden by media queries or parent selectors.

**Testing:**
Visual regression tests (Chromatic, Percy) with a snapshot per token set. Test that toggling `.dark` on the root element changes the rendered button color without any code change to the component.

**Score:** Validated (see pattern-lifecycle.md)

---

## Pattern: Accessible Interactive Components

**Problem:** Custom interactive components (modals, dropdowns, comboboxes, date pickers) are built with `div`s and mouse handlers. Keyboard users cannot use them, and screen reader users get no semantic information about the component's state or role.

**Solution:** For every custom interactive component, implement the corresponding [ARIA pattern](https://www.w3.org/WAI/ARIA/apg/patterns/). Use semantic HTML where possible. Prefer a tested accessible component library (Radix UI, Headless UI) over building from scratch.

**Implementation Notes:**
- **Before building a custom component:** check whether Radix UI or Headless UI provides it. They handle focus management, keyboard navigation, and ARIA automatically.
- **If building custom:** implement the W3C ARIA pattern exactly: the roles, the states (`aria-expanded`, `aria-selected`, `aria-disabled`), and the keyboard interactions (Arrow keys for navigation, Enter/Space for selection, Escape to close, Home/End for first/last).
- Focus trap in modals: when a modal opens, focus must move inside; Tab must cycle within the modal; Escape must close and return focus to the trigger.
- Announce dynamic content changes with `aria-live="polite"` for non-urgent updates (search results) and `aria-live="assertive"` for urgent alerts.

**Example — accessible modal focus trap:**
```tsx
"use client";
import { useEffect, useRef } from "react";

function Modal({ isOpen, onClose, children }: { isOpen: boolean; onClose: () => void; children: React.ReactNode }) {
  const modalRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!isOpen) return;

    // Move focus inside
    const firstFocusable = modalRef.current?.querySelector<HTMLElement>(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );
    firstFocusable?.focus();

    // Trap Tab key
    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape") { onClose(); return; }
      if (e.key !== "Tab") return;
      const focusable = [...(modalRef.current?.querySelectorAll<HTMLElement>(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
      ) ?? [])];
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
      else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
    }

    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div role="dialog" aria-modal="true" ref={modalRef} className="modal">
      {children}
      <button onClick={onClose} aria-label="Close modal">×</button>
    </div>
  );
}
```

**Common Mistakes:**
- `onClick` without an equivalent keyboard handler — keyboard users are blocked.
- `aria-label` on a generic `div` instead of giving it a meaningful `role` — screen readers announce the text but not what the element is.
- Not restoring focus to the trigger element after a modal closes — keyboard users lose their position in the page.

**Testing:**
Use `axe-core` (via `jest-axe` or Playwright accessibility) to run automated accessibility checks. For keyboard flows, use `userEvent.keyboard` in Testing Library: Tab into a modal, assert focus is trapped, press Escape, assert the modal closes and focus returns to the trigger.

**Score:** TBD (see pattern-lifecycle.md)

## Official References
- [W3C ARIA Authoring Practices Guide](https://www.w3.org/WAI/ARIA/apg/) — definitive keyboard and ARIA patterns
- [Radix UI Docs](https://www.radix-ui.com/docs/primitives/overview/introduction) — unstyled, accessible component primitives
- [Headless UI Docs](https://headlessui.com) — accessible components for Tailwind CSS
- [Tailwind CSS Docs](https://tailwindcss.com/docs/customizing-colors) — design token configuration
