# Agent-assisted video editing without generic templates

**Source Reel:** https://www.instagram.com/reel/De90ttNOJbo/ — confirmed Hebrew transcript and visual scene breakdown.

## Reusable four-part workflow

1. **Context as durable project files.** Give the editor agent `preferences.md` with typography, pacing, subtitle style, trimming conventions, aspect ratio, export details and explicit rights. Store `reference/` with approved example videos, then link to prior approved outputs.
2. **Curated visual inspiration.** EyeCandy: https://eyecandy.im/ is a reference gallery. Prompt Motion: https://prompt-motion.com/ and similar galleries give motion-prompt examples; exact site name is ambiguous across brands. React Bits: https://reactbits.dev/ (canonical GitHub https://github.com/DavidHDev/react-bits) offers installable UI/text animations. **The libraries are inspiration and components, not an automatic video-editing engine.**
3. **Audio assets.** Openverse API: https://api.openverse.org/v1/ supports openly licensed audio discovery. Engineering-OS now bundles `tools/openverse_audio_search.py` for real read-only searches, returns metadata/attribution and leaves licensing confirmation to a human. Avoid using third-party sounds whose reuse rights are unclear.
4. **Editable multi-track result.** Instead of only exporting a flattened MP4, deliver timeline segments (video, subtitle, overlays, voice/music/SFX) with timestamps and source references. A creator reviews and adjusts before final rendering.

## Implementation / acceptance

- Source model: reusable prompt preference manifest, individual voice/image/video sources, asset provenance and edit-decision list.
- Rendering: use a code/video framework only after checking that existing project stack provides it; compose in a structured editor/timeline.
- Quality: preview mobile format, check subtitle legibility, no copyright violations, synced SFX, silence/trimming logic, audio levels and editable track boundaries.
- A motion prompt gallery or aesthetic reference never proves the generated video looks like the original style. Evaluate with manually reviewed real outputs.

**Tools:** `react-bits` bundled project installer, `openverse-audio` bundled audio-search CLI, `lemo-opuscar` Claude film-style plugin (separate tool).
