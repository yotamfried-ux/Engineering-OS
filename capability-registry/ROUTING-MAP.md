# Engineering-OS Routing Map

Use this map for progressive disclosure: route by **job**, then open only the relevant knowledge.

| Need | First stop | Then inspect | Evidence/exit condition |
|---|---|---|---|
| Build, test, launch or grow a Roblox game | `docs/roblox/README.md` | `docs/roblox/GAME-DEVELOPMENT-MASTER-GUIDE.md`; task-specific engineering, art, monetization, MCP/skills guides | prototype, authoritative source checks, device/multiplayer tests, safety and launch evidence |
| Build a customer-facing app or website | `docs/product-experience/README.md` | `templates/`, `patterns/`, architecture, accessibility, privacy and testing routes as relevant | design rationale + representative UX/technical evidence |
| Design premium UI, motion or 3D experiences | `docs/product-experience/premium-motion-and-design-systems.md` | platform design systems, performance and accessibility guidance | responsive prototype + reduced-motion and performance review |
| Design system messages, notifications, reminders or transactional communication | `docs/user-messaging/README.md` | `docs/user-messaging/MASTER-GUIDE.md`; appointment/CRM, games, delivery, content, testing guides as relevant | event/recipient matrix, accessible copy, reliable delivery and scenario-specific evidence |
| Write or improve human customer-facing text | `docs/product-experience/human-centered-ux-writing.md` | product voice, content design and UX research as relevant | clear, accurate, accessible copy matched to context |
| Improve onboarding, forms, conversion or usability | `docs/product-experience/ux-research-conversion.md` | product analytics guide + research and accessibility references | user journey + hypothesis + usability evidence |
| Acquire first customers, plan founder outreach or set early SaaS pricing | `external-skills/minimalist-entrepreneur/README.md` (catalog only) | `docs/product-experience/analytics-experimentation-growth.md`; upstream skill files after security/license review | evidence-backed prospects, manual approval before outreach, validated unit economics; no automatic installation |
| Measure growth, retention or experiment on conversion | `docs/product-experience/analytics-experimentation-growth.md` | UX research + privacy/compliance + instrumentation | event taxonomy, baseline and experiment interpretation |
| Build a new application/system | `templates/` | `patterns/`, architecture guides, framework docs, reference repos | chosen architecture + implementation-specific tests |
| Choose architecture | `docs/architecture-guides/` | `architecture-decisions/`, relevant reference repos | explicit trade-offs and target constraints |
| Delegate/parallelize work or choose model cost | `EXECUTION-FAST-PATH.json` | `EXECUTION-FAST-PATH.md` only if explanation is needed | bounded workers + explicit cost class + deterministic verification |
| Run local/open model work | `EXECUTION-FAST-PATH.json` | Ollama + compatible orchestration/agent assets | model/runtime/hardware qualified + task-quality evidence |
| Add/use an agent capability | `capability-registry/agent-tools.md` | matching `external-skills/<tool>/` | installation/connection verified before dependence |
| Reduce tokens/context | `token-context-efficiency.md` | RTK, Graphify, memory tools | measured/observed benefit on the target workflow |
| Connect external data/service | `connectors.md` | `external-systems/`, connector wrapper | auth + representative read/write action as applicable |
| Write/choose a fast code test | `patterns/testing/FAST-PATH.json` | `patterns/testing/FAST-PATH.md` only if a skeleton/explanation is needed | smallest deterministic test that can falsify the claim |
| Test web app | `application-testing/README.md` | Playwright, Chrome DevTools, testing knowledge map | capability matrix with evidence |
| Test mobile app | `application-testing/README.md` | Maestro/Appium/Mobile Next + platform docs | build/install/launch + user journey + authoritative side effects |
| Qualify whole project | `patterns/testing/project-qualification.md` | authoritative testing sources + templates | PASS/FAIL/PARTIAL/BLOCKED/NOT TESTED matrix |
| Stress-test a business idea with simulated buyer personas | `external-skills/founder-skill/README.md` (catalog only) | real customer discovery + product analytics guide | hypotheses only; validate with actual customers |
| Prevent double booking, overselling or concurrent state corruption | `patterns/security/race-conditions-and-atomic-booking.md` | PostgreSQL and OWASP | enforce database invariants and test concurrent requests |
| Coordinate a specialized AI game-development team | `capability-registry/discoveries/game-studios-and-agent-reach.md` | game-development and orchestration guides | compare roles, costs and tests before adoption |
| Read social platforms or video links with an agent | `capability-registry/discoveries/game-studios-and-agent-reach.md` | existing video URL analyzer and browser tooling | verify supported access; no auto-install |
| Choose React UI motion/component libraries | `docs/product-experience/ui-library-candidates-2026.md` | premium motion guide | verify identity, licensing and accessibility |
| Review GDPR, cookies and personal-data consent | `docs/product-experience/gdpr-official-guidance.md` | legal/privacy docs, EDPB and EUR-Lex | lawful-basis and jurisdiction review, actual tracker tests |
| Evaluate autonomous penetration testing | `patterns/security/pentagi-candidate.md` | OWASP ASVS/WSTG and security qualification | authorized isolated test, sandbox and version verification |
| Stress-test a business idea with simulated buyer personas | `external-skills/founder-skill/README.md` (catalog only) | real customer discovery + `docs/product-experience/analytics-experimentation-growth.md` | hypotheses and objections only; validate with actual customers, no forecast or auto-install |
| Prevent double booking, overselling or concurrent state corruption | `patterns/security/race-conditions-and-atomic-booking.md` | PostgreSQL transaction/locking documentation; OWASP business logic testing | database invariant enforced + adversarial simultaneous requests pass on real DB |
| Coordinate a specialized AI game-development team | `capability-registry/discoveries/game-studios-and-agent-reach.md` | existing Roblox/game-development and orchestration guides | compare roles, costs and engine tests before adoption |
| Read social platforms or video links with an agent | `capability-registry/discoveries/game-studios-and-agent-reach.md` | existing video URL analyzer and browser tooling | supported authenticated access verified; no automatic installation |
| Choose React UI motion/component libraries | `docs/product-experience/ui-library-candidates-2026.md` | premium-motion-and-design-systems guide | upstream identity, license, accessibility and reduced motion verified |
| Review GDPR, cookies and personal-data consent | `docs/product-experience/gdpr-official-guidance.md` | legal/privacy docs and official EDPB/EUR-Lex | processing map, jurisdiction review and actual tracker tests |
| Evaluate autonomous penetration testing | `patterns/security/pentagi-candidate.md` | OWASP ASVS/WSTG + existing security qualification route | authorization, isolated target, sandbox and version attestation |
| Segment and track objects in sports videos | `capability-registry/discoveries/sam3-sports-vision.md` | Meta SAM 3 upstream; ground truth validation | accuracy, identity, latency, licensing and cost verified |
| Learn reinforcement learning with LunarLander | `docs/ai/reinforcement-learning-lunarlander.md` | Gymnasium and Stable-Baselines3 official docs | reproducible reward and held-out evaluation |
| Evaluate repository knowledge graphs for token reduction | `capability-registry/discoveries/graphify-code-knowledge.md` | verified upstream pending; existing code navigation | full-cost benchmark and source identity verified |
| Audit seven basic web security failure modes | `patterns/security/web-app-seven-basics.md` | OWASP, Supabase and MDN | server-side authorization and transport evidence |
| Research open robot imitation learning and simulation | `capability-registry/discoveries/open-robotics-sourccey.md` | MuJoCo, LeRobot, Raspberry Pi | maker repo/license and simulation validation |
| Optimize App Store and Play Store listings | `docs/product-experience/app-store-listing-optimization.md` | Apple/Google developer docs | compliant store assets and measured conversion |
| Learn circuit-board and PCB design | `docs/hardware/pcb-design-primary-sources.md` | KiCad official docs | ERC/DRC and manufacturing/safety review |
| Security qualification | `patterns/security/README.md` | OWASP + CodeQL/SCA/secrets/config/DAST/mobile tools | scoped security evidence + residual gaps |
| Android/Google Play readiness | `release-readiness/google-play.md` | Android reference repos + mobile/security testing | exact build/release evidence + current Play requirements |
| Inspect generated/pipeline video output | `video-analysis/mcp-video-analyzer.md` | focused moment/frame/burst analysis; then pipeline logs/code/tests | visual defect + timestamp/frame evidence + rerun comparison |
| Analyze public/social video URL | `video-analysis/video-url-analyzer-mcp.md` | `video-analysis/mcp-video-analyzer.md` or `external-skills/watch-video/` when local extraction is preferable | visual question + timestamp/frame evidence |
| Create, revise, or inspect a 3D asset | `3d-asset-generation/README.md` | `3d-asset-generation/kiln.md`; then authoritative DCC/engine validation | representative asset generated/revised + downstream open/validation evidence |
| Browser automation/research | `external-skills/browser-use/` | Playwright for deterministic qualification; Page Agent for in-page UI agent use | result + target-specific verification |
| Internet/social retrieval | `external-skills/agent-reach/` | provider/channel docs | diagnostics show requested channel is live |
| Memory across sessions | `token-context-efficiency.md` | claude-mem, agentmemory, OpenViking | retrieval/update/deletion behavior verified |
| Autonomous coding agent | `agent-tools.md` | OpenHands/Hermes/host-native agent tools | bounded task + diff + tests + sandbox review |
| Local typed decisions on Apple Silicon | `external-skills/laya-coreml/` | upstream Core ML docs/tests/benchmarks | representative local decision + target-host evidence |
| Voice/audio capability | `external-skills/voicebox/` | upstream docs | representative local I/O verified |
| WhatsApp automation | `external-systems/open-wa/` | official WhatsApp/Meta route when appropriate | authorized account + representative safe action |
| Debug known failure | `docs/troubleshooting/` | lessons + failed-solutions | reproduced cause + regression evidence |
| Scientific/research workflow | `external-skills/scientific-agent-skills/` | authoritative domain sources | citations/data provenance + domain validation |

## Cross-domain routing examples (advisory)

- “Build a booking app”: combine application architecture, UX flows, accessible forms, privacy, security, instrumentation and testing as the actual scope warrants.
- “Create a startup-quality landing page”: prioritize brand/art direction, typography, purposeful motion, mobile performance, accessibility and conversion clarity; do not assume animation improves sales.
- “Increase checkout conversion”: prioritize user research, analytics validity, checkout friction, pricing transparency and experiment design; do not start with arbitrary color changes.
- “Fix a backend API timeout”: prioritize troubleshooting, architecture and regression testing; skip marketing and motion docs unless relevant.

This is an **index and decision aid**, not a runtime router. No hooks, automated triggers, forced tool execution or universal requirement to open every branch. Existing independent policies still apply.

## Selection rules

1. Before spawning agents, use `EXECUTION-FAST-PATH.json` and prefer deterministic/no-model or qualified local execution when it meets the evidence bar.
2. Prefer an already available, authorized native capability over installing a duplicate.
3. Prefer official docs/standards for claims about behavior, security, release requirements and APIs.
4. Prefer deterministic framework-native tests for qualification; exploratory agent tools complement them.
5. Use community catalogs as discovery sources, not as final authority.
6. Do not load an entire corpus when one branch answers the task.
7. If two tools overlap, choose based on the target job and constraints; do not install both merely because both exist.
