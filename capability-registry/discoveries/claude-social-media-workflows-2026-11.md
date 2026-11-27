# Claude for social media: workflows, MCP publishers and skill packs (discovery, 2026-11-27)

**Status: REFERENCE ONLY.** Nothing here is installed or qualified. Tool entries are candidates; none was run. Claims made by video creators and vendors are marked as such and are not verified facts.

Requested by Yotam for the Director repo (`yotamfried-ux/Director`, social-manager / social-content skills). Director rules still win: nothing is published without per-action approval, no invented claims, demo data labelled.

## How this was gathered (and limits)

- Searched YouTube through web search for videos about using Claude / Claude Code / Claude Cowork for social content.
- The cloud workspace cannot reach YouTube (proxy 403 for `yt-dlp`, `WebFetch` fails), so `mcp-video-analyzer` and `external-skills/watch-video/` could **not** be run there. Transcripts were read from the YouTube transcript panel in the person's built-in browser instead. This is a manual route, not a qualified capability.
- **Transcripts actually read:** 4 videos (table below). `zFM5elMy5Do` was read only for the first ~11,000 of ~36,700 characters.
- **Seen by title/description only (not watched):** `DnBtU1-g7P8`, `oFTA27l_TO4`, `gvcOOj3FhoM`, `CeJAGpP3XGs`, `gL7URBrih2I`, `Mo4K3pHk7E8` (transcript panel never loaded), `WvuLxxDY37U`, `eKlfHcjhOMg`, `uK6p4gAV8zU`, `GQfayD4FUg0`, `LqfRe6q9Fok`, `05jVpXv9iMU`, `hpbXMpi4R0A`. Treat as leads.
- Browser-route gotchas: a pre-roll ad blocks the page until skipped; the "Show transcript" button sits behind the description "...more"; a hidden browser pane throttles timers and scripts time out.

## Videos with transcripts read

| ID | Title | What it contributes |
|---|---|---|
| `pu72TSWJp4g` | How I Automated Social Media Content With Claude (Full Walkthrough) | Small-business case, 8 min |
| `xb-nlHih0qc` | How to Use Claude for Instagram (Without Posting AI Slop) | Five-phase workflow with approval point |
| `9oFqIJX43H8` | Make Viral Instagram Reels Using Claude (Step By Step) | Idea inbox to scheduled post, human in the loop |
| `zFM5elMy5Do` | How I Automate 90% of My Social Media Content with Claude Code (partial) | Agent "content team", outlier research, hook formula |

## Transferable practices (creator-reported)

1. **Written content rules before generation.** A mix (about 50% benefits, 25% lifestyle, 25% offer), a day-by-day rhythm, a "never do" list (no false claims, no AI-generated people or scenes), and a "must do" list, kept as files Claude re-reads. Source: `pu72TSWJp4g`.
2. **Asset inbox with a used/unused ledger.** Real photos go into a folder; Claude tracks which were used and asks for more when it runs low. Source: `pu72TSWJp4g`.
3. **Plan as a table, then pick.** Ask for a 7-day plan (format, caption idea per day), then ask which post is most likely to earn saves/shares and why, and push back on it. Source: `xb-nlHih0qc`.
4. **Reusable brand templates built once** (Canva brand template, filled by Claude) so each format is a fill-in. Claude could not export files itself; a human step remained. Source: `xb-nlHih0qc`.
5. **Drafts as the approval point.** Posts land as drafts/ideas in the scheduler; the human edits the caption to their voice before scheduling. Source: `xb-nlHih0qc`, `9oFqIJX43H8`.
6. **Weekly performance debrief closes the loop:** bring the numbers back, ask what to cut and double down on. Source: `xb-nlHih0qc`.
7. **Analyze style, format, pace and on-screen content of reference posts, not only their transcript**, then write original scripts for your niche from a niche/ICP document. Source: `9oFqIJX43H8`.
8. **Human keeps taste and the camera;** Claude does research, drafts, captions, scheduling. The creator lets Claude learn from the human's edits. Source: `9oFqIJX43H8`, `xb-nlHih0qc`.
9. **Intro formula:** strong hook that names the viewer, the opportunity they miss, then a promise of value; extract formulas from outliers rather than copying scripts; store reference vs. adapted version side by side in a sheet. Source: `zFM5elMy5Do`.
10. **Secrets belong in `.env`** (reason the creator preferred Claude Code over Cowork for API-key work). Source: `zFM5elMy5Do`.
11. **A/B cadence test** (one vs. two posts a day) judged on engagement, not follower count alone. Source: `pu72TSWJp4g`.

Unverified platform claims repeated in `xb-nlHih0qc` (verify against Instagram/Meta sources before use): sends and saves outweigh likes; reposting the same content more than 10 times in 30 days drops it from recommendations.

## Candidate tools (none installed or run)

| Candidate | What it is (vendor/listing statement) | Notes for Director |
|---|---|---|
| Metricool MCP (official; `https://ai.metricool.com/mcp`) | Schedule, analytics, best posting times, competitor review for ~10 networks; listed as an official Claude connector; works on any Metricool plan including Free | Possible read-only analytics / best-time source. Adds a third-party scheduler dependency; Director already publishes through Meta Graph via n8n with an approval gate |
| Buffer MCP, SocialPilot MCP, Planoly MCP | Hosted scheduler MCPs | Comparison page: https://www.socialpilot.co/best-social-media-mcp-tools (vendor-authored) |
| Blotato MCP (`https://mcp.blotato.com/mcp`) | Paid, 9 platforms | Starting plan is paid per the vendor page |
| `pendpost/pendpost` | Open source (MIT), agent drafts, human approval gate controls publishing | Very small project (9 stars at listing time); reference design only |
| `helbertparanhos/postforme-mcp-pro`, `postmcp/postmcp-mcp-server`, SocialClaw, Socialync, Atlas Social (needs a Zernio account) | Cross-posting MCP servers | Third-party hosted APIs; review data handling before any use |
| Self-hosted Instagram/Facebook MCP on Meta Graph (listing: https://glama.ai/mcp/servers/c0qkfghfty) | Posts photos, carousels, Reels, schedules, analytics, "autopilot" two-week plans | Same API Director already uses; review its autopilot against the approval rule |
| Remotion | Video editing by Claude Code | Already Director's renderer |
| Poppy AI | Paid tool that analyzes saved reels | Paid; alternative is the video analyzer route above |

## Candidate skill packs (copy only after review; check licence)

| Pack | Content |
|---|---|
| `sergebulaev/instagram-skills` | 9 Instagram skills: hooks, captions, 10-slide carousel planner, hashtags, humanizer |
| `charlie947/social-media-skills` | 17 skills, mainly LinkedIn-oriented plus Instagram/X |
| `coreyhaines31/marketingskills` (`social`) | Already vendored in Director as `mkt-*`; see Director `third_party/NOTICE.md` |
| `marcolang/Marketing-Skills`, `borghei/Claude-Skills` (`social-content`) | Smaller collections |

Skill packs are untrusted third-party instructions: review the text, do not auto-install, and let Director rules override them.

## Applicability to Director (suggestions, not decisions)

- Already matched: human approval gate, real photos/real claims rule, weekly review (`ig-audit`), Remotion renderer.
- Gaps worth considering: (a) an asset inbox with a used/unused ledger for photos and clips; (b) an explicit weekly "cut / double down" debrief file fed by Meta insights; (c) reference-post analysis (format, pace, on-screen text) using the video analyzer once it is qualified on a host that can reach the source; (d) reference vs. adapted hook table; (e) optional read-only Metricool analytics only if Meta insights prove insufficient.

## Decisions (2026-11-27, for Director)

Nothing was installed or vendored from outside. Reasons are stated so the decision can be revisited.

| Candidate | Decision | Reason |
|---|---|---|
| Practices 1-9 above | **ADOPTED in Director** | Implemented as `business/social/rules.md`, `Director's asset-ledger script` (asset ledger), `Director's debrief script` (weekly candidates with denominators), `business/social/hooks.template.md`, updated `social-manager` skill and marketing charter; covered by `tests/social.test.mjs` |
| `sergebulaev/instagram-skills` (MIT, 9 skills) | **ADOPTED: two skills, trimmed** (2026-11-27, Yotam approved) | Hook Extractor and Humanizer vendored into Director (`ig-hook-extractor`, `ig-humanizer`, commit 823c681) after a file-by-file review. Removed: Apify read layer, Python `lib/` (Publora/Pixfaro/Apify), illustration and voice-profile sub-skills. No network, posting or token use remains. Humanizer wording lists are English-only (Hebrew uses the structural checks only); the corpus statistics are the upstream author's and unverified. Other skills overlap the existing `ig-*` set and stay unvendored |
| `charlie947/social-media-skills` (MIT, 17 skills) | **REFERENCE ONLY** | LinkedIn-centred; `reels-scripting` needs Apify and Gemini keys; overlaps existing skills. Ideas (post-scorer against own history, content-matrix) are already covered by the debrief and rules file |
| `coreyhaines31/marketingskills` | Already vendored (`mkt-*`) | No change |
| Metricool MCP | **NOT NOW** | Adds a third-party scheduler; Director publishes through Meta Graph in n8n with an approval gate and reads Insights directly. Revisit only if Meta Insights lacks best-time or competitor data |
| Buffer, SocialPilot, Planoly, Blotato, Post for Me, PostMCP, SocialClaw, Socialync, Atlas Social | **REJECTED for now** | Each puts a hosted third party (and its API key) between Director and the networks, with no gap in what Meta Graph already gives |
| `pendpost` | **REFERENCE ONLY** | Useful design (human approval gate) but a very small project |
| Self-hosted Instagram/Facebook MCP on Meta Graph | **REJECTED for now** | Same API Director already uses through n8n; its "autopilot" queueing conflicts with per-post approval |
| Poppy AI | **REJECTED** | Paid; the video analyzer route covers reference analysis once it runs on a host that reaches the source |
| Video transcript services (e.g. via Composio) | **NOT CONNECTED** | Paid third-party account needs Yotam's explicit approval |

## Sources

- https://www.youtube.com/watch?v=pu72TSWJp4g
- https://www.youtube.com/watch?v=xb-nlHih0qc
- https://www.youtube.com/watch?v=9oFqIJX43H8
- https://www.youtube.com/watch?v=zFM5elMy5Do
- https://metricool.com/metricool-mcp-claude/
- https://help.metricool.com/how-to-connect-metricool-mcp-with-claude-0l84v.md
- https://www.blotato.com/mcp
- https://enterprisedna.co/directories/mcp/pendpost-pendpost
- https://github.com/charlie947/social-media-skills
- https://claudemarketplaces.com/plugins/sergebulaev-instagram-skills/instagram-skills
- https://claude-plugins.dev/skills/@coreyhaines31/marketingskills/social


## Follow-up (2026-11-27)
Yotam set 3 posts per day with one daily batch approval and staggered publishing slots to test posting times. Director added slot rotation and a slot-aware debrief (confounded with content, 'no signal' below 10 posts per slot) and a scheduled n8n queue publisher that only publishes rows Yotam approved. Status: READY pending activation; real publish through it NOT TESTED.