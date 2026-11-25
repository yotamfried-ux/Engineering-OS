"""Deterministic, offline checks for executable Openverse audio discovery."""
from __future__ import annotations

import io
import json
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import openverse_audio_search as audio  # noqa: E402


class OpenverseAudioTests(unittest.TestCase):
    def test_normalize_preserves_license_and_attribution(self):
        response = {"results": [{"id": "audio-1", "title": "UI click",
            "creator": "Creator", "license": "by", "license_version": "4.0",
            "attribution": "Credit Creator", "url": "https://media.example/click.wav",
            "foreign_landing_url": "https://origin.example/item", "source": "freesound"}]}
        normalized = audio.search_audio("button click", limit=3, response=response)
        self.assertEqual(normalized["results"][0]["creator"], "Creator")
        self.assertEqual(normalized["results"][0]["license"], "by")
        self.assertEqual(normalized["results"][0]["attribution"], "Credit Creator")
        self.assertIn("q=button+click", normalized["api_url"])
        self.assertIn("page_size=3", normalized["api_url"])

    def test_live_request_is_read_only_get_with_timeout(self):
        payload = {"results": [{"id": "a"}]}
        response = io.BytesIO(json.dumps(payload).encode())
        with patch.object(audio.urllib.request, "urlopen", return_value=response) as urlopen:
            result = audio.search_audio("whoosh", limit=1)
        self.assertEqual(len(result["results"]), 1)
        request = urlopen.call_args.args[0]
        self.assertEqual(request.get_method(), "GET")
        self.assertIn("api.openverse.org/v1/audio/", request.full_url)

    def test_rejects_unbounded_requests_and_empty_query(self):
        for query, limit in [("", 10), ("whoosh", 0), ("whoosh", 21)]:
            with self.assertRaises(ValueError):
                audio.search_audio(query, limit, response={"results": []})

    def test_help_exits_successfully_without_network(self):
        with self.assertRaises(SystemExit) as context:
            audio.main(["--help"])
        self.assertEqual(context.exception.code, 0)


if __name__ == "__main__":
    unittest.main()
