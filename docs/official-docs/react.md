# React — Official Documentation Index

## Official Documentation
**Primary:** https://react.dev/
**API Reference:** https://react.dev/reference/react
**GitHub:** https://github.com/facebook/react
**Changelog:** https://github.com/facebook/react/blob/main/CHANGELOG.md

## Key Sections (Recommended Reading Order)

1. [Learn React](https://react.dev/learn) — The new docs are significantly better than the old reactjs.org site; start here even if you already know React
2. [Describing the UI](https://react.dev/learn/describing-the-ui) — Components, JSX, props, conditional rendering, rendering lists; foundational for all that follows
3. [Adding Interactivity](https://react.dev/learn/adding-interactivity) — State, events, render cycle; why state triggers re-renders and how batching works
4. [Managing State](https://react.dev/learn/managing-state) — Lifting state, derived state, `useReducer`; read before reaching for an external state library
5. [Escape Hatches](https://react.dev/learn/escape-hatches) — Refs, effects, custom hooks — and when NOT to use them; the most misunderstood section
6. [Hooks Reference](https://react.dev/reference/react/hooks) — Canonical API for all built-in hooks; bookmark this for argument/return-value lookups
7. [Server Components (RSC)](https://react.dev/reference/rsc/server-components) — What runs on the server, what can't be done in an RSC, how they compose with Client Components
8. [Suspense](https://react.dev/reference/react/Suspense) — Declarative loading states; works with `lazy()`, RSC data fetching, and streaming
9. [useTransition](https://react.dev/reference/react/useTransition) — Marks state updates as non-urgent; the concurrent primitive behind smooth navigation and deferred rendering
10. [React Compiler](https://react.dev/learn/react-compiler) — Automatic memoisation without `useMemo`/`useCallback`; read before manually optimising for performance

## Important APIs / Concepts

- **`useState`** — Local component state; updates are batched in React 18+; never mutate state directly
- **`useEffect`** — Synchronises a component to an external system only; not for derived state or event handling; cleanup must undo the setup
- **`useReducer`** — Complex state with structured transitions; prefer over multiple interdependent `useState` calls
- **`useContext`** — Reads the nearest Provider value; every context change re-renders all consumers — split contexts by update frequency
- **`useMemo` / `useCallback`** — Opt-in memoisation; only add after profiling, not pre-emptively; premature memoisation harms readability
- **`useRef`** — Mutable value that does not trigger re-renders; also the way to hold DOM node references
- **`useTransition` / `useDeferredValue`** — Concurrent mode primitives; keep the UI responsive during slow renders without debouncing timers
- **`Strict Mode`** — Double-invokes renders and effects in development to surface impure code; always keep enabled
- **`key` prop** — Tells React which list items changed; also forces a component remount when changed deliberately; never use array index on reorderable lists

## Common Patterns

- Custom hooks — see [patterns/ui/README.md](../../patterns/ui/README.md)
- State management with context + reducer — see [patterns/ui/README.md](../../patterns/ui/README.md)
- Data fetching with Suspense — see [patterns/api/README.md](../../patterns/api/README.md)

## Related External Systems

- Next.js (App Router + RSC integration) — see [external-systems/nextjs/README.md](../../external-systems/nextjs/README.md)

## Gotchas & Version Notes

- **React 18 batches all state updates** — including those inside `setTimeout` and native event handlers; this changed from React 17 where only React event handlers were batched
- **React 19 removes `forwardRef`** — refs are now a regular prop; update component libraries before upgrading your React version
- **`useEffect` runs twice in Strict Mode (dev only)** — cleanup functions must correctly undo the setup; missing cleanup causes race conditions in production
- **RSC rules are strict** — Server Components cannot use hooks, state, or browser APIs; Client Components cannot be `async` functions; RSC can import Client Components but not vice versa
- **`use client` / `use server` are directives, not imports** — they must be the literal first line of the file
- **The new react.dev docs supersede the old reactjs.org site** — the old site is archived and may show outdated patterns (`componentDidMount`, class components, `getDerivedStateFromProps`)
- **React Compiler is opt-in** — enable per-directory via `babel-plugin-react-compiler`; not yet production-stable for all codebases; verify against your bundler
