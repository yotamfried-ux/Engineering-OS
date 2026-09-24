# Engineering-OS Routing Map

Use this map for progressive disclosure: route by **job**, then open only the relevant knowledge.

| Need | First stop | Then inspect | Evidence/exit condition |
|---|---|---|---|
| Build a new application/system | `templates/` | `patterns/`, architecture guides, framework docs, reference repos | chosen architecture + implementation-specific tests |
| Choose architecture | `docs/architecture-guides/` | `architecture-decisions/`, relevant reference repos | explicit trade-offs and target constraints |
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

## Selection rules

1. Prefer an already available, authorized native capability over installing a duplicate.
2. Prefer official docs/standards for claims about behavior, security, release requirements and APIs.
3. Prefer deterministic framework-native tests for qualification; exploratory agent tools complement them.
4. Use community catalogs as discovery sources, not as final authority.
5. Do not load an entire corpus when one branch answers the task.
6. If two tools overlap, choose based on the target job and constraints; do not install both merely because both exist.
