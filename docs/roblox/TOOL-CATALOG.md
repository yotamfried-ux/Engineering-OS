# Roblox tool and source catalog — complete coverage

Status: references, not installed dependencies. Review version, maintainer, license, API compatibility and safety before adopting. This inventory covers all tools and sources proposed in the Roblox knowledge initiative. Each category links to a dedicated principles guide.

| Tool / source | Category | MCP classification | Primary guide |
|---|---|---|---|
| [Creator Hub](https://create.roblox.com/docs), [Creation overview](https://create.roblox.com/docs/creation), [Game design](https://create.roblox.com/docs/production/game-design), [creator-docs](https://github.com/Roblox/creator-docs) | official platform docs | documentation, not MCP | [Master guide](GAME-DEVELOPMENT-MASTER-GUIDE.md) |
| [Roblox Studio](https://create.roblox.com/docs/studio), [Studio agent plugin](https://github.com/Roblox/roblox-studio-agent-plugin) | game engine/AI | official Studio MCP | [Engineering](ENGINEERING-AND-TOOLS.md), [MCP](MCP-AND-SKILLS.md) |
| [GitHub](https://github.com/), [GitHub MCP](https://github.com/github/github-mcp-server) | source control | official MCP | [Engineering](ENGINEERING-AND-TOOLS.md) |
| [Rojo](https://github.com/rojo-rbx/rojo), [Rokit](https://github.com/rojo-rbx/rokit), [Wally](https://github.com/UpliftGames/wally) | source sync/toolchain/dependencies | CLI/plugin, not native MCP | [Engineering](ENGINEERING-AND-TOOLS.md) |
| [Luau](https://github.com/luau-lang/luau), [Selene](https://github.com/Kampfkarren/selene), [StyLua](https://github.com/JohnnyMorganz/StyLua), [Lune](https://github.com/lune-org/lune) | language/quality/automation | tooling/CLI, not native MCP | [Engineering](ENGINEERING-AND-TOOLS.md) |
| [React Luau](https://github.com/Roblox/react-luau) | UI architecture | library, not MCP | [Art/UX](ART-UX-AND-PRODUCTION.md) |
| [TestEZ](https://github.com/Roblox/testez) | unit testing | library, not MCP | [Quality](QUALITY-SECURITY-LIVEOPS.md) |
| [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) | persistence candidate | library, not MCP | [Engineering](ENGINEERING-AND-TOOLS.md) |
| [Blender](https://www.blender.org/) | 3D/animation | community MCP options; no official Blender MCP confirmed | [Art/UX](ART-UX-AND-PRODUCTION.md) |
| [Figma](https://www.figma.com/), [Figma MCP](https://developers.figma.com/docs/figma-mcp-server/) | UX/interface design | official MCP, access-dependent | [Art/UX](ART-UX-AND-PRODUCTION.md) |
| [Roblox Open Cloud](https://create.roblox.com/docs/cloud) | cloud APIs/publishing automation | REST API, not verified official MCP | [MCP](MCP-AND-SKILLS.md) |
| [Monetization](https://create.roblox.com/docs/production/monetization), [Analytics](https://create.roblox.com/docs/production/analytics), [Promotion](https://create.roblox.com/docs/production/promotion) | business/growth | docs, not MCP | [Business](DESIGN-GROWTH-MONETIZATION.md) |
| [Safety](https://create.roblox.com/docs/safety), [Content maturity](https://create.roblox.com/docs/production/promotion/content-maturity) | policy | docs, not MCP | [Quality](QUALITY-SECURITY-LIVEOPS.md) |
| [AI docs index](https://create.roblox.com/docs/llms.txt), [Engine index](https://create.roblox.com/docs/reference/engine/llms.txt), [Cloud index](https://create.roblox.com/docs/cloud/llms.txt) | AI reference retrieval | docs, not MCP | [MCP](MCP-AND-SKILLS.md) |
| [roblox-get-started](https://github.com/Roblox/roblox-studio-agent-plugin/tree/main/skills/roblox-get-started) | agent skill | skill, not MCP itself | [MCP](MCP-AND-SKILLS.md) |

Roblox Assistant skill names to discover **in the running Studio environment**, not presume installable: `rbx-docs-search`, `rbx-debug`, `rbx-unit-test`, `rbx-perf-profiling`, `rbx-scene-analysis`, `rbx-device-simulator-lua`, `rbx-create-skill`. Engineering-OS proposals: `roblox-game-planning`, `roblox-architecture`, `roblox-monetization-review`, `roblox-growth-analysis`, `roblox-release-qualification`.

## Adoption checklist

1. Prefer official source and verify latest upstream docs; note licensing and compatibility.
2. Classify as official MCP / community MCP / CLI / library / API / docs / skill.
3. Verify actual availability and permissions on the intended host before calling READY.
4. Use narrow permissions, pin versions and test representative read/write safely.
5. Do not copy full third-party repositories into this knowledge library or auto-install tools.
