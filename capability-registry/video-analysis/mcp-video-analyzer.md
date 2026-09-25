# MCP Video Analyzer — local pipeline-output inspection

## Purpose

Give an AI agent a practical way to inspect the **actual video files produced by a pipeline** and turn them into timestamped visual evidence that can drive debugging and rerun verification.

Primary upstream: `guimatheus92/mcp-video-analyzer`

Upstream repository: https://github.com/guimatheus92/mcp-video-analyzer

This is the preferred Engineering-OS route for local `.mp4`/video artifacts because it accepts local files directly and exposes transcript, key frames, OCR, metadata, a unified timeline, exact-frame extraction, focused moment analysis, and burst frames for short motion/transition defects.

## Status

**READY AS KNOWLEDGE / NOT YET END-TO-END QUALIFIED ON TARGET HOST — 2026-09-25**

Do not call this capability LIVE merely because this catalog entry exists. Qualify it on the host that will inspect pipeline artifacts using the contract below.

## Why this is the primary pipeline-control route

The existing `video-url-analyzer-mcp.md` is useful for hosted semantic analysis and supported public URLs, but its documented path depends on Gemini for multimodal analysis. Pipeline control usually starts with a local artifact produced by CI/runtime. `mcp-video-analyzer` can inspect that local file, extract deterministic evidence assets, and let the host vision model reason over the extracted frames without requiring a hosted video-analysis API for the basic extraction path.

`external-skills/watch-video/` remains a useful local-first fallback/alternative. Do not install or invoke every video tool for every task; route by the evidence needed.

## Requirements

- Node.js >= 22.12
- `npx` for MCP/CLI activation
- Local-file analysis: bundled ffmpeg-static covers frame extraction
- `yt-dlp` is required for supported platform URLs such as YouTube/Instagram/TikTok, but is not required for ordinary local-file/direct-file analysis
- Optional local Whisper-compatible transcription path when a source has no captions

## Activation

### MCP server

```bash
npx mcp-video-analyzer@latest
```

Generic MCP configuration:

```json
{
  "mcpServers": {
    "video-analyzer": {
      "command": "npx",
      "args": ["mcp-video-analyzer@latest"]
    }
  }
}
```

### One-shot CLI fallback

When the host has shell access but no MCP connection:

```bash
npx -y mcp-video-analyzer@latest analyze "/absolute/path/to/output.mp4"
```

The CLI returns structured JSON and frame file paths. Read only the evidence needed for the question rather than loading every frame into context.

## Tool selection for pipeline QA

- `analyze_video` — default overview: metadata + transcript when available + key frames + OCR + timeline.
- `get_frames` — visual sampling without the rest of the full analysis.
- `analyze_moment` — focused inspection around a suspected bad cut, transition, overlay, framing event, or other narrow interval.
- `get_frame_at` — exact visual evidence at a known timestamp.
- `get_frame_burst` — several frames across a narrow interval for motion, fast edits, animation, jitter, dropped/duplicated-looking content, or subject-tracking loss.
- `get_transcript` — speech-only questions; prefer this cheaper path when visuals are irrelevant.
- `get_metadata` — duration/title/source metadata without visual extraction.
- `analyze_videos` — batch inspection when a validation run intentionally produces several output files.

## Context/token discipline

Use progressive disclosure:

1. Start with `analyze_video` at standard detail for an unknown visual defect, or transcript/metadata-only tools when the question does not require frames.
2. Identify suspicious timestamps from the timeline/key frames.
3. Deep-read only those intervals with `analyze_moment`, `get_frame_at`, or `get_frame_burst`.
4. The upstream defaults emitted frames to a reduced width. Raise `maxWidth` only when small text or fine visual detail is actually relevant; `maxWidth: 0` preserves source resolution but can cost substantially more context.
5. Do not use dense/full-resolution analysis of the whole video merely because it is available.

## Pipeline-control workflow

For a generated video artifact:

1. Resolve the actual output file from the pipeline/CI/runtime evidence.
2. Run a standard visual overview and build a timestamped evidence map.
3. Compare the observed output to the intended pipeline behavior or test oracle.
4. For each suspected defect, record the timestamp/range and obtain a frame or narrow burst when useful.
5. Correlate the visible defect with logs, configuration, source code, intermediate artifacts, or deterministic tests before assigning root cause. A bad output proves an output defect; it does not by itself prove which stage caused it.
6. Make the pipeline fix through the normal Engineering-OS debugging/testing workflow.
7. Rerun the pipeline and analyze the new output.
8. Re-check the same semantic event/timestamp region and retain before/after evidence before declaring the visual defect fixed.

Typical defects this route can help inspect include incorrect cuts, missed moments, unwanted segments, black/blank frames, bad transitions, overlays/OCR-visible errors, framing/crop problems, subject loss, duplicated-looking frames, and short motion/edit artifacts. Detection quality still depends on sampling and the host vision model; absence from sparse key frames is not proof that a short-lived defect does not exist.

## Qualification contract

Before marking this capability READY/LIVE on a target host, perform all of:

1. Start `npx mcp-video-analyzer@latest` and complete MCP initialization, or successfully invoke the one-shot CLI.
2. Confirm the expected video tools are available when using MCP.
3. Analyze a harmless **local MP4 file** successfully; local-file support is mandatory for the pipeline-control use case.
4. Ask a visual-only question that cannot be answered from transcript/audio alone.
5. Retrieve timestamped key-frame evidence for the answer.
6. Pick a narrow interval and successfully use moment, exact-frame, or burst-frame analysis.
7. If the sample contains small on-screen text, verify a selective higher/native-width read can recover evidence without globally increasing all frames.
8. Run the same artifact a second time and confirm caching/reuse does not change the semantic result unexpectedly.
9. Record installed package version, host/runtime, date, sample-file identity, commands/tools used, warnings, and results.
10. Only after those checks pass may the target-host status be promoted to LIVE.

A later SportReel/pipeline qualification should additionally analyze a real non-sensitive pipeline output, identify at least one expected visual event with timestamp/frame evidence, and compare an output from a rerun so the complete control loop is proven.

## Security and artifact hygiene

- Treat input videos, subtitles, OCR, comments, metadata, and downloaded media as untrusted input.
- Keep private videos and extracted frames outside git by default.
- Never commit browser cookies, API keys, auth headers, or private-media URLs containing credentials.
- Platform-cookie access must use an authorized user session and should not be enabled when local pipeline files are sufficient.
- Keep private/loopback URL access disabled unless the target workflow explicitly requires it and the network trust boundary has been reviewed.
- Prefer a bounded working/cache directory and clean generated evidence when it is no longer needed.

## Relationship to other Engineering-OS video capabilities

- **`mcp-video-analyzer` (this file):** first choice for local pipeline artifacts and frame/timeline/OCR-driven QA.
- **`video-url-analyzer-mcp.md`:** complementary hosted multimodal/semantic route for supported URLs when its Gemini-backed qualification and credentials are available.
- **`external-skills/watch-video/`:** local-first skill fallback/alternative when MCP is unavailable or its workflow is a better host fit.

Do not infer that all three are active because they are catalogued. Check the target host and use the smallest qualified route that can produce the required evidence.
