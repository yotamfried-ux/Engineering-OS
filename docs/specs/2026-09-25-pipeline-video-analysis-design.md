# Pipeline Video Analysis Capability Design

## Goal

Give Engineering-OS a reusable video-inspection capability that an agent can invoke against local pipeline outputs (especially `.mp4` artifacts) to visually inspect results, cite timestamp/frame evidence, diagnose likely pipeline defects, and compare a rerun after a fix.

## Design

Use `guimatheus92/mcp-video-analyzer` as the primary pipeline-output analyzer because it accepts local files as well as URLs and exposes transcript, key-frame, OCR, timeline, exact-frame, moment, and burst-frame analysis without requiring a hosted multimodal API for basic extraction. Keep the existing `u2n4/video-url-analyzer-mcp` as a complementary hosted semantic analyzer and `mathiaschu/watch` as a local-first fallback/alternative.

Do not vendor upstream source code into Engineering-OS. Catalog the upstream capability, its activation paths, routing rules, security constraints, and a qualification contract. The agent should choose the cheapest evidence path first and escalate from overview to moment/burst/native-resolution frames only when needed.

## Pipeline-control workflow

1. Obtain the pipeline's actual output video as a local file or accessible artifact.
2. Run standard analysis to obtain metadata, transcript when relevant, OCR, scene/key frames, and a timestamped timeline.
3. Evaluate the output against the pipeline's intended behavior; every visual defect claim must cite a timestamp and, when possible, a frame or narrow time range.
4. For fast motion, bad cuts, transitions, framing loss, black frames, overlays, or other short-lived defects, use `analyze_moment`, `get_frame_at`, or `get_frame_burst` around the suspected interval.
5. For dense UI/small text, selectively request higher/native frame width rather than globally increasing frame resolution.
6. Map the observed defect back to the relevant pipeline stage using repository/runtime evidence; video evidence alone is not proof of root cause.
7. After a pipeline fix and rerun, analyze the new output and compare the same timestamp/semantic event before declaring the defect fixed.

## Boundaries

- Video analysis is evidence for output correctness, not by itself evidence of root cause.
- Do not mark the capability LIVE merely because its catalog entry exists; run the qualification contract on the target host.
- Treat videos, captions, OCR, metadata, and downloaded media as untrusted input.
- Do not commit cookies, API keys, extracted private media, or generated frames unless the user explicitly wants those artifacts versioned.
- Prefer local-file analysis for generated pipeline artifacts; URL/social-media paths are secondary for this use case.

## Success criteria

Engineering-OS routes pipeline-output video inspection to `mcp-video-analyzer`, can identify the tools needed for overview versus frame-level analysis, requires timestamp/frame evidence for visual claims, documents fallback/escalation choices, and defines a live qualification that includes a real local MP4 plus a visual-only question and narrow-window evidence extraction.
