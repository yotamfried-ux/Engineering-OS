# Pipeline Video Analysis Capability Implementation Plan

> **For agentic workers:** Use the host's available task-by-task implementation workflow. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a routed, evidence-driven local pipeline-video analysis capability to Engineering-OS.

**Architecture:** Catalog `guimatheus92/mcp-video-analyzer` as the primary analyzer for local pipeline outputs while retaining the existing hosted Video URL Analyzer MCP and `/watch` skill as complementary routes. Update the central routing and agent-tool registry so agents choose overview, moment/frame, and fallback paths without loading unrelated video knowledge.

**Tech Stack:** Markdown capability registry, MCP/CLI activation metadata, Node.js 22.12+, yt-dlp where platform URLs are used, bundled ffmpeg-static in the upstream analyzer.

## Global Constraints

- Do not vendor upstream source into Engineering-OS.
- Prefer local-file analysis for pipeline outputs.
- Require timestamp/frame evidence for visual defect claims.
- Escalate to burst/native-resolution extraction only when the question requires it to limit context/token cost.
- Keep secrets, cookies, private media, and generated evidence assets out of git by default.
- Catalog status must remain NOT END-TO-END QUALIFIED until a real target-host local-MP4 test passes.

---

### Task 1: Catalog the local pipeline video analyzer

**Files:**
- Create: `capability-registry/video-analysis/mcp-video-analyzer.md`

**Interfaces:**
- Consumes: local video path or supported video URL.
- Produces: documented routes for `analyze_video`, `analyze_moment`, `get_frame_at`, `get_frame_burst`, transcript/OCR/timeline evidence, and CLI fallback.

- [ ] Add purpose, upstream, prerequisites, activation, tool-selection rules, pipeline-control workflow, security constraints, and qualification contract.
- [ ] Verify the document explicitly covers a real local MP4, a visual-only question, timestamp/frame evidence, narrow-window analysis, and rerun comparison.

### Task 2: Route video-control work to the new capability

**Files:**
- Modify: `capability-registry/ROUTING-MAP.md`
- Modify: `capability-registry/agent-tools.md`

**Interfaces:**
- Consumes: agent job classification such as pipeline-output inspection or social/video URL analysis.
- Produces: progressive-disclosure route to the smallest relevant video capability document.

- [ ] Change the video route so local/pipeline outputs prefer `mcp-video-analyzer`, with the existing URL analyzer and `/watch` as complementary routes.
- [ ] Add `mcp-video-analyzer` to Media understanding with its qualification state and pipeline-specific use.
- [ ] Verify central routing still requires timestamp/frame evidence and does not claim LIVE qualification.

### Task 3: Repository-level consistency verification

**Files:**
- Verify: `capability-registry/video-analysis/mcp-video-analyzer.md`
- Verify: `capability-registry/ROUTING-MAP.md`
- Verify: `capability-registry/agent-tools.md`

**Interfaces:**
- Consumes: final registry text.
- Produces: internally consistent capability naming, upstream reference, status, and evidence contract.

- [ ] Search for `mcp-video-analyzer` and confirm all references point to the same catalog path and upstream.
- [ ] Search video-analysis routing and confirm the primary local-pipeline route, hosted URL route, and local `/watch` fallback are distinguishable.
- [ ] Confirm no credential, cookie, generated media, or copied upstream source was committed.

## Unresolved externally observable decisions

None for catalog integration. Promotion from NOT END-TO-END QUALIFIED to LIVE remains evidence-dependent and is intentionally deferred until a target host can run the real local-MP4 qualification.
