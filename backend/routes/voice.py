from __future__ import annotations

import asyncio
import json
import logging
import uuid
from datetime import date, timedelta

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from google.api_core.exceptions import ResourceExhausted
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession
from supabase import create_client

from config import settings
from database import get_db
from models import Insight, Transaction
from schemas import ParseRequest, ParseResponse
from services import gemini_service, insight_engine


logger = logging.getLogger(__name__)
router = APIRouter()


def _quota_http_error(exc: Exception) -> HTTPException:
    return HTTPException(
        status_code=429,
        detail=(
            "Gemini API ki free limit khatam ho chuki hai. "
            "Thori dair baad try karein, ya .env mein TEST_MODE=true set karein."
        ),
    )


async def _week_transactions(user_id: int, db: AsyncSession) -> list:
    today = date.today()
    start = today - timedelta(days=today.weekday())
    end = start + timedelta(days=6)
    return (
        await db.scalars(
            select(Transaction)
            .where(
                Transaction.user_id == user_id,
                Transaction.date >= start,
                Transaction.date <= end,
            )
            .order_by(Transaction.date.asc())
        )
    ).all()


async def _ask_context(user_id: int, db: AsyncSession) -> dict:
    rows = await _week_transactions(user_id, db)
    summary = insight_engine.calculate_weekly_summary(rows) if rows else {}
    insight_row = await db.scalar(
        select(Insight)
        .where(Insight.user_id == user_id)
        .order_by(desc(Insight.created_at))
        .limit(1)
    )
    return {
        "summary": summary,
        "key_insight": insight_row.key_insight if insight_row else "",
        "recommendations": json.loads(insight_row.recommendations or "[]")
        if insight_row
        else [],
    }


def _normalize_audio_content_type(content_type: str | None, filename: str | None = None) -> str:
    value = (content_type or "").split(";")[0].strip().lower()
    name = (filename or "").lower()
    if value in {"video/webm", "application/octet-stream", "binary/octet-stream"} and name.endswith(".webm"):
        return "audio/webm"
    if value in {"video/webm"}:
        return "audio/webm"
    if value:
        return value
    if name.endswith(".webm"):
        return "audio/webm"
    if name.endswith(".wav"):
        return "audio/wav"
    if name.endswith(".mp3"):
        return "audio/mpeg"
    if name.endswith(".m4a") or name.endswith(".mp4"):
        return "audio/mp4"
    return "audio/webm"


async def _upload_audio(user_id: int, audio_bytes: bytes, content_type: str | None) -> str:
    path = f"{user_id}/{uuid.uuid4()}.webm"
    if settings.test_mode:
        return f"{settings.supabase_url.rstrip('/')}/storage/v1/object/public/{settings.supabase_audio_bucket}/{path}"

    def _upload():
        supabase = create_client(settings.supabase_url, settings.supabase_service_key)
        supabase.storage.from_(settings.supabase_audio_bucket).upload(
            path,
            audio_bytes,
            file_options={"content-type": content_type or "audio/mp4", "upsert": "true"},
        )
        return supabase.storage.from_(settings.supabase_audio_bucket).get_public_url(path)

    return await asyncio.to_thread(_upload)


@router.post("/transcribe")
async def transcribe_voice(audio_file: UploadFile = File(...), user_id: int = Form(...)):
    try:
        audio_bytes = await audio_file.read()
        content_type = _normalize_audio_content_type(audio_file.content_type, audio_file.filename)
        audio_url = await _upload_audio(user_id, audio_bytes, content_type)
        text = await gemini_service.transcribe_audio(audio_bytes, content_type)
        return {"transcription": text, "audio_url": audio_url, "user_id": user_id}
    except ResourceExhausted as exc:
        raise _quota_http_error(exc) from exc
    except Exception as exc:
        logger.exception("Voice transcription failed")
        raise HTTPException(status_code=500, detail=f"Voice process nahi ho saki: {exc}") from exc


@router.post("/ask")
async def ask_voice_question(
    audio_file: UploadFile = File(...),
    user_id: int = Form(...),
    question_hint: str | None = Form(None),
    db: AsyncSession = Depends(get_db),
):
    context = await _ask_context(user_id, db)
    try:
        audio_bytes = await audio_file.read()
        content_type = _normalize_audio_content_type(
            audio_file.content_type, audio_file.filename
        )
        result = await gemini_service.ask_finance_from_audio(
            audio_bytes, content_type, context, question_hint=question_hint
        )
        return {
            "user_id": user_id,
            "transcription": result.get("transcription", ""),
            "answer": result.get("answer", ""),
        }
    except ResourceExhausted:
        return {
            "user_id": user_id,
            "transcription": "",
            "answer": gemini_service._context_fallback_answer(context),
        }
    except Exception as exc:
        logger.exception("Voice ask failed")
        err = str(exc).lower()
        if "quota" in err or "429" in err or "resource_exhausted" in err:
            return {
                "user_id": user_id,
                "transcription": "",
                "answer": gemini_service._context_fallback_answer(context),
            }
        raise HTTPException(status_code=500, detail=f"Voice ask fail ho gaya: {exc}") from exc


@router.post("/process")
async def process_voice(audio_file: UploadFile = File(...), user_id: int = Form(...)):
    try:
        audio_bytes = await audio_file.read()
        content_type = _normalize_audio_content_type(audio_file.content_type, audio_file.filename)
        audio_url = await _upload_audio(user_id, audio_bytes, content_type)
        result = await gemini_service.process_voice_audio(
            audio_bytes,
            content_type,
            audio_url=audio_url,
        )
        return {"user_id": user_id, "audio_url": audio_url, **result}
    except ResourceExhausted as exc:
        raise _quota_http_error(exc) from exc
    except Exception as exc:
        logger.exception("Voice processing failed")
        raise HTTPException(status_code=500, detail=f"Voice process nahi ho saki: {exc}") from exc


@router.post("/parse", response_model=ParseResponse)
async def parse_voice_text(payload: ParseRequest):
    try:
        parsed = await gemini_service.parse_transaction(payload.text)
        return ParseResponse(**parsed)
    except Exception as exc:
        logger.exception("Voice parse failed")
        raise HTTPException(status_code=500, detail=f"Transaction samajh nahi aayi: {exc}") from exc
