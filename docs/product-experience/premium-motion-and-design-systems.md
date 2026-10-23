# Premium UI, Motion, Visual Storytelling & Design Systems

## Visual direction before code

Create a brand brief (audience, differentiation, personality, emotional tone), art direction (typography scale, grid, color, imagery, depth), and component tokens. Design states: idle, hover, focus, pressed, loading, success, empty, error and disabled. Treat editorial typography, restrained color, spatial rhythm and original assets as first-class design decisions. A premium interface is not synonymous with maximal animation.

## Authoritative systems and platform guidance

| Source | URL | Use |
|---|---|---|
| Apple Human Interface Guidelines | https://developer.apple.com/design/human-interface-guidelines/ | Native interaction, motion, hierarchy |
| Google Material Design 3 | https://m3.material.io/ | Tokens, interaction states, accessible components |
| IBM Carbon | https://carbondesignsystem.com/ | Enterprise components, design patterns |
| Shopify Polaris | https://polaris.shopify.com/ | Commerce product patterns |
| Adobe Spectrum | https://spectrum.adobe.com/ | Design system and inclusive components |
| Microsoft Fluent 2 | https://fluent2.microsoft.design/ | Interaction, motion, cross-platform patterns |
| W3C WCAG 2.2 | https://www.w3.org/TR/WCAG22/ | Accessibility acceptance criteria |
| WAI ARIA APG | https://www.w3.org/WAI/ARIA/apg/ | Keyboard and semantic interaction patterns |
| Google web.dev animations | https://web.dev/learn/css/animations | CSS animation guidance |
| Google web.dev performance | https://web.dev/explore | Core Web Vitals and animation performance |
| MDN Web Animations API | https://developer.mozilla.org/en-US/docs/Web/API/Web_Animations_API | Browser-native motion APIs |

## Production animation & visual libraries (evaluate per project)

| Library | Official docs | Best suited for | Caution |
|---|---|---|---|
| Motion for React | https://motion.dev/docs/react | Layout transitions, gestures, component microinteractions | Respect reduced motion |
| GSAP + ScrollTrigger | https://gsap.com/docs/v3/Plugins/ScrollTrigger/ | Sophisticated timelines and scroll storytelling | Review commercial license for intended use |
| React Three Fiber | https://r3f.docs.pmnd.rs/ | Immersive WebGL/3D scenes | GPU and accessibility fallback |
| Three.js | https://threejs.org/docs/ | Custom 3D and shader scenes | Mobile performance |
| Lenis | https://lenis.darkroom.engineering/ | Scroll behavior | Do not break native scroll or focus |
| Lottie web | https://airbnb.io/lottie/ | Vector animation playback | Asset complexity |
| Rive | https://rive.app/docs/ | Interactive state-machine animations | Licensing and runtime fit |
| Radix Primitives | https://www.radix-ui.com/primitives | Accessible unstyled React interactions | Add intentional art direction |
| shadcn/ui | https://ui.shadcn.com/docs | Customizable component starting point | Not a finished brand system |
| Tailwind CSS | https://tailwindcss.com/docs | Utility-driven tokens and responsive styling | Avoid generic presets |
| Storybook | https://storybook.js.org/docs | Component states, documentation, visual QA | Maintain examples |

## Premium motion patterns

- Hero reveal: meaningful hierarchy, staggered copy, purposeful visual entrance, never hide primary CTA.
- Scroll narrative: pinned sections and parallax only where they help comprehension; provide a static/reduced-motion alternative.
- Shared-element transitions: preserve spatial continuity across views.
- Microinteractions: input feedback, button press, optimistic state, drag affordances.
- Product demos: short, captioned, controllable, muted-by-default when autoplay is used.
- Depth: restrained 3D, lighting, blur and gradients; keep readable text and interaction hit targets.
- RTL: test transforms, direction, icon semantics and reading order rather than blindly mirroring everything.

## Acceptance checks

- Keyboard and focus states work without motion; reduced-motion mode is meaningful.
- No scroll hijacking that impairs navigation; no flashing hazards.
- Mobile GPU/CPU load, bundle size and layout shift are measured.
- Target Core Web Vitals: LCP <= 2.5s, INP <= 200ms, CLS <= 0.1 at 75th percentile, per current web.dev guidance; verify current thresholds before release.
- Animations do not block content, conversion, reading or accessibility.
- Record screenshots/videos of desktop, mobile, RTL, reduced motion and slow-device fallback.

## Design inspiration (not authoritative UX evidence)

Awwwards https://www.awwwards.com/ ; SiteInspire https://www.siteinspire.com/ ; Godly https://godly.website/ . Use for composition and art direction only; do not infer accessibility, performance or conversion quality from awards.
