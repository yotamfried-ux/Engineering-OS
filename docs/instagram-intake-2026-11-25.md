# Instagram tool & principle intake — 2026-11-25

**Repository:** yotamfried-ux/Engineering-OS (NOT Improved-Engineering-OS).
**Input:** 19 distinct Instagram Reel URLs (including 3 added on 2026-11-25); one originally duplicated URL omitted.

## Evidence tiers
- **WATCHED:** vidIQ visual+spoken short-form breakdown, or browser-provided full video transcript. This verifies what the creator said/shown, **not that the claimed product result is true**.
- **CAPTION:** full public caption and page metadata only. Do not infer unnamed tools, visual demo steps, or exact private implementation.
- **UPSTREAM:** matched a developer's official GitHub project/docs independent of the Reel.
- **HOST INSTALL:** evaluated separately. The local Engine OS registry can install curated skills on demand, but user VM/Claude login and app deployments have **not** been verified in this chat.

## Source-by-source dispositions

| Instagram Reel | Evidence | Specific tool / principle | Integrated assets |
|---|---|---|---|
| [De7a_Gqk-sY](https://www.instagram.com/reel/De7a_Gqk-sY/) | WATCHED + transcript | Illustrative SaaS growth, activation, tests, retention, operating-cost gates | `docs/product-experience/saas-conversion-and-retention-reel.md` |
| [DgEveYmpH9H](https://www.instagram.com/reel/DgEveYmpH9H/) | CAPTION + upstream | Thinking Machines Inkling 2 Mini, local coding model; vendor benchmark unverified | `external-systems/inkling-2-mini/` (model/hardware conditional) |
| [DgHCSOKuchM](https://www.instagram.com/reel/DgHCSOKuchM/) | WATCHED + upstream | Lemomo `lemo-opuscar`, 99 code-rendered film styles | `lemo-opuscar` registered as real Claude plugin installer |
| [DgG3rhkNUzU](https://www.instagram.com/reel/DgG3rhkNUzU/) | CAPTION + official Anthropic sources | Scheduled/background Claude Code routines; precise four methods not recovered | `docs/official-docs/claude-code-routines.md` |
| [DgI9usSyEJG](https://www.instagram.com/reel/DgI9usSyEJG/) | CAPTION | Less cluttered, clearer sign-in design; exact demo unavailable | `docs/ui-ux/accessible-sign-in-and-interactions.md` |
| [DgJcVOdzDCB](https://www.instagram.com/reel/DgJcVOdzDCB/) | CAPTION + upstream | `msitarzewski/agency-agents` | Existing `external-skills/agency-agents/` asset; no new runtime installation verified |
| [DgJpifrheez](https://www.instagram.com/reel/DgJpifrheez/) | CAPTION + upstream | Corey Haines Marketing Skills | `marketing-skills` git-skills auto-installer |
| [DgJC0A4SF7B](https://www.instagram.com/reel/DgJC0A4SF7B/) | CAPTION/metadata | 21st.dev, React Bits and other design sources whose exact names are uncertain | `external-systems/21st-dev/`; executable `react-bits` project CLI |
| [DgJdC03AcSe](https://www.instagram.com/reel/DgJdC03AcSe/) | CAPTION + upstream | `sybil-solutions/skill-distill` | `skill-distill` git-skills installer; tmux + real student harness required |
| [DgJoi_Rh4av](https://www.instagram.com/reel/DgJoi_Rh4av/) | WATCHED + transcript | Nine open-source SaaS alternatives (OpenWhispr, Open-Generative-AI, Cal.diy, Chatwoot, AppFlowy, Cap, OpenSEO, VoiceStudio, OpenProject) | `external-systems/instagram-reel-service-candidates.md`, all 9 in registry as conditional/not deployed |
| [DgHepn5nDzl](https://www.instagram.com/reel/DgHepn5nDzl/) | CAPTION + partial forks | Harvey sales prospecting; canonical source identity not independently qualified | `external-systems/harvey/`, `patterns/ai/sales-marketing-agent-workflow.md` |
| [DfuKScLAOK-](https://www.instagram.com/reel/DfuKScLAOK-/) | CAPTION + upstream | Vercel UI SDK accessibility behaviors | `ui-sdk-agent` git-skills installer; `ui-sdk-react` npm project installer |
| [DfdAMRISFvs](https://www.instagram.com/reel/DfdAMRISFvs/) | CAPTION + upstream | `gamedev-skills/awesome-gamedev-agent-skills` 79 skills plus router | `gamedev-agent-skills` git-skills installer |
| [De90ttNOJbo](https://www.instagram.com/reel/De90ttNOJbo/) | WATCHED + Hebrew transcript | `preferences.md`, reference video, EyeCandy, Prompt Motion, React Bits, audio search, editable multi-track Studio | `docs/ui-ux/ai-video-editing-with-context-and-motion.md`, executable Openverse audio and React Bits helpers |
| [DgJncKIBPpN](https://www.instagram.com/reel/DgJncKIBPpN/) | WATCHED + transcript | Hallmark, Anatomy, ECC, Impeccable, Ponytail, Matt Pocock Skills, Cloudflare Security Audit | 7 executable installation entries, official upstream checked |
| [Df3YLvFCyDA](https://www.instagram.com/reel/Df3YLvFCyDA/) | Full transcript | One creator's LinkedIn 50-day content-format experiment; avoid outlier-driven causal conclusion | `docs/product-experience/linkedin-content-format-experiment.md` |
| [DgCYbIeAt69](https://www.instagram.com/reel/DgCYbIeAt69/) | CAPTION only | Creator's private 0-employee sales and marketing system; no public installable code identified | `patterns/ai/sales-marketing-agent-workflow.md`; do NOT invent an upstream |
| [DgKB_kXODn-](https://www.instagram.com/reel/DgKB_kXODn-/) | Detailed caption + upstream | Sahil Lavingia `slavingia/skills`, 10 Minimalist Entrepreneur skills | Existing `external-skills/minimalist-entrepreneur/` plus Claude plugin installer |
| [Dfpm8EmTjKx](https://www.instagram.com/reel/Dfpm8EmTjKx/) | Detailed caption | Private `/lead finder` workflow combining scraping, qualification, email discovery and outreach; no canonical source identified | `patterns/ai/sales-marketing-agent-workflow.md` only; never auto-send or scrape restricted data |

## Genuine install surfaces

- `capability-registry/INSTALL-PROFILES.json`: opt-in `reels-design`, `reels-engineering`, `reels-marketing`, `reels-media`, `reels-all`, `reels-react`, `reels-services`.
- `tools/eos_reel_install.py`: real canonical Git checkout and idempotent Claude Skill symlinking, conflict blocking and runtime checks.
- `tools/eos_capabilities.py`: existing central `ensure`, `status`, `setup` integration, official Claude plugin and project npm flows.
- `tools/openverse_audio_search.py`, `tools/reactbits_component.py`: executable bundled tools, with source/permission validation.
- `.github/workflows/eos-reel-capabilities.yml`: offline and upstream verification, plus isolated live host install smoke. CI runner setup is not a durable user-host deployment.

## Remaining blockers and honest status

1. **Nine full applications** require actual host-level provisioning/credentials and cannot be globally called READY just because their names were recognized.
2. **Inkling 2 Mini** requires verified hardware, model artifacts and runtime inference, not a CLI skill install.
3. **Harvey and private Reel systems** need exact maintainable source/licensing and security review before autonomous outreach.
4. **Certain videos** reveal categories/principles but not enough to reconstruct named/private tools; do not fabricate missing implementation.
5. **Host installation**: real installation remains to be run on an authorized persistent Claude Code host. A registry entry or CI pass is not evidence of installation on that host.

