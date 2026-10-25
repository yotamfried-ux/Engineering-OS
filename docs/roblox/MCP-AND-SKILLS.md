# Roblox MCP and agent skills

## Official Studio MCP

- [Roblox Studio official agent plugin](https://github.com/Roblox/roblox-studio-agent-plugin) — official integration and setup; Roblox Studio contains the actual local MCP server.
- [AI accelerated workflows](https://create.roblox.com/docs/ai/accelerated-workflows) — official setup and workflow.
- [roblox-get-started SKILL.md](https://github.com/Roblox/roblox-studio-agent-plugin/blob/main/skills/roblox-get-started/SKILL.md) — official install/connect skill.
- [Roblox AI-oriented documentation index](https://create.roblox.com/docs/llms.txt), [Engine index](https://create.roblox.com/docs/reference/engine/llms.txt), [Cloud index](https://create.roblox.com/docs/cloud/llms.txt).

The local Studio MCP requires Roblox Studio on **Windows/macOS**, a place open and Studio MCP enabled. Cloud/mobile chat cannot directly reach the user's local Studio. Never install a duplicate MCP bridge when official Studio MCP is available. Verify connection by listing open Studio windows, not merely by inspecting a config file.

## Skill routing

Official Roblox Assistant capabilities may include docs search, debugging, unit testing, performance profiling, scene analysis and device simulation. **Do not assume every skill exists in every Studio version or that it is a standalone downloadable skill**: enumerate available capabilities through Studio's `skill` tool.

Suggested **new Engineering-OS knowledge skills** (not Roblox-official packages):
- `roblox-game-planning`: competitor research, core loop, PRD and prototype gate.
- `roblox-architecture`: server trust, persistence, networking and code structure.
- `roblox-monetization-review`: policy, receipts, ethics and unit economics.
- `roblox-growth-analysis`: analytics events, cohorts, discovery and experiments.
- `roblox-release-qualification`: tests, devices, performance, safety and launch evidence.

Use the [master guide](GAME-DEVELOPMENT-MASTER-GUIDE.md) as skill context; these are design proposals until implemented and validated.

## Capability matrix

| Tool | Native MCP? | Preferred integration |
|---|---|---|
| Roblox Studio | yes, official | local Studio MCP |
| GitHub | yes, official | GitHub MCP / existing connector |
| Figma | yes, official | Figma MCP where available |
| Blender | no Blender-official server verified here | vetted community MCP or scripts |
| Rojo, Rokit, Wally, Selene, StyLua, Lune | no native MCP established | CLI through authorized shell |
| Luau, React Luau, TestEZ, ProfileStore | not MCP servers | code libraries/toolchain |
| Roblox Open Cloud | API; no Roblox-official MCP verified here | REST with scoped credentials |

MCP support is **not** proof that a connector is installed, connected or authorized. Validate host permissions and one safe representative operation before marking READY.
