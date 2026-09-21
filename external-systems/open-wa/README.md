# open-wa / wa-automate

**Canonical upstream:** `open-wa/wa-automate-nodejs`

Unofficial WhatsApp Web automation toolkit that can expose a WhatsApp account as an API, bot runtime, webhook source, plugin host and MCP/tool surface.

## Use when
Use only when a project explicitly accepts an unofficial WhatsApp Web automation path and needs capabilities beyond or instead of an official Meta integration.

## Version warning
Upstream currently identifies v5 as alpha and recommends stable v4 for mature production systems while testing v5 separately. Re-check this before every new integration.

## Risk
This project is not affiliated with WhatsApp/Meta. Account/session automation may carry Terms-of-Service, account-restriction and credential/session risks. Prefer official WhatsApp Business/Cloud API when it satisfies the product requirement.

## Qualification
Use a disposable/test account, protect exposed APIs, verify authentication, send/receive, reconnect/session persistence, webhook delivery/idempotency and logout/revocation. Never store session credentials in Engineering-OS.

**Status:** CONDITIONAL / UNOFFICIAL INTEGRATION.
