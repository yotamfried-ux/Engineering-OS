# Sales & marketing agent loop — verified tool list and bounded architecture

**Reel:** https://www.instagram.com/reel/DgCYbIeAt69/ (full transcript obtained on 2026-11-25). Creator claims 56 agents; their private blueprint and proof of deployment were **not** provided. This document records the **named vendor services**, not a recreated or proven 56-agent system.

## Named services and capability roles

| Stage | Vendor named in Reel | Role | Installation status |
|---|---|---|---|
| Market signals | [Google Trends](https://trends.google.com/) | Trend discovery | External provider; no credential/connector verified |
| Market/SEO signals | [Semrush](https://www.semrush.com/) | Topic, keyword and competitor research | External paid service |
| Audience research | [SparkToro](https://sparktoro.com/) | Audience interests and sources | External service |
| Reasoning/copywriting | [Claude Code](https://code.claude.com/docs/en/overview) | Drafting and orchestrating | Host-side CLI required |
| Visual generation | [Higgsfield](https://higgsfield.ai/) | Visual/media creation | External generation service; costs/permissions need review |
| Programmatic rendering | [Remotion](https://www.remotion.dev/) | React-driven short video rendering | **Installable**: `remotion-agent-skills` plus explicit `remotion-project` |
| Social publishing/analytics | [Metricool](https://metricool.com/) | Channel scheduling | External service; posting needs owner authorization |
| Messaging/DM automation | [ManyChat](https://manychat.com/) | Inbound channel conversations | External service; platform policy and opt-ins required |
| Call attribution | [CallRail](https://www.callrail.com/) | Phone lead source tracking | External service; phone data/privacy permissions |
| CRM | [HubSpot](https://www.hubspot.com/) | Lead records, qualification, hand-off | External account; never automate unsolicited sending |
| Booking | [Calendly](https://calendly.com/) | Appointment slots | External account; links not assumed to be API access |
| SMS confirmation | [Twilio](https://www.twilio.com/) | Compliant transactional texts | External account, verified phone sender, consent and charges |
| Deal analytics | [Looker Studio](https://lookerstudio.google.com/) | Closed-deal dashboard | Connected data sources, permissions and reliable attribution |
| Tool protocol | [MCP](https://modelcontextprotocol.io/) | Tool invocation interface | Standard, not a service or API credential itself |

## Loop with stopping points

1. Approved brief and constraints: explicit target segment, brand voice, privacy, offer, budgets, prohibited sources and allowed channels in versioned project files.
2. Discover potential topics from authorized research feeds, store source URL and timestamp.
3. Claude drafts content and visual brief; a human or policy gate approves spending and claims.
4. Remotion renders approved media, preserving media asset provenance.
5. Publish **only after explicit approval**, using account-scoped vendor connectors and consent rules.
6. CRM/calls/forms/DMs receive opted-in inbound data; deduplicate and qualify, never invent contact details.
7. Bookings and transactional messages occur only under user permissions and platform law. Human signs off quotes/contracts and sends where required.
8. Dashboard joins outcomes to channels, then feeds aggregate performance (not sensitive raw identities) into the next planning cycle.

## Qualification gates

Each external vendor must have: legitimate ownership, API documentation and supported connector, scoped read/write permission, sandbox or synthetic sample, verified limits/costs, opt-out/compliance controls, error/retry and audit log, and independent end-to-end live evidence. A transcript naming a service cannot authorize access.

Use `patterns/ai/sales-marketing-agent-workflow.md` for the architectural pattern; `docs/product-experience/saas-conversion-and-retention-reel.md` for the measurement/retention logic.

## Separate private lead-finder Reel

https://www.instagram.com/reel/Dfpm8EmTjKx/ describes a private `/lead finder` Claude skill with scraper, profile builder, email finder and sender. No authenticated canonical source or license was supplied. **Do not install or imitate mass scraping of restricted profiles or bulk unsolicited email**. An internal implementation should restrict itself to permitted public business information, consent, opt-outs and reviewable drafts.
