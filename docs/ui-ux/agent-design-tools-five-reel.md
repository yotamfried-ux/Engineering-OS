# Five tools for improving AI-generated UI — verified Reel

**Source:** https://www.instagram.com/reel/DgJC0A4SF7B/ — spoken transcript recovered and official tool sources independently checked on 2026-11-25.

The creator lists five things: **shadcn/ui MCP, 21st.dev, React Bits, Impeccable and Pinterest**. Automated transcription rendered shadcn and React Bits phonetically; canonical branding was resolved against the official projects.

| Tool | Actual mechanism | Engineering OS integration |
|---|---|---|
| [shadcn/ui MCP](https://ui.shadcn.com/docs/mcp) | Search configured registries and retrieve/install components through agent MCP | Opt-in `shadcn-mcp` uses official `npx shadcn@latest mcp` server; check `/mcp` live connection |
| [21st.dev](https://21st.dev/) | Browse design/component references; remote MCP requires provider API credentials | `21st-mcp` registered as conditional, **not connected** |
| [React Bits](https://reactbits.dev/) | Source-level animated components and text effects | Executable `tools/reactbits_component.py` installs a selected official registry component into a React project |
| [Impeccable](https://impeccable.style/) | Agent skill reviewing alignment, typography, polish and accessibility | `impeccable` Git-backed skill installer, verified isolated host install |
| [Pinterest](https://www.pinterest.com/) | Visual inspiration and reference images | Reference-only website; no unverified automated download/copy of copyrighted design assets |

## Practical evaluation

Start from product requirements and design system, not the tool's visual gallery. Provide the agent with approved reference links and constraints, then compare output with original product intent. Prefer existing accessible components over creating new components without a reason. Check RTL, reduced motion, focus, keyboard navigation, responsiveness, working forms and actual value to the customer. Do not copy branded UIs/images without permission.

A layout that appears more polished is only a design hypothesis; verify real usability and brand fit. Combining five overlapping sources at once can increase inconsistent styling and code bloat; choose the minimum sources needed.

Reference standards: https://www.w3.org/WAI/ARIA/apg/ and https://www.w3.org/WAI/WCAG22/Techniques/html/H102 .
