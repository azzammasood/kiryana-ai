"""User-facing agent trace text — no paths, errno, or raw stack details."""

from __future__ import annotations

import re

_ENGINE = "Gemini 2.5 Flash"

_VERTEX_NOISE_RE = re.compile(
    r"Vertex AI Agent Builder fallback used:\s*[^.]*\.?\s*",
    re.IGNORECASE,
)
_ERRNO_RE = re.compile(r"\[Errno\s+\d+\][^.]*\.?\s*", re.IGNORECASE)
_WIN_PATH_RE = re.compile(r"[A-Za-z]:\\[^\s']+")
_UNIX_JSON_PATH_RE = re.compile(r"(?:/[\w.-]+)+\.json")


def sanitize_step_detail(detail: str) -> str:
    """Strip dev-only noise from stored traces (legacy rows included)."""
    if not detail:
        return detail
    text = detail
    text = _VERTEX_NOISE_RE.sub("", text)
    text = _ERRNO_RE.sub("", text)
    text = _WIN_PATH_RE.sub("", text)
    text = _UNIX_JSON_PATH_RE.sub("cloud credentials", text)
    text = re.sub(r"\s{2,}", " ", text).strip()
    text = re.sub(r"\.\s*\.", ".", text)
    return text


def anomaly_detection_detail(observation: str) -> str:
    obs = (observation or "No major anomaly found.").strip()
    return (
        f"Scanned sales and expense patterns for unusual trends using {_ENGINE}. "
        f"Observation: {obs}"
    )


def insight_generation_detail(recommendation_count: int) -> str:
    count = max(0, recommendation_count)
    tip_word = "tip" if count == 1 else "tips"
    return (
        f"Generated weekly business recommendations using {_ENGINE}. "
        f"Prepared {count} personalized {tip_word} for the shopkeeper."
    )


def action_planning_detail(
    recommendation_count: int,
    accepted: int,
    rejected: int,
) -> str:
    return (
        f"Structured {recommendation_count} actionable steps from insights and pattern rules. "
        f"Adapted using learning feedback (accepted={accepted}, rejected={rejected})."
    )
