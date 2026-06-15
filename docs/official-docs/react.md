# React — Official Documentation Index

## Official Documentation
**Primary:** https://react.dev/
**GitHub:** https://github.com/facebook/react
**Changelog:** https://github.com/facebook/react/blob/main/CHANGELOG.md

## Key Sections (Recommended Reading Order)
1. [Learn React](https://react.dev/learn) — Start here: thinking in React, describing the UI, state, and effects. The new docs are far better than the old ones.
2. [Describing the UI](https://react.dev/learn/describing-the-ui) — Components, JSX, props, conditional rendering, rendering lists.
3. [Managing State](https://react.dev/learn/managing-state) — Lifting state up, reducer pattern, context, avoiding redundant state.
4. [Escape Hatches](https://react.dev/learn/escape-hatches) — Refs, effects, custom hooks — and when NOT to use them.
5. [Hooks Reference](https://react.dev/reference/react) — Complete API reference for all built-in hooks.
6. [Server Components](https://react.dev/reference/rsc/server-components) — RSC architecture; read before using with Next.js App Router.
7. [Suspense](https://react.dev/reference/react/Suspense) — Data fetching boundaries, lazy loading, streaming.

## Important APIs / Concepts
- **useState** — Local component state; prefer multiple small state variables over one large object.
- **useEffect** — Synchronize with external systems only; not for derived state or event responses.
- **useReducer** — Complex state transitions with multiple sub-values; pairs well with useContext.
- **useContext** — Avoid prop drilling; don't overuse — causes re-renders for all consumers.
- **useMemo / useCallback** — Opt-in memoization; only add after profiling, not preemptively.
- **useRef** — Mutable values that don't trigger re-renders; DOM node references.
- **useTransition** — Mark non-urgent state updates; keeps UI responsive during slow renders.
- **Server Components (RSC)** — Render on server with zero client JS; cannot use hooks or browser APIs.
- **Suspense** — Declarative loading states; works with lazy(), data fetching in RSC, and streaming.
- **Strict Mode** — Double-invokes effects/renders in dev to surface impure components; keep enabled.

## Common Patterns
- Custom hooks — see [patterns/ui/README.md](../../patterns/ui/README.md)
- State management with context + reducer — see [patterns/ui/README.md](../../patterns/ui/README.md)
- Data fetching with Suspense — see [patterns/api/README.md](../../patterns/api/README.md)

## Related External Systems
- Next.js (App Router + RSC integration) — see [external-systems/nextjs/README.md](../../external-systems/nextjs/README.md)

## Gotchas & Version Notes
- React 19 (stable): `use()` hook, form Actions, `useOptimistic`, and `useFormStatus` are production-ready.
- Effects run twice in Strict Mode (dev only) — cleanup functions must be correct, not a workaround.
- RSC and client components cannot be mixed arbitrarily: RSC can import client components but not vice versa.
- `useEffect` with an empty dependency array is not "run once" — it runs after every mount including StrictMode remounts.
- Avoid placing derived values in state — compute them during render instead.
- Key prop on lists must be stable and unique; using array index causes subtle bugs on reorder/delete.
- Context does not prevent re-renders of children that don't consume it — split contexts by update frequency.
- React DevTools Profiler is the correct tool for diagnosing render performance, not guesswork.
