# Instagram reel — full software alternatives and activation gates

**Source:** https://www.instagram.com/reel/DgJoi_Rh4av/ — verified video transcript and independently located upstream projects (2026-11-25).

These are nine *different full applications*, **not nine agent skills**. They are optional project/service dependencies, not globally available commands. Installing all on a production host merely to mark a registry READY would be resource-intensive, could introduce vulnerabilities and may require paid API accounts. Do not auto-deploy or expose to the public network as part of the core or reel skill profiles.

| Discovery name | Canonical project | Deployment scope | Gate before READY |
|---|---|---|---|
| OpenWhispr | https://github.com/OpenWhispr/openwhispr | Desktop audio recorder; Windows/macOS/Linux | Native supported desktop, microphone permission, local ASR/model tests |
| Open-Generative-AI | https://github.com/Anil-matcha/Open-Generative-AI | Generative-video web frontend | Third-party Muapi.ai key, API cost, legal/license check, sample job; **not entirely free computation** |
| Cal.diy | https://github.com/calcom/cal.diy | Self-hosted scheduling app | Isolated Docker stack, persistent DB, calendaring credentials, auth, mail, TLS, booking smoke |
| Chatwoot | https://github.com/chatwoot/chatwoot | Customer-service web app | Redis/Postgres, persistent storage, SMTP, TLS, authentication, message send/receive smoke |
| AppFlowy | https://github.com/AppFlowy-IO/AppFlowy | Desktop collaborative workspace / optional cloud | Choose client versus self-hosted cloud, auth, storage, backups, sync tests |
| Cap | https://github.com/CapSoftware/Cap | Desktop recording and sharing | Native screen-recording permissions, local recording/export test; optional cloud storage |
| OpenSEO | https://github.com/every-app/open-seo | SEO research app | Data/API provider, valid API keys/limits and meaningful SEO-query test |
| VoiceStudio | https://github.com/debpalash/VoiceStudio | Local voice app/API; may use large models | GPU/CPU/RAM/storage, model downloads, voice rights and consent, voice sample test |
| OpenProject | https://github.com/opf/openproject | Project management web service | Dedicated Docker Compose deployment, DB/storage/backups, SMTP/auth, TLS, test project |

## Official deployment references

- OpenProject: https://www.openproject.org/docs/installation-and-operations/installation/docker-compose/
- Chatwoot: https://www.chatwoot.com/deploy
- AppFlowy: https://appflowy.com/docs/Local-Host-Deployment
- OpenWhispr: https://github.com/OpenWhispr/openwhispr#readme
- Cal.diy: https://github.com/calcom/cal.diy#readme
- OpenSEO: https://github.com/every-app/open-seo#readme
- VoiceStudio: https://github.com/debpalash/VoiceStudio#readme

## Availability and limitations

All nine entries are **CONDITIONAL / NOT INSTALLED / NOT PRODUCTION QUALIFIED** pending host selection and prerequisites. None should be silently installed into the user's existing n8n/Postgres/Caddy production stack. Alternative tools do not guarantee parity with the paid services shown in the Reel.

For safe, already executable utilities, use the **bundled Openverse audio search** and **React Bits project installer** from the central manifest. For agent skills, use the opt-in `reels-*` profiles.
