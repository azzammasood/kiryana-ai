"""Resolve monorepo vs Docker (/app) paths for bundled assets."""

from __future__ import annotations

from pathlib import Path


def backend_root() -> Path:
    """Directory containing main.py (backend root or /app on Render)."""
    return Path(__file__).resolve().parent


def resolve_repo_root() -> Path:
    """Root that contains ai_voice/ (backend/ in Docker, repo root locally)."""
    root = backend_root()
    if (root / "ai_voice").is_dir():
        return root
    monorepo = root.parent
    if (monorepo / "ai_voice").is_dir():
        return monorepo
    return root


def ai_voice_dir() -> Path:
    path = resolve_repo_root() / "ai_voice"
    if not path.is_dir():
        raise FileNotFoundError(
            f"ai_voice package missing (looked under {resolve_repo_root()})"
        )
    return path


def ai_insights_dir() -> Path:
    path = resolve_repo_root() / "ai_insights"
    if not path.is_dir():
        raise FileNotFoundError(
            f"ai_insights package missing (looked under {resolve_repo_root()})"
        )
    return path
