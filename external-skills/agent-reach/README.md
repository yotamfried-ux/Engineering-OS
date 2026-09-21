# Agent Reach

**Canonical upstream:** `Panniantong/Agent-Reach`

Agent internet-access layer that routes supported platforms through maintained primary/fallback backends and exposes installation plus diagnostics to coding agents. Current upstream covers web/social/video/code sources and provides `agent-reach doctor` to report actual channel health.

## Use when
Use when an agent needs reusable read/search access across several public internet platforms and maintaining a separate scraper/tool integration per platform would waste time and context.

## Safe activation
Start with upstream's read-only environment check. System dependency installation must remain an explicit host change. After installation, run the upstream doctor command and record which channels/backends actually pass rather than assuming every advertised source is usable.

## Credentials
Some platforms require browser login/cookies. Treat cookies as credentials; keep them local, minimize account privilege, and never commit them to the knowledge library.

**Status:** READY AS KNOWLEDGE / CHANNEL-AND-HOST-DEPENDENT.
