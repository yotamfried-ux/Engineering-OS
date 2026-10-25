# High-quality Roblox development — domain excellence playbook

Use this with [the master guide](GAME-DEVELOPMENT-MASTER-GUIDE.md). Each section is a practical standard for what excellent work means, how to get there, and what evidence to request.

## 1. Product strategy and game design
Define target players, market gap and a single compelling player promise. Prototype one core loop before adding content. Design first-minute comprehension, meaningful choices, skill progression, rewards, pacing, fair challenge and social incentives. Conduct user playtests; measure early exits and return intent. **Evidence:** game design brief, competitor comparison, playtest findings.

## 2. Luau and software architecture
Use typed modules with clear ownership and testable boundaries. Keep server authoritative, client responsive, dependencies pinned, and remotes validated. Isolate persistence and monetization behind services. Avoid oversized shared mutable state. **Evidence:** architecture decision, typed/linted code, integration tests. **Tools:** Luau, Rojo, Rokit, Wally, Selene, StyLua, Lune, GitHub.

## 3. Networking, multiplayer and persistence
Design for latency, packet loss, reconnect, concurrent actions, cross-server travel, streaming and eventual consistency. Make critical actions idempotent and observable. Treat untrusted input and inventory duplication as primary threats. **Evidence:** multi-client and failure-injection playtests. **Tools:** Roblox Studio, DataStores, optional audited ProfileStore.

## 4. Art direction and 3D production
Create a coherent visual language: readable silhouettes, restrained palettes, focal hierarchy and purposeful VFX. Plan mesh/texture budgets and LOD, UV/rigging/animation export, lighting and audio. Validate assets in Studio on lower-end devices. **Evidence:** in-engine captures, memory and frame-time budgets. **Tools:** Blender, Roblox Studio.

## 5. UI/UX and accessibility
Optimize first for touch/mobile, then keyboard/mouse and controller. Keep HUD readable, shop pricing transparent, navigation predictable, feedback immediate and onboarding progressive. Test color contrast, localization, safe areas and motion sensitivity. **Evidence:** real device screenshots, usability sessions and task completion. **Tools:** Figma, React Luau, Roblox UI.

## 6. Monetization and economy
Build a sustainable economy with measured currency sources/sinks, transparent entitlements and fair value. Test pricing, conversion, receipt retries, regional/age eligibility and refund/support processes. Do not optimize only short-term spend at the expense of player trust. **Evidence:** economy spreadsheet, receipt test logs, conversion cohorts. **Sources:** Roblox monetization and policy docs.

## 7. Discovery, marketing and community
Communicate the game's promise in title, thumbnail and first 30 seconds. Run small tests of creatives and channels; align promotion with actual retention. Establish safe community management, creator partnerships and a repeatable content cadence. **Evidence:** campaign attribution, join funnel, cohort retention and player feedback. **Sources:** Roblox promotion and analytics.

## 8. Analytics, experimentation and LiveOps
Define event taxonomy before launch, with activation, D1/D7/D30 retention, session quality, payer conversion, ARPDAU and failure rates. Use hypotheses and guardrail metrics; compare cohorts, not only aggregate trends. Plan incident response and content rollback. **Evidence:** dashboards, experiment notes, post-release review.

## 9. Testing, security, performance and policy
Automate deterministic checks; manually verify multiplayer, purchases, moderation and device behavior. Budget frame-time, memory and network use. Review child safety, IP, UGC and regional rules. **Evidence:** revision-specific PASS/FAIL matrix, exploit test notes, content review. **Tools:** TestEZ, Selene, Studio profiler, official safety guidance.

## 10. AI agents, skills and MCP
Give agents narrow scoped tasks, the current official docs, tool permission boundaries and explicit acceptance criteria. Prefer official Roblox Studio MCP for interactive editing and authorized terminal tools for CLI. Verify actual output in Studio; require review before publishing or spending. **Evidence:** tool capability matrix, diff, test outputs and approval. **Sources:** Studio agent plugin, AI docs indexes, Engineering-OS routing.

## Selection rule

For any requested feature, consult its primary domain **and adjacent domains** (e.g. shop → UI + receipts + persistence + policy + analytics). Use the [tool catalog](TOOL-CATALOG.md) to identify relevant sources and interfaces; do not load all documentation into context.
