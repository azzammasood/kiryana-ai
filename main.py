#!/usr/bin/env python3
"""
CLI: send a local ``.wav`` / ``.mp4`` (audio track) file through ``VoiceEngine``.
Uses the ``google-genai`` SDK and ``gemini-2.5-flash`` by default (see ``ai_voice.engine.GEMINI_MODEL``).

Environment
-----------
``GEMINI_API_KEY`` — required unless ``--api-key`` is passed.

Examples
--------
python main.py recording.wav
python main.py shop_clip.mp4 --context "Vegetable stall in Lahore"
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def _load_dotenv() -> None:
    try:
        from dotenv import load_dotenv
    except ImportError:
        return
    # Base defaults, then `.env.local` wins (common local-dev pattern).
    load_dotenv()
    load_dotenv(".env.local", override=True)


def main() -> int:
    _load_dotenv()

    parser = argparse.ArgumentParser(
        description="KiryanaAI — parse a voice clip into structured JSON (Gemini 1.5 Flash).",
    )
    parser.add_argument(
        "audio_file",
        type=Path,
        help="Path to .wav, .mp3, .mp4 (audio), etc.",
    )
    parser.add_argument(
        "--api-key",
        dest="api_key",
        default=None,
        help="Gemini API key (overrides GEMINI_API_KEY).",
    )
    parser.add_argument(
        "--context",
        default=None,
        help="Optional hint about the shop or inventory (improves disambiguation).",
    )
    parser.add_argument(
        "--items",
        default=None,
        help="Comma-separated recent items this trader sells (optional).",
    )
    parser.add_argument(
        "--pretty",
        action="store_true",
        help="Pretty-print JSON.",
    )

    args = parser.parse_args()

    if not args.audio_file.is_file():
        print(f"File not found: {args.audio_file}", file=sys.stderr)
        return 2

    from ai_voice import VoiceEngine

    engine = VoiceEngine(api_key=args.api_key)
    prev = (
        [s.strip() for s in args.items.split(",") if s.strip()]
        if args.items
        else None
    )
    result = engine.process_audio(
        args.audio_file,
        context_hint=args.context,
        previous_items=prev,
    )

    payload = result.to_api_dict()
    if args.pretty:
        print(json.dumps(payload, indent=2, ensure_ascii=False))
    else:
        print(json.dumps(payload, ensure_ascii=False))

    return 0 if result.processing_status.value != "failed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
