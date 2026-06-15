# UI/UX Patterns
> See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring.

## Overview

Patterns in this directory cover the **visual design system and component architecture layer**: design tokens, component hierarchy, accessibility, data display, theming, form semantics, and dashboard layout. Apply them when building or extending a design system, a component library, or any user-facing UI regardless of framework.

For React/Next.js-specific concerns (App Router, Server vs Client Components, optimistic updates, virtualised lists), see [`patterns/frontend/README.md`](../frontend/README.md). A rough boundary: if the question is "how does data get to the component?" that belongs in `frontend/`; if the question is "how does the component look, behave, and communicate meaning?" it belongs here.

---

## Pattern: Design Tokens

**Problem:** UI teams duplicate color, spacing, and typography values across components; a single brand update requires changing hundreds of files.

**Solution:** Define all design decisions as named tokens in a single source of truth (a JSON token file). Components reference token names, never raw values. The token layer sits between brand values and component styles, structured in three tiers: primitive -> semantic -> component.

**Implementation Notes:**
- Three-tier architecture: primitive tokens hold raw values (`blue-600: #2563eb`); semantic tokens map intent to primitives (`color.primary.default -> blue-600`); component tokens scope tokens to a surface (`button.background -> color.primary.default`). Components consume only semantic or component tokens; never primitives directly.
- Use Style Dictionary (or an equivalent build tool) to compile the single JSON source into CSS custom properties, a Tailwind `extend` config, and TypeScript constants simultaneously.
- Name tokens by intent, not appearance: `color.feedback.error`, not `color.red.500`. This is what enables theming — the name stays stable while the value changes.
- Cover all decision categories: color, typography (family, size, weight, line-height), spacing (4 px base-unit scale: 4, 8, 12, 16, 24, 32, 48, 64), border-radius, shadow elevation, and z-index.
- Commit generated output (CSS variables, TypeScript constants) alongside the source JSON so CI can detect drift.

**Example:**
```json
// tokens/base.json — primitive values
{
  "color": {
    "blue": { "600": { "value": "#2563eb" }, "700": { "value": "#1d4ed8" } },
    "red":  { "600": { "value": "#dc2626" } },
    "gray": { "900": { "value": "#111827" }, "50": { "value": "#f9fafb" } }
  },
  "space": {
    "1": { "value": "4px" }, "2": { "value": "8px" },
    "4": { "value": "16px" }, "6": { "value": "24px" }
  }
}
```

```json
// tokens/semantic.json — intent layer
{
  "color": {
    "primary":  { "default": { "value": "{color.blue.600}" } },
    "feedback": { "error":   { "value": "{color.red.600}" }  },
    "surface":  { "default": { "value": "{color.gray.50}" }  },
    "text":     { "default": { "value": "{color.gray.900}" } }
  }
}
```

```javascript
// style-dictionary.config.js
const StyleDictionary = require('style-dictionary');

module.exports = {
  source: ['tokens/base.json', 'tokens/semantic.json', 'tokens/component.json'],
  platforms: {
    css: {
      transformGroup: 'css',
      prefix: 'ds',
      buildPath: 'dist/',
      files: [{ destination: 'tokens.css', format: 'css/variables' }],
    },
    ts: {
      transformGroup: 'js',
      buildPath: 'dist/',
      files: [{ destination: 'tokens.ts', format: 'javascript/es6' }],
    },
  },
};
// Output: :root { --ds-color-primary-default: #2563eb; }
// Output: export const ColorPrimaryDefault = '#2563eb';
```

```javascript
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        primary: 'var(--ds-color-primary-default)',
        error:   'var(--ds-color-feedback-error)',
      },
    },
  },
};
```

**Common Mistakes:**
- Naming tokens by appearance (`blue`, `large`) rather than intent (`primary`, `heading-lg`) — the name must survive a rebrand without confusion.
- Skipping the semantic layer and having components reference primitives directly — dark mode requires touching every component.
- Not generating TypeScript types from tokens — loses autocomplete and allows typos to reach production silently.
- Treating the generated output as the source of truth — always regenerate; never hand-edit generated files.

**Security Considerations:** None unique to design tokens beyond standard Content Security Policy for inline styles. If tokens are loaded at runtime from an external config (white-label), validate and sanitize before injecting (see Theming pattern).

**Testing:** Run a generated-output snapshot test on every PR that touches `tokens/`. Assert that every CSS variable name in `dist/tokens.css` corresponds to an entry in the source JSON. Catch any primitive reference leaking into a component with a lint rule that bans raw hex literals in component files.

**Score:** Candidate

---

## Pattern: Component Architecture (Atomic Design)

**Problem:** UI components organized by file type (`pages/`, `components/`, `hooks/`) rather than abstraction level produce God components that mix data fetching with markup, unresolvable import cycles between features, and no clear rule for where a new component belongs.

**Solution:** Organize components by abstraction level (Atoms -> Molecules -> Organisms -> Templates -> Pages). Each level depends only on levels below it. Feature-specific components are co-located with their hooks and utilities in a `features/` directory.

**Implementation Notes:**
- Atoms: stateless, no API calls, no business logic, fully controlled by props. Examples: `Button`, `Input`, `Badge`, `Icon`, `Spinner`.
- Molecules: compose atoms; may hold local UI state (open/closed, hover) but no server state. Examples: `SearchBar` (Input + Button + Icon), `Dropdown`.
- Organisms: may contain feature logic and connect to server state via hooks. Examples: `Header`, `UserMenu`, `ProductCard`.
- Features: co-locate a domain's component, hook, types, and utils together. Import from atoms/molecules freely; never import from another feature directly. Share across features through atoms/molecules or a `/lib/shared` layer.
- Pages (Next.js): thin wrappers that call Templates or Features. Data fetching lives here (or in Server Components) — not in atoms or molecules.
- Shared design-system components (atoms, molecules) belong in `src/components/`; feature components belong in `src/features/`.

**Example:**
```tsx
// src/components/atoms/Button.tsx — stateless, no business logic
import { ButtonHTMLAttributes } from 'react';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'ghost' | 'destructive';
  size?: 'sm' | 'md' | 'lg';
}

export function Button({ variant = 'primary', size = 'md', children, ...props }: ButtonProps) {
  return (
    <button className={`btn btn-${variant} btn-${size}`} {...props}>
      {children}
    </button>
  );
}
```

```tsx
// src/components/molecules/SearchBar.tsx — composes atoms, local UI state only
import { useState } from 'react';
import { Button } from '../atoms/Button';
import { Input } from '../atoms/Input';
import { Icon } from '../atoms/Icon';

interface SearchBarProps {
  onSearch: (query: string) => void;
  placeholder?: string;
}

export function SearchBar({ onSearch, placeholder = 'Search...' }: SearchBarProps) {
  const [query, setQuery] = useState('');

  return (
    <div role="search" className="flex gap-2">
      <Input
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder={placeholder}
        aria-label="Search query"
      />
      <Button onClick={() => onSearch(query)} aria-label="Submit search">
        <Icon name="search" />
      </Button>
    </div>
  );
}
```

```tsx
// src/features/users/UserListPage.tsx — feature component with server state
import { SearchBar } from '../../components/molecules/SearchBar';
import { useUserSearch } from './useUserSearch';

export function UserListPage() {
  const { results, search, isLoading } = useUserSearch();

  return (
    <main>
      <SearchBar onSearch={search} />
      {isLoading ? <Spinner /> : <UserTable rows={results} />}
    </main>
  );
}

// src/features/users/useUserSearch.ts — co-located hook
export function useUserSearch() {
  // server state logic here
}
```

**Common Mistakes:**
- Putting business logic or API calls in atoms — they become impossible to test in isolation and cannot be reused in Storybook.
- Feature A importing directly from Feature B — creates hidden coupling; both features must change together. Route through atoms/molecules or a shared lib.
- One large `components/` folder without hierarchy — engineers disagree on where new components go and avoid splitting existing ones.

**Security Considerations:**
- Never pass auth tokens, raw API keys, or unmasked PII as props to atoms or molecules — they belong in hooks or server-side logic, not in presentational components that might be logged or rendered in error boundaries.

**Testing:**
- Atoms: render in isolation with Storybook; unit test with `@testing-library/react` in jsdom.
- Molecules: test user interactions (click, keyboard input) and prop-driven state transitions.
- Organisms and Features: integration test with mocked API responses using `msw`.
- Never mock child atoms inside a molecule test — let them render and test the composed output.

**Score:** Candidate

---

## Pattern: Accessibility (WCAG 2.2)

**Problem:** Interactive components built without ARIA attributes, keyboard navigation, or focus management are unusable for screen reader and keyboard-only users, and may violate legal accessibility requirements (ADA, EN 301 549).

**Solution:** Follow WCAG 2.2 principles (Perceivable, Operable, Understandable, Robust) as a non-negotiable baseline. Use semantic HTML first; add ARIA only when native semantics are insufficient.

**Implementation Notes:**
- Semantic HTML first: `<button>` not `<div onClick>`, `<nav>` not `<div className="nav">`, `<h1>`-`<h6>` in document order. Semantic elements provide role, name, and state to assistive technology for free.
- ARIA rules: never use ARIA to override native HTML semantics. Required attributes: `aria-label` or `aria-labelledby` on icon-only buttons; `aria-expanded` on disclosure toggles; `aria-live="polite"` for dynamic content updates (toasts, status); `aria-live="assertive"` for urgent alerts (form errors).
- Keyboard navigation: every interactive element reachable by Tab; focus indicator visible (`outline: 2px solid`; never `outline: none` without an equivalent); Escape closes modals and menus; arrow keys navigate within composite widgets (menus, listboxes, radio groups) per the ARIA Authoring Practices Guide.
- Focus management: when a modal opens, focus moves into it; when it closes, focus returns to the trigger element that opened it.
- Color contrast: body text 4.5:1 ratio (AA); large text (18 pt or 14 pt bold) 3:1. Never use color as the only means to convey information — always pair with text, icons, or patterns.

**Example:**
```tsx
// Accessible modal dialog with focus management and keyboard handling
import { useRef, useEffect } from 'react';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  triggerRef: React.RefObject<HTMLElement>;
}

export function Modal({ isOpen, onClose, title, children, triggerRef }: ModalProps) {
  const modalRef = useRef<HTMLDivElement>(null);
  const titleId  = `modal-title-${title.replace(/\s+/g, '-').toLowerCase()}`;

  // Move focus into modal on open; return focus to trigger on close
  useEffect(() => {
    if (!isOpen) return;
    modalRef.current?.focus();
    return () => { triggerRef.current?.focus(); };
  }, [isOpen, triggerRef]);

  // Escape key closes modal
  useEffect(() => {
    if (!isOpen) return;
    const handler = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose(); };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div role="presentation" className="modal-backdrop" onClick={onClose}>
      <div
        ref={modalRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        tabIndex={-1}
        className="modal-panel"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 id={titleId}>{title}</h2>
        {children}
        <button onClick={onClose} aria-label="Close dialog">Close</button>
      </div>
    </div>
  );
}
```

```tsx
// Button with disclosure state
function NavMenu() {
  const [isOpen, setIsOpen] = useState(false);
  const menuId = 'nav-menu';

  return (
    <>
      <button
        aria-expanded={isOpen}
        aria-controls={menuId}
        onClick={() => setIsOpen((prev) => !prev)}
      >
        Menu
      </button>
      <ul id={menuId} role="menu" hidden={!isOpen}>
        <li role="menuitem"><a href="/home">Home</a></li>
        <li role="menuitem"><a href="/settings">Settings</a></li>
      </ul>
    </>
  );
}
```

**Common Mistakes:**
- Adding `tabIndex={0}` to a `<div>` to make it interactive — use `<button>` or `<a>` so the browser provides role, keyboard handling, and activation for free.
- Missing `aria-live` on form submission feedback — screen reader users hear nothing after submitting and do not know if it succeeded or failed.
- Modal without a focus trap — keyboard users Tab past the modal into obscured content behind the overlay.
- `onClick` without `onKeyDown` for Enter/Space — keyboard users cannot activate the element (this problem disappears when using native `<button>`).

**Security Considerations:**
- Avoid `dangerouslySetInnerHTML` in ARIA labels and visible text — ARIA attributes rendered from user-supplied strings are XSS vectors.

**Testing:**
- Automated: integrate `jest-axe` (`expect(await axe(container)).toHaveNoViolations()`) into every component test; this catches approximately 30% of WCAG issues.
- Manual: navigate each interactive component with keyboard only; verify with VoiceOver on macOS and NVDA on Windows.
- CI: integrate `@axe-core/playwright` into E2E tests and fail the build on any violation with severity `critical` or `serious`.

**Score:** Candidate

---

## Pattern: Data Table

**Problem:** Tables that render thousands of rows into the DOM cause layout thrashing and slow scrolling; tables without sort/filter/paginate require users to scan entire datasets manually.

**Solution:** Use a headless table library (TanStack Table) for column definitions, sorting, filtering, and selection state; pair with server-side data operations for datasets larger than ~500 rows; add virtual row rendering (TanStack Virtual) only when pagination is insufficient.

**Implementation Notes:**
- Prefer server-side sort, filter, and paginate for large datasets — fetch only the visible page, not the full dataset.
- TanStack Table is headless: it manages state and computes derived values; you own the markup. Wrap with shadcn/ui `<Table>` for consistent styling without losing control.
- Column definitions: use `accessorKey` for simple field mapping; use `cell` with a renderer function for formatted, linked, or action cells.
- Always memoize column definitions with `useMemo` — column objects are referentially compared and recreating them causes a full table re-render on every parent render.
- Empty states: render an explicit `<tr><td colSpan={columns.length}>No results.</td></tr>` row; never render zero rows silently.
- Bulk actions: maintain `rowSelection` state; show a bulk-action toolbar only when `Object.keys(rowSelection).length > 0`; require explicit confirmation before destructive bulk operations.

**Example:**
```tsx
import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  flexRender,
  type ColumnDef,
  type SortingState,
} from '@tanstack/react-table';
import { useMemo, useState } from 'react';

interface User { id: string; name: string; email: string; createdAt: string; }

const columns: ColumnDef<User>[] = [
  {
    id: 'select',
    header: ({ table }) => (
      <input
        type="checkbox"
        checked={table.getIsAllPageRowsSelected()}
        onChange={table.getToggleAllPageRowsSelectedHandler()}
        aria-label="Select all rows"
      />
    ),
    cell: ({ row }) => (
      <input
        type="checkbox"
        checked={row.getIsSelected()}
        onChange={row.getToggleSelectedHandler()}
        aria-label={`Select row ${row.original.name}`}
      />
    ),
  },
  { accessorKey: 'name',      header: 'Name' },
  { accessorKey: 'email',     header: 'Email' },
  {
    accessorKey: 'createdAt',
    header: 'Created',
    cell: ({ getValue }) => new Date(getValue<string>()).toLocaleDateString(),
  },
];

interface UserTableProps {
  data: User[];
  onSort: (field: string, direction: 'asc' | 'desc') => void;
  onBulkDelete: (ids: string[]) => Promise<void>;
}

export function UserTable({ data, onSort, onBulkDelete }: UserTableProps) {
  const [sorting, setSorting]       = useState<SortingState>([]);
  const [rowSelection, setRowSelection] = useState({});
  const memoizedColumns             = useMemo(() => columns, []);

  const table = useReactTable({
    data,
    columns: memoizedColumns,
    state: { sorting, rowSelection },
    manualSorting: true,
    enableRowSelection: true,
    onSortingChange: (updater) => {
      const next = typeof updater === 'function' ? updater(sorting) : updater;
      setSorting(next);
      if (next[0]) onSort(next[0].id, next[0].desc ? 'desc' : 'asc');
    },
    onRowSelectionChange: setRowSelection,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
  });

  const selectedIds = table.getSelectedRowModel().rows.map((r) => r.original.id);

  return (
    <>
      {selectedIds.length > 0 && (
        <div role="toolbar" aria-label="Bulk actions">
          <span>{selectedIds.length} selected</span>
          <button
            onClick={async () => {
              if (confirm(`Delete ${selectedIds.length} users?`)) {
                await onBulkDelete(selectedIds);
                setRowSelection({});
              }
            }}
          >
            Delete selected
          </button>
        </div>
      )}

      <table aria-label="Users">
        <thead>
          {table.getHeaderGroups().map((hg) => (
            <tr key={hg.id}>
              {hg.headers.map((header) => (
                <th
                  key={header.id}
                  scope="col"
                  aria-sort={
                    header.column.getIsSorted() === 'asc'  ? 'ascending'  :
                    header.column.getIsSorted() === 'desc' ? 'descending' :
                    header.column.getCanSort()             ? 'none'       : undefined
                  }
                  onClick={header.column.getToggleSortingHandler()}
                  style={{ cursor: header.column.getCanSort() ? 'pointer' : 'default' }}
                >
                  {flexRender(header.column.columnDef.header, header.getContext())}
                </th>
              ))}
            </tr>
          ))}
        </thead>
        <tbody>
          {table.getRowModel().rows.length === 0 ? (
            <tr>
              <td colSpan={memoizedColumns.length} style={{ textAlign: 'center' }}>
                No results.
              </td>
            </tr>
          ) : (
            table.getRowModel().rows.map((row) => (
              <tr key={row.original.id}>
                {row.getVisibleCells().map((cell) => (
                  <td key={cell.id}>
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </td>
                ))}
              </tr>
            ))
          )}
        </tbody>
      </table>
    </>
  );
}
```

**Common Mistakes:**
- Fetching all rows client-side for filtering — acceptable for 50 rows, unacceptable for 5000.
- Not memoizing column definitions — causes a full table re-render on every parent state change.
- Using array index as React `key` — breaks selection and animation state when rows reorder or are removed; use the stable row ID.
- Performing bulk delete without a confirmation step — data loss with no recovery path.

**Security Considerations:**
- Sanitize filter query strings server-side — filter values become SQL query parameters and must be parameterized, not interpolated.
- Validate `sort` column names against an explicit allowlist on the server — arbitrary column names in ORDER BY clauses can leak schema details or cause errors.

**Testing:**
- Unit: assert that column sort produces the correct order for strings, numbers, and ISO dates.
- Integration: assert the server receives the correct `sort`, `direction`, and `page` query parameters when the user clicks a column header.
- E2E: select all rows, deselect one, confirm the bulk-action toolbar shows the correct count, and assert the delete confirmation dialog appears.
- Accessibility: assert the table has an `aria-label`, all `<th>` elements have `scope="col"` or `scope="row"`, and sortable headers have `aria-sort`.

**Score:** Candidate

---

## Pattern: Theming (Dark Mode + Brand Tokens)

**Problem:** Adding dark mode after launch requires touching every component individually. Supporting white-label brand customization requires hard-coded overrides throughout the codebase.

**Solution:** Build the entire color system on semantic CSS custom properties from the start. A theme switches the property values at the root; no component changes.

**Implementation Notes:**
- Detect system preference with `prefers-color-scheme` as the default. Allow user override stored in `localStorage` and applied synchronously before the page renders to eliminate flash.
- Apply the theme via a `data-theme` attribute on `<html>` rather than toggling CSS classes. Attribute selectors compose cleanly with arbitrary brand overrides.
- Avoid hard-coding `#ffffff` or Tailwind utilities like `text-gray-900` in component files. Use token-backed CSS variable references.
- For white-label: load tenant-specific token overrides from their config at runtime and inject them as a scoped `<style>` block or via a CSS custom property block on the tenant's root element. Never inject raw CSS strings from user input.
- Synchronize with the server on initial render to avoid hydration mismatches in SSR — store the theme in a cookie in addition to `localStorage` and read it in the server render.

**Example:**
```css
/* tokens.css — generated by Style Dictionary */
:root {
  --color-bg:         #ffffff;
  --color-text:       #111827;
  --color-surface:    #f9fafb;
  --color-border:     #e5e7eb;
  --color-primary:    #2563eb;
  --color-primary-fg: #ffffff;
}

[data-theme="dark"] {
  --color-bg:         #111827;
  --color-text:       #f9fafb;
  --color-surface:    #1f2937;
  --color-border:     #374151;
  --color-primary:    #3b82f6;
  --color-primary-fg: #ffffff;
}

/* White-label override — injected at runtime per tenant */
[data-theme="brand-acme"] {
  --color-primary:    #e11d48;
  --color-primary-fg: #ffffff;
}
```

```tsx
// ThemeProvider.tsx
'use client';
import { createContext, useContext, useEffect, useState } from 'react';

type Theme = 'light' | 'dark' | 'system';
const ThemeContext = createContext<{ theme: Theme; setTheme: (t: Theme) => void } | null>(null);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [theme, setThemeState] = useState<Theme>('system');

  useEffect(() => {
    const stored = localStorage.getItem('theme') as Theme | null;
    if (stored) setThemeState(stored);
  }, []);

  useEffect(() => {
    const root        = document.documentElement;
    const resolvedTheme =
      theme === 'system'
        ? window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
        : theme;
    root.setAttribute('data-theme', resolvedTheme);
    localStorage.setItem('theme', theme);
    document.cookie = `theme=${theme}; path=/; max-age=31536000`;
  }, [theme]);

  useEffect(() => {
    if (theme !== 'system') return;
    const mq      = window.matchMedia('(prefers-color-scheme: dark)');
    const handler = () =>
      document.documentElement.setAttribute('data-theme', mq.matches ? 'dark' : 'light');
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, [theme]);

  return (
    <ThemeContext.Provider value={{ theme, setTheme: setThemeState }}>
      {children}
    </ThemeContext.Provider>
  );
}

export const useTheme = () => {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used within ThemeProvider');
  return ctx;
};
```

```tsx
// app/layout.tsx — inline script prevents flash before React hydrates
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html: `(function(){try{
              var t=localStorage.getItem('theme')||'system';
              if(t==='system'){t=window.matchMedia('(prefers-color-scheme:dark)').matches?'dark':'light';}
              document.documentElement.setAttribute('data-theme',t);
            }catch(e){}})();`,
          }}
        />
      </head>
      <body>
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
```

**Common Mistakes:**
- Storing theme only in React state — causes a flash of the default theme on every page reload before JS hydrates.
- Using Tailwind `dark:` variants throughout components instead of semantic CSS variables — doubles the CSS output and still requires component changes when adding a third theme.
- Not listening to `prefers-color-scheme` change events — users who change their system theme mid-session see no update until they reload.

**Security Considerations:**
- If tenant brand overrides are user-supplied strings, restrict them to overriding only a named allowlist of `--color-*` variable names. Validate allowlist server-side before injecting. Never inject a raw CSS string from user input — it is a CSS injection vector.

**Testing:**
- Assert `localStorage.getItem('theme')` persists the correct value after `setTheme` is called.
- Assert that the inline script sets `data-theme` before React renders (test by verifying the attribute is present in SSR HTML via the cookie path).
- Run visual regression tests in both `light` and `dark` data-theme states.
- Test tenant theme injection: mock a tenant config, assert that CSS variables resolve to the tenant's values under `[data-theme="brand-<tenant>"]`.
- Mock `window.matchMedia('(prefers-color-scheme: dark)')` and assert the correct theme is applied without user action.

**Score:** Candidate

---

## Pattern: Form Accessibility & Error States

**Problem:** Form errors shown only in color or without ARIA announcements are invisible to screen reader users. Loading and success states without announcements leave assistive technology users uncertain whether their action had any effect.

**Solution:** Associate every field-level error with its input using `aria-describedby`. Announce form-level errors with `aria-live="assertive"`. Announce success confirmations with `aria-live="polite"`.

**Implementation Notes:**
- Field-level errors: set `aria-invalid="true"` on the input when invalid; set `aria-describedby` pointing to the error element's `id`. The error element should have `role="alert"` so it is announced immediately when it appears.
- Form-level errors (post-submit summary): render the summary in an `aria-live="assertive"` region; move focus to the summary element after it renders so screen reader users land on it.
- Loading state: set `aria-disabled="true"` on the submit button alongside `disabled` (the `disabled` attribute removes it from the tab order; `aria-disabled` keeps it reachable so users can understand there is a pending action); render a spinner with an accessible `aria-label`.
- Success state: announce in an `aria-live="polite"` region. If redirecting, do so after a short delay (1-2 s) so the announcement has time to complete.
- Never use `placeholder` as a visible label — it disappears on input and is not reliably announced by all screen readers.
- Never convey required status by color alone — add a visible asterisk (*) and a legend explaining the convention, or use the word "Required".

**Example:**
```tsx
import { useId, useRef, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const schema = z.object({
  email:    z.string().email('Enter a valid email address.'),
  password: z.string().min(8, 'Password must be at least 8 characters.'),
});
type FormData = z.infer<typeof schema>;

export function SignInForm() {
  const emailErrorId    = useId();
  const passwordErrorId = useId();
  const formErrorRef    = useRef<HTMLDivElement>(null);
  const [formError,  setFormError]  = useState<string | null>(null);
  const [isSuccess,  setIsSuccess]  = useState(false);

  const { register, handleSubmit, formState: { errors, isSubmitting } } =
    useForm<FormData>({ resolver: zodResolver(schema) });

  const onSubmit = async (data: FormData) => {
    setFormError(null);
    try {
      await signIn(data);
      setIsSuccess(true);
    } catch {
      // Never expose raw server error text to the user
      setFormError('Sign in failed. Check your email and password and try again.');
      formErrorRef.current?.focus();
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate>
      {/* Form-level error — assertive, gets focus after render */}
      <div
        ref={formErrorRef}
        aria-live="assertive"
        aria-atomic="true"
        tabIndex={-1}
        style={{ outline: 'none' }}
      >
        {formError && <p role="alert">{formError}</p>}
      </div>

      {/* Success announcement — polite */}
      <div aria-live="polite" aria-atomic="true">
        {isSuccess && <p>Signed in successfully.</p>}
      </div>

      <div>
        <label htmlFor="email">
          Email <span aria-hidden="true">*</span>
          <span className="sr-only">(required)</span>
        </label>
        <input
          id="email"
          type="email"
          autoComplete="email"
          aria-required="true"
          aria-invalid={!!errors.email}
          aria-describedby={errors.email ? emailErrorId : undefined}
          {...register('email')}
        />
        {errors.email && (
          <p id={emailErrorId} role="alert">{errors.email.message}</p>
        )}
      </div>

      <div>
        <label htmlFor="password">
          Password <span aria-hidden="true">*</span>
          <span className="sr-only">(required)</span>
        </label>
        <input
          id="password"
          type="password"
          autoComplete="current-password"
          aria-required="true"
          aria-invalid={!!errors.password}
          aria-describedby={errors.password ? passwordErrorId : undefined}
          {...register('password')}
        />
        {errors.password && (
          <p id={passwordErrorId} role="alert">{errors.password.message}</p>
        )}
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        aria-disabled={isSubmitting}
        aria-busy={isSubmitting}
      >
        {isSubmitting ? <span aria-label="Signing in...">...</span> : 'Sign in'}
      </button>
    </form>
  );
}
```

**Common Mistakes:**
- Using `placeholder` as the field label — it disappears when the user starts typing and is not reliably announced by all screen readers.
- Marking fields `required` in HTML only, without a visible indicator — sighted users cannot identify required fields before submitting.
- Auto-focusing an input on page load when the page contains complex navigation — disorients screen reader users who have not yet explored the page structure.

**Security Considerations:**
- Never display raw server error messages in form error states — they may expose SQL schema, internal service names, file paths, or PII.
- Sanitize all error strings before rendering, even when they originate from your own API. Keep user-facing messages generic; log detailed errors server-side.

**Testing:**
- `jest-axe`: assert no violations on the rendered form in its default state and after triggering validation errors.
- Manual: submit an empty form and verify each field error is announced by VoiceOver and NVDA.
- Test loading state with a screen reader: confirm the `aria-label="Signing in..."` text is announced when `isSubmitting` is true.
- Assert the form-level error summary receives focus after a failed submission.

**Score:** Candidate

---

## Pattern: Dashboard Layout

**Problem:** Dashboard UIs with no layout hierarchy assign equal visual weight to all information, making it impossible for users to identify key metrics, spot anomalies, or navigate sections efficiently. Without responsive design, mobile users cannot use the dashboard at all.

**Solution:** Apply a clear information hierarchy: persistent navigation (low emphasis) -> summary KPI row (high emphasis, above the fold) -> primary content area -> secondary/detail panels. Use CSS Grid with consistent responsive breakpoints.

**Implementation Notes:**
- KPI cards: 3-5 maximum in the above-the-fold row; each card shows current value, delta vs. prior period, and trend direction (up/down). More than 5 KPIs dilutes attention; move lower-priority metrics below the fold.
- Data freshness: display a last-updated timestamp on every chart; auto-refresh with a `stale-while-revalidate` (SWR) strategy to avoid stale numbers going unnoticed.
- Empty states for charts: render an explicit message and a CTA when no data exists. Never display an empty chart frame — it reads as a loading error.
- Skeleton loaders: render placeholder skeletons at the correct dimensions while data loads to prevent layout shift and disorientation.
- Responsive: sidebar collapses to a bottom navigation bar on mobile; KPI row scrolls horizontally on small screens; charts stack vertically; secondary panels move below the primary content.
- Landmark regions: use `<nav>` for sidebar, `<main>` for the primary content area, and `<aside>` for secondary panels so keyboard and screen reader users can jump between sections.

**Example:**
```tsx
// DashboardShell.tsx — responsive layout with landmark regions
import { Suspense } from 'react';

export function DashboardShell() {
  return (
    <div className="dashboard-grid">
      <nav aria-label="Main navigation" className="dashboard-nav">
        <NavMenu />
      </nav>

      <main className="dashboard-main">
        <h1 className="sr-only">Dashboard</h1>
        <Suspense fallback={<KpiRowSkeleton />}>
          <KpiRow />
        </Suspense>
        <Suspense fallback={<ChartSkeleton />}>
          <PrimaryChart />
        </Suspense>
      </main>

      <aside aria-label="Details" className="dashboard-aside">
        <Suspense fallback={<PanelSkeleton />}>
          <ActivityFeed />
        </Suspense>
      </aside>
    </div>
  );
}
```

```css
/* dashboard.css — CSS Grid layout */
.dashboard-grid {
  display: grid;
  grid-template-areas: "nav main aside";
  grid-template-columns: 240px 1fr 320px;
  min-height: 100vh;
}
.dashboard-nav   { grid-area: nav;   background: var(--color-surface); }
.dashboard-main  { grid-area: main;  padding: var(--space-6); overflow-y: auto; }
.dashboard-aside { grid-area: aside; padding: var(--space-4); border-left: 1px solid var(--color-border); }

/* Tablet */
@media (max-width: 1024px) {
  .dashboard-grid {
    grid-template-areas: "nav main" "nav aside";
    grid-template-columns: 240px 1fr;
  }
  .dashboard-aside { border-top: 1px solid var(--color-border); border-left: none; }
}

/* Mobile */
@media (max-width: 640px) {
  .dashboard-grid {
    grid-template-areas: "main" "aside" "nav";
    grid-template-columns: 1fr;
    padding-bottom: 60px;
  }
  .dashboard-nav {
    position: fixed;
    bottom: 0; left: 0; right: 0;
    height: 60px;
    display: flex;
    flex-direction: row;
    z-index: var(--z-sticky);
  }
}
```

```tsx
// KpiCard.tsx — metric with delta and stale-while-revalidate refresh
import useSWR from 'swr';

interface KpiCardProps { label: string; metricKey: string; }

export function KpiCard({ label, metricKey }: KpiCardProps) {
  const { data, isLoading } = useSWR(`/api/metrics/${metricKey}`, fetcher, {
    refreshInterval: 60_000,
    revalidateOnFocus: true,
  });

  if (isLoading) return <KpiCardSkeleton />;
  if (!data)     return <KpiCardEmpty label={label} />;

  const isPositive = data.delta >= 0;

  return (
    <article aria-label={`${label}: ${data.value}`} className="kpi-card">
      <h2 className="kpi-label">{label}</h2>
      <p className="kpi-value">{data.formatted}</p>
      <p
        className={`kpi-delta ${isPositive ? 'kpi-delta--up' : 'kpi-delta--down'}`}
        aria-label={`${isPositive ? 'Up' : 'Down'} ${Math.abs(data.delta)}% vs. last period`}
      >
        {/* Icon paired with text — never color alone */}
        <span aria-hidden="true">{isPositive ? '▲' : '▼'}</span>
        {Math.abs(data.delta)}%
      </p>
      <p className="kpi-updated">
        Updated {new Date(data.updatedAt).toLocaleTimeString()}
      </p>
    </article>
  );
}
```

**Common Mistakes:**
- More than 5 KPIs in the header row — each additional card reduces the attention given to all others; move non-critical metrics below the fold.
- Charts without axis labels or units — users cannot interpret values without context (`$`, `ms`, `%`).
- No skeleton loaders — layout shift when data loads causes disorientation and is measured negatively by Core Web Vitals (CLS).
- Dashboard designed only at 1440px — mobile and tablet users encounter broken or unreadable layouts.

**Security Considerations:**
- Aggregate metrics on the dashboard must respect the authenticated user's data access scope — query server-side with the current user's tenant ID; never rely on client-side filtering of a full cross-tenant dataset.
- Timestamps and row IDs visible in charts or tables must not expose information about other tenants' activity.

**Testing:**
- Visual regression: snapshot the dashboard with mock data at 375 px, 768 px, and 1280 px breakpoints; fail CI on unexpected layout changes.
- Accessibility: assert `<nav>`, `<main>`, and `<aside>` landmark regions are present; assert no duplicate `<h1>`.
- Data permissions: assert a user authenticated with tenant A's token cannot see tenant B's data in any chart or KPI.
- Stale data: assert the last-updated timestamp updates after the SWR refresh interval elapses.

**Score:** Candidate

---

## Official References

- shadcn/ui: https://ui.shadcn.com/docs (Official Documentation)
- Radix UI Primitives: https://www.radix-ui.com/primitives (Official Documentation)
- Material Design 3: https://m3.material.io/ (Official Documentation)
- WCAG 2.2: https://www.w3.org/TR/WCAG22/ (Official Documentation)
- WAI-ARIA 1.2: https://www.w3.org/TR/wai-aria-1.2/ (Official Documentation)
- WAI-ARIA Authoring Practices Guide: https://www.w3.org/WAI/ARIA/apg/ (Official Documentation)
- Radix UI Accessibility: https://www.radix-ui.com/primitives/docs/overview/accessibility (Official Documentation)
- TanStack Table: https://tanstack.com/table/latest/docs/introduction (Official Documentation)
- TanStack Virtual: https://tanstack.com/virtual/latest/docs/introduction (Official Documentation)
- Style Dictionary: https://amzn.github.io/style-dictionary/#/ (Official Repository - Amazon)
