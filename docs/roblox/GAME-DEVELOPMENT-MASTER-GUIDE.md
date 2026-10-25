# Roblox game development — master guide for AI agents

**Purpose:** task-based, end-to-end research and delivery map, not a substitute for Roblox's current documentation or a mandatory execution hook.

Official starting points:
- [Roblox Creation overview](https://create.roblox.com/docs/creation)
- [Creator Hub](https://create.roblox.com/docs)
- [Game design](https://create.roblox.com/docs/production/game-design)
- [Official source documentation repository](https://github.com/Roblox/creator-docs)
- [AI workflows and Studio MCP](https://create.roblox.com/docs/ai/accelerated-workflows)

## Agent procedure

1. Identify target audience, device mix, genre, age suitability, budget, schedule, team, differentiation and success criteria.
2. Select relevant branches below; read only those sections and linked sources. Check current official policies and API behavior before implementation.
3. Produce a brief PRD: player promise, core loop, onboarding, progression, social mechanics, economy, content plan, anti-abuse assumptions and measurable goals.
4. Prototype the fun and mobile controls before building complex systems; validate with actual players.
5. Design client/server trust boundaries, data persistence, remote validation, network ownership, abuse prevention, observability and failure recovery.
6. Plan asset pipeline, UX, accessibility, audio, animation, device compatibility and performance budgets.
7. Define monetization ethically: product types, pricing, purchase confirmation, receipt idempotency, regional/age policy, economy sinks/sources and no deceptive pressure.
8. Instrument acquisition → activation → retention → conversion; interpret cohorts and experiments, not only raw visits.
9. Run deterministic tests, multiplayer playtests, device/performance profiling, moderation/policy and release reviews.
10. Publish with explicit approval; monitor live issues, retention, revenue, abuse, moderation and content cadence; iterate using evidence.

## Cross-domain research routes

| Phase | Investigate | Primary guide | Evidence |
|---|---|---|---|
| Opportunity | competitor mechanics, audience, discoverability, feasibility | [Design/business](DESIGN-GROWTH-MONETIZATION.md) | competitor matrix + testable hypothesis |
| Product | core loop, tutorials, progression, balance, social features | [Design/business](DESIGN-GROWTH-MONETIZATION.md) | playable prototype + user observations |
| Engineering | Luau, server authority, remotes, DataStores, matchmaking, recovery | [Engineering](ENGINEERING-AND-TOOLS.md) | architecture, threat model, automated tests |
| Art/experience | Blender, 3D, lighting, audio, animation, HUD, localization | [Art/UX](ART-UX-AND-PRODUCTION.md) | device screenshots + usability/perf evidence |
| Business | passes, developer products, subscriptions, ads, rewards, DevEx eligibility | [Design/business](DESIGN-GROWTH-MONETIZATION.md) | policy review + revenue assumptions |
| Launch | publishing, privacy, content maturity, moderation, QA, analytics | official Creator Hub + existing launch/security guides | signed-off qualification matrix |
| Growth | discovery, thumbnails, ads, influencers, retention, funnels | [Design/business](DESIGN-GROWTH-MONETIZATION.md) | cohort and campaign analysis |
| Operations | live events, releases, experiments, incident response | existing testing/operations knowledge | change log + observed outcomes |

## Task-specific routing

- “Build an inventory” → Luau/server validation + persistent data + UX + exploit testing.
- “Add purchases” → official monetization + receipts + persistence + policy + analytics.
- “Create a simulator” → game loops + economy balancing + anti-exploit + retention + performance.
- “Make a lobby” → matchmaking/teleport + networking + mobile UI + multiplayer testing.
- “Improve revenue” → retention/cohorts first; investigate pricing and product fit; no guaranteed ROI claims.
- “Use an AI agent” → [MCP/skills](MCP-AND-SKILLS.md), tool permissions and actual Studio connectivity.

## Exit criteria

Report PASS / FAIL / PARTIAL / BLOCKED / NOT TESTED separately for code, multiplayer, data recovery, device UI, performance, safety, policy, purchase flow and analytics. Do not claim a production-ready game from static documentation alone.
