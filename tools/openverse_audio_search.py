#!/usr/bin/env python3
"""Read-only, standard-library client for Openverse's public audio search API.

Never downloads or inserts audio into projects. The caller must independently
verify media licensing, attribution, allowed uses and creator permissions.
"""
from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.parse
import urllib.request

BASE_URL = "https://api.openverse.org/v1/audio/"


def normalize(payload: dict) -> list[dict]:
    return [
        {
            "id": row.get("id"),
            "title": row.get("title"),
            "creator": row.get("creator"),
            "license": row.get("license"),
            "license_version": row.get("license_version"),
            "attribution": row.get("attribution"),
            "foreign_landing_url": row.get("foreign_landing_url"),
            "audio_url": row.get("url"),
            "source": row.get("source"),
        }
        for row in payload.get("results", [])
        if isinstance(row, dict)
    ]


def search_audio(query: str, limit: int = 10, *, response: dict | None = None) -> dict:
    if not query.strip():
        raise ValueError("A non-empty query is required")
    if not 1 <= limit <= 20:
        raise ValueError("Limit must be between 1 and 20")
    params = urllib.parse.urlencode({"q": query.strip(), "page_size": limit})
    url = BASE_URL + "?" + params
    if response is None:
        request = urllib.request.Request(url, headers={
            "User-Agent": "Engineering-OS-Openverse-Research/1.0",
            "Accept": "application/json",
        })
        with urllib.request.urlopen(request, timeout=20) as stream:
            response = json.load(stream)
    if not isinstance(response, dict):
        raise ValueError("Unexpected Openverse response schema")
    return {
        "query": query.strip(),
        "api_url": url,
        "results": normalize(response)[:limit],
        "licensing_note": "Verify each asset's license at the original source before use. Attribution and commercial permissions vary.",
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Search Openverse for openly licensed audio, read-only.")
    parser.add_argument("query", help="Audio keyword, e.g. whoosh or button click")
    parser.add_argument("--limit", type=int, default=10, help="Maximum results (1-20)")
    args = parser.parse_args(argv)
    try:
        print(json.dumps(search_audio(args.query, args.limit), ensure_ascii=False, indent=2))
    except (OSError, urllib.error.URLError, ValueError, json.JSONDecodeError) as exc:
        print(f"Openverse search failed: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
