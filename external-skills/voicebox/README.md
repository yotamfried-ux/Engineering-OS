# Voicebox

**Canonical upstream:** `jamiepine/voicebox`

Local-first open-source AI voice studio for voice cloning, speech generation, dictation and agent voice I/O. Upstream exposes REST plus a built-in MCP server and supports local execution across desktop platforms.

## Use when
Use when a project or agent needs local speech input/output, TTS, STT/dictation, owned voice profiles, or an MCP-accessible speaking capability.

## Qualification
Install only from canonical upstream/release. Verify one local transcription, one speech generation, MCP initialize/tools listing, and one agent-triggered speech call. Record model/engine, host/GPU, version and whether any selected engine sends data to a cloud service.

## Privacy
Do not assume every optional model/engine is local merely because the application is local-first. Verify the selected backend and data path before using sensitive audio.

**Status:** READY AS KNOWLEDGE / HOST-DEPENDENT FOR EXECUTION.
