# User notifications in games and Roblox

Consult [Roblox knowledge index](../roblox/README.md), [Roblox safety](https://create.roblox.com/docs/safety), [Roblox Creator Hub](https://create.roblox.com/docs).

## Gameplay surfaces

- **Immediate feedback:** hit, quest progress, reward, unlock, inventory full, cooldown, insufficient resources — usually in-world/HUD, not interruptive modal.
- **Social:** party invite, friend joins, guild activity, trade requests — permission/anti-spam, mute/block and moderation-aware.
- **Operational:** connection lost, server maintenance, teleport failed, queue wait, matchmaking ready — clear retry/rejoin actions.
- **Account and safety:** moderation decisions, trade warnings, suspicious activity — precise language, no exposing sensitive details.
- **Commerce:** purchase pending/confirmed/failed, entitlement applied, subscription/benefit changes — server-verified, no false success.
- **LiveOps:** events, seasonal rewards, limited-time content, update announcements — frequency caps and honest deadlines.

## Design and engineering

Match urgency to interruption cost. Avoid disrupting combat or accessibility-critical moments. Respect device size, controller navigation, safe areas, audio-off and reduced motion. Keep gameplay rewards server-authoritative and notification content free from exploitable claims. Validate Roblox platform rules for chat, filtering, minors, off-platform links and paid mechanics. Don't assume arbitrary push/email channels are available to a Roblox experience; use documented platform capabilities only.

## Quality

Test high event rates, network loss, reconnect, language, screen reader/text alternatives where supported, cross-device HUD, cooldowns and moderation. Measure missed critical cues, player comprehension and annoyance, not just clickthrough.
