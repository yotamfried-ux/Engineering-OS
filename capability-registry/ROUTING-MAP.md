# Engineering-OS Routing Map

Use this map for progressive disclosure: route by **job**, then open only the relevant knowledge.

| Need | First stop | Then inspect | Evidence/exit condition |
|---|---|---|---|
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
| Security qualification | `patterns/security/README.md` | OWASP + CodeQL/SCA/secrets/config/DAST/mobile tools | scoped security evidence + residual gaps |
| Android/Google Play readiness | `release-readiness/google-play.md` | Android reference repos + mobile/security testing | exact build/release evidence + current Play requirements |
| Analyze video/Instagram | `video-analysis/` | Video URL Analyzer MCP and `external-skills/watch-video/` | visual question + timestamp/frame evidence |
| Browser automation/research | `external-skills/browser-use/` | Playwright for deterministic qualification; Page Agent for in-page UI agent use | result + target-specific verification |
| Internet/social retrieval | `external-skills/agent-reach/` | provider/channel docs | diagnostics show requested channel is live |
| Memory across sessions | `token-context-efficiency.md` | claude-mem, agentmemory, OpenViking | retrieval/update/deletion behavior verified |
| Autonomous coding agent | `agent-tools.md` | OpenHands/Hermes/host-native agent tools | bounded task + diff + tests + sandbox review |
| Local typed decisions on Apple Silicon | `external-skills/laya-coreml/` | upstream Core ML docs/tests/benchmarks | representative local decision + target-host evidence |
| Voice/audio capability | `external-skills/voicebox/` | upstream docs | representative local I/O verified |
| WhatsApp automation | `external-systems/open-wa/` | official WhatsApp/Meta route when appropriate | authorized account + representative safe action |
| Debug known failure | `docs/troubleshooting/` | lessons + failed-solutions | reproduced cause + regression evidence |
| Scientific/research workflow | `external-skills/scientific-agent-skills/` | authoritative domain sources | citations/data provenance + domain validation |

## Navigation notes

This map is descriptive. It exposes likely starting points and overlapping
capabilities; it does not prescribe how an AI or human must execute a task.

- `EXECUTION-FAST-PATH.json` contains cost/capability metadata for execution options.
- Existing authorized capabilities can often avoid duplicate setup.
- `SOURCE-POLICY.md` records provenance tiers for readers who need to evaluate sources.
- Testing, agent and application-testing entries link to both deterministic and exploratory options.
- Community catalogs are discovery sources; official/canonical material is identified separately where available.
- Overlapping tools are intentionally preserved so the active worker can choose based on the task and environment.
