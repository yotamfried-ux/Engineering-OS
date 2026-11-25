# Openverse audio discovery — executable capability

**Status:** BUNDLED EXECUTABLE / offline syntax and parser tests needed; live API credentials and availability unverified.

Canonical source: https://api.openverse.org/v1/
Official documentation: https://docs.openverse.org/
Video provenance: https://www.instagram.com/reel/De90ttNOJbo/

## Immediately available after cloning Engineering-OS

```bash
python3 tools/openverse_audio_search.py --help
python3 tools/openverse_audio_search.py "ui click" --limit 5
python3 tools/eos_capabilities.py ensure --tool openverse-audio
```

The tool is implemented in `tools/openverse_audio_search.py`, has no pip dependencies and needs no account for basic public searches. It makes **read-only** GET requests; it never downloads files, chooses licensed audio automatically, applies assets to a video, or uploads anything. Returned audio URL, title, creator, license, version, attribution and original source link allow review.

**Security & qualification:** Network access is required for the live search. Before downloading/reusing a result, independently verify licensing, attribution, commercial permissions and any restrictions directly at the original source. Passing the offline `--help` test proves command discoverability only, not live API responsiveness.
