"""
Core multimodal engine: Gemini (google-genai SDK) ingests audio and returns JSON in one call.
"""

from __future__ import annotations

import json
import logging
import mimetypes
import os
import time
from pathlib import Path
from typing import Any, Union

from google import genai
from google.genai import types

from .prompts import (
    MASTER_SYSTEM_PROMPT,
    build_extraction_prompt,
    get_clarification_message,
)
from .schema import (
    DetectedLanguage,
    ProcessingStatus,
    TransactionType,
    UnitType,
    VoiceTransactionResult,
)

logger = logging.getLogger("kiryanaai.ai_voice")

SUPPORTED_AUDIO_MIME_TYPES: dict[str, str] = {
    ".wav": "audio/wav",
    ".mp3": "audio/mpeg",
    ".mp4": "audio/mp4",
    ".m4a": "audio/mp4",
    ".ogg": "audio/ogg",
    ".flac": "audio/flac",
    ".aac": "audio/aac",
    ".webm": "audio/webm",
}

GEMINI_MODEL: str = "gemini-2.5-flash"
MAX_RETRIES: int = 3
RETRY_DELAY_SECONDS: float = 1.5
MAX_OUTPUT_TOKENS: int = 2048
TEMPERATURE: float = 0.1


class VoiceEngineError(RuntimeError):
    """Raised for unrecoverable engine failures (API, IO, invalid JSON)."""


class VoiceEngine:
    """
    Process trader voice clips into structured ``VoiceTransactionResult`` objects.

    Uses the official ``google-genai`` client (not the deprecated ``google-generativeai``
    package). The client reads ``GEMINI_API_KEY`` from the environment when no key
    is passed explicitly.

    Parameters
    ----------
    api_key
        Gemini API key, or ``None`` to read ``GEMINI_API_KEY`` from the environment.
    model_name
        Gemini model id (default ``gemini-2.5-flash``).
    max_retries
        Retries for transient API failures.
    """

    def __init__(
        self,
        api_key: str | None = None,
        model_name: str = GEMINI_MODEL,
        max_retries: int = MAX_RETRIES,
    ) -> None:
        resolved_key = api_key or os.getenv("GEMINI_API_KEY")
        if not resolved_key:
            raise ValueError(
                "Gemini API key is required. Pass api_key= or set GEMINI_API_KEY."
            )

        self._client = genai.Client(api_key=resolved_key)
        self._model_name = model_name
        self._max_retries = max_retries
        logger.info("VoiceEngine initialised with model %s", model_name)

    def process_audio(
        self,
        audio_source: Union[str, Path, bytes],
        mime_type: str | None = None,
        context_hint: str | None = None,
        previous_items: list[str] | None = None,
    ) -> VoiceTransactionResult:
        """
        Parse audio (path or raw bytes) into validated structured output.

        Audio is sent with ``types.Part.from_bytes`` for multimodal ``generate_content``.
        """
        start_ts = time.monotonic()

        try:
            audio_bytes, resolved_mime = self._load_audio(audio_source, mime_type)
            logger.info(
                "Audio loaded: %d bytes, MIME %s",
                len(audio_bytes),
                resolved_mime,
            )

            raw_json_str = self._call_gemini_with_retry(
                audio_bytes=audio_bytes,
                mime_type=resolved_mime,
                context_hint=context_hint,
                previous_items=previous_items,
            )

            result = self._parse_and_validate(raw_json_str)

        except VoiceEngineError as exc:
            logger.error("VoiceEngineError: %s", exc)
            result = self._make_failed_result(str(exc))

        except Exception as exc:  # noqa: BLE001 — surface as safe FAILED payload
            logger.exception("Unexpected error in VoiceEngine.process_audio")
            result = self._make_failed_result(
                f"Unexpected error: {type(exc).__name__}: {exc}"
            )

        elapsed = round(time.monotonic() - start_ts, 3)
        logger.info(
            "Processed in %.3fs | status=%s | confidence=%.2f | items=%d",
            elapsed,
            result.processing_status,
            result.confidence_score,
            len(result.transactions),
        )
        return result

    def _load_audio(
        self,
        source: Union[str, Path, bytes],
        mime_override: str | None,
    ) -> tuple[bytes, str]:
        if isinstance(source, bytes):
            mime = mime_override or "audio/wav"
            return source, mime

        path = Path(source)
        if not path.exists():
            raise VoiceEngineError(f"Audio file not found: {path}")

        suffix = path.suffix.lower()
        mime = (
            mime_override
            or SUPPORTED_AUDIO_MIME_TYPES.get(suffix)
            or mimetypes.guess_type(str(path))[0]
            or "audio/wav"
        )

        if suffix not in SUPPORTED_AUDIO_MIME_TYPES and not mime_override:
            logger.warning(
                "Unknown extension %s; attempting MIME %s",
                suffix,
                mime,
            )

        return path.read_bytes(), mime

    def _call_gemini_with_retry(
        self,
        audio_bytes: bytes,
        mime_type: str,
        context_hint: str | None,
        previous_items: list[str] | None,
    ) -> str:
        user_prompt = build_extraction_prompt(
            context_hint=context_hint,
            previous_items=previous_items,
        )

        contents: list[types.Part | str] = [
            types.Part.from_bytes(data=audio_bytes, mime_type=mime_type),
            user_prompt,
        ]

        config = types.GenerateContentConfig(
            temperature=TEMPERATURE,
            max_output_tokens=MAX_OUTPUT_TOKENS,
            response_mime_type="application/json",
            system_instruction=MASTER_SYSTEM_PROMPT,
        )

        last_error: Exception | None = None

        for attempt in range(1, self._max_retries + 1):
            try:
                response = self._client.models.generate_content(
                    model=self._model_name,
                    contents=contents,
                    config=config,
                )
                return _extract_response_text(response)

            except Exception as exc:  # noqa: BLE001
                last_error = exc
                logger.warning("Gemini attempt %d failed: %s", attempt, exc)
                if attempt < self._max_retries:
                    sleep_time = RETRY_DELAY_SECONDS * (2 ** (attempt - 1))
                    logger.info("Retrying in %.1fs", sleep_time)
                    time.sleep(sleep_time)

        raise VoiceEngineError(
            f"Gemini API failed after {self._max_retries} attempts. Last: {last_error}"
        ) from last_error

    def _parse_and_validate(self, raw_json_str: str) -> VoiceTransactionResult:
        cleaned = _strip_json_fences(raw_json_str)

        try:
            data: dict[str, Any] = json.loads(cleaned)
        except json.JSONDecodeError as exc:
            logger.error("JSON decode error: %s | head=%r", exc, cleaned[:500])
            raise VoiceEngineError(f"Gemini returned invalid JSON: {exc}") from exc

        raw_items = data.get("transactions") or []
        data["transactions"] = [_sanitise_item(dict(item)) for item in raw_items]

        confidence = float(data.get("confidence_score", 0.5))
        if confidence < 0.5 and not data.get("user_friendly_message"):
            missing = _detect_missing_fields(data["transactions"])
            data["user_friendly_message"] = get_clarification_message(missing)

        try:
            return VoiceTransactionResult(**data)
        except Exception as exc:  # noqa: BLE001
            logger.error("Pydantic validation error: %s", exc)
            raise VoiceEngineError(f"Response schema validation failed: {exc}") from exc

    @staticmethod
    def _make_failed_result(error_detail: str) -> VoiceTransactionResult:
        return VoiceTransactionResult(
            transactions=[],
            raw_transcript="",
            detected_language=DetectedLanguage.MIXED,
            confidence_score=0.0,
            processing_status=ProcessingStatus.FAILED,
            error_detail=error_detail,
            user_friendly_message=(
                "آواز سمجھنے میں خرابی آئی۔ دوبارہ کوشش کریں۔\n"
                "(A processing error occurred. Please try again.)"
            ),
        )


def _extract_response_text(response: Any) -> str:
    """Return stripped model text or raise VoiceEngineError."""
    try:
        text = response.text
    except ValueError as exc:
        raise VoiceEngineError(
            "Gemini returned no text (empty or blocked response). "
            f"Detail: {exc}"
        ) from exc
    if text is None or not str(text).strip():
        raise VoiceEngineError("Gemini returned empty text.")
    return str(text).strip()


def _strip_json_fences(text: str) -> str:
    text = text.strip()
    if text.startswith("```"):
        lines = text.splitlines()
        lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        text = "\n".join(lines).strip()
    return text


def _sanitise_item(item: dict[str, Any]) -> dict[str, Any]:
    raw_type = str(item.get("transaction_type", "")).lower()
    if raw_type not in {t.value for t in TransactionType}:
        item["transaction_type"] = TransactionType.SALE.value

    raw_unit = str(item.get("unit", "")).lower()
    valid_units = {u.value for u in UnitType}
    if raw_unit not in valid_units:
        item["unit"] = UnitType.UNKNOWN.value

    for field in ("item_name_urdu", "notes"):
        if item.get(field) == "":
            item[field] = None

    conf = item.get("confidence")
    if conf is not None:
        try:
            item["confidence"] = max(0.0, min(1.0, float(conf)))
        except (TypeError, ValueError):
            item["confidence"] = 0.5

    return item


def _detect_missing_fields(transactions: list[dict[str, Any]]) -> list[str]:
    missing: set[str] = set()
    for item in transactions:
        name = item.get("item_name")
        if not name or name == "unknown":
            missing.add("item_name")
        if item.get("price") is None:
            missing.add("price")
        if item.get("quantity") is None:
            missing.add("quantity")
    return list(missing)
