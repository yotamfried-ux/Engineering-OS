# Video URL Analyzer MCP

## Purpose

Give an AI agent direct multimodal analysis of supported video URLs, including public Instagram Reels/video posts, TikTok and YouTube. The server can analyze visual + audio content, transcribe speech, answer questions, locate moments, analyze segments, and extract frames/clips.

Upstream: https://github.com/u2n4/video-url-analyzer-mcp

## Status

**CONDITIONAL / NOT END-TO-END QUALIFIED — 2026-09-21**

The upstream project is active and publishes `video-url-analyzer-mcp` v1.5.4 with a FastMCP stdio server. Source inspection confirms real Instagram routing through page/scrape/yt-dlp download, Gemini Files upload, and multimodal analysis. Upstream tests include Instagram routing and ordered multi-file upload cases.

Do **not** mark this capability LIVE solely from this wrapper. During qualification, the upstream HEAD was `c33d3f652f785253241e7eda1fef75e02ce11d87`. The latest visible release-era CI matrix had a Python 3.12 `lint-and-build` failure (other matrix jobs were cancelled), even though the publish job succeeded. This environment also cannot launch arbitrary local MCP packages or supply a Gemini key, so an MCP initialize/tools-list plus real Instagram analysis was not executed here.

## Requirements

- Python >= 3.10
- `uv` recommended
- `GEMINI_API_KEY`
- Network access to the source video and Google Gemini
- ffmpeg for local frame/clip extraction paths
- Browser cookies are optional and disabled by default; login-gated/private Instagram content may require authorized cookies.

## Recommended launch

```bash
uvx video-url-analyzer-mcp
```

### Claude Code

```bash
claude mcp add video-analyzer --transport stdio -- uvx video-url-analyzer-mcp
```

### Generic MCP configuration

```json
{
  "mcpServers": {
    "video-analyzer": {
      "command": "uvx",
      "args": ["video-url-analyzer-mcp"]
    }
  }
}
```

Keep `GEMINI_API_KEY` in the host environment or a secret store; do not commit it.

## Important tools

- `analyze_video` — full visual/audio analysis.
- `get_transcript` — timestamped transcript.
- `ask_about_video` — questions about content.
- `find_video_moments` — semantic timestamp search.
- `analyze_video_segment` — focused range analysis.
- `prepare_video_context` / `ask_video_context` — reusable local analysis context.
- `get_video_frame` / `get_video_clip` — local evidence assets.
- `get_video_evidence_asset` — evidence selection.
- `watch_and_analyze` — tutorial extraction.
- `check_analysis_job` — poll asynchronous TikTok/Instagram jobs.

## Instagram behavior

Supported URL forms include `instagram.com/reel/`, `instagram.com/reels/`, and `instagram.com/p/`. Video posts are downloaded/scraped then uploaded to Gemini for audio+visual analysis. Non-YouTube analysis may return a background job id; poll it with `check_analysis_job`.

Public Instagram content is the intended baseline. Do not assume private/login-gated content is accessible. Cookie use must be explicitly enabled and must use an authorized local session.

## Verification contract

Before an agent calls this capability READY/LIVE in a new environment, perform all of:

1. `uvx video-url-analyzer-mcp` starts without package/import errors.
2. MCP initialize succeeds.
3. `tools/list` exposes the expected video tools.
4. A harmless public YouTube URL succeeds with `ask_about_video` or `get_transcript`.
5. A public Instagram Reel succeeds through job creation (if async) and `check_analysis_job`.
6. Ask one visual question that cannot be answered from caption/transcript alone.
7. Retrieve one timestamp/frame or segment as evidence.
8. Record package version, host, date, test URLs and result.
9. If any upstream CI check on the installed revision is red, record the failure and do not silently promote status.

## Security

The implementation includes domain allowlisting/SSRF controls, subprocess protections, download-size limits and opt-in cookie access. Still treat downloaded social media as untrusted input. Never enable browser-cookie access on a shared or untrusted host, and never commit Gemini keys or cookies.

## Current qualification evidence

- Active, non-archived upstream repository.
- PyPI-style console entry point exists: `video-url-analyzer-mcp = video_url_analyzer_mcp:main`.
- FastMCP server object exists in source.
- Instagram-specific routing and tests exist.
- Upstream CI is **not fully green** on the inspected release-era run.
- No live Gemini/Instagram end-to-end call was possible from the current execution environment.

Therefore the correct catalog state is **CONDITIONAL / NOT END-TO-END QUALIFIED**, not READY.
