# /watch — local video understanding skill

**Canonical upstream:** `mathiaschu/watch`

Claude/Codex-compatible video-understanding skill. It accepts a video URL or local file, uses yt-dlp/ffmpeg to acquire and sample the media, obtains captions or performs local Whisper transcription, and gives the agent timestamped transcript plus extracted frames for visual analysis.

Upstream explicitly documents YouTube, Instagram, X/Twitter, Vimeo, TikTok, Loom and other yt-dlp-supported sources, plus browser-cookie authentication for content the user is authorized to access.

## Why use it
This is a useful local-first complement/alternative to the catalogued Video URL Analyzer MCP: no Gemini API key is required, transcription can remain local, and visual questions are answered from extracted frames rather than transcript alone.

## Qualification contract
Before marking LIVE on a host: install from canonical upstream; verify ffmpeg/yt-dlp and local Whisper fallback; test a public video; ask a visual-only question; verify timestamp/frame evidence; then test a public Instagram Reel. Cookie-authenticated testing is optional and must use the user's authorized session without copying cookies into the repository.

**Status:** READY AS KNOWLEDGE / NOT YET END-TO-END QUALIFIED ON TARGET HOST.
