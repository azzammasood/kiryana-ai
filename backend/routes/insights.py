from __future__ import annotations

import json
from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import delete, desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models import AgentTrace, Insight, RecommendationFeedback, Transaction, VoiceFeedback
from schemas import (
    AdaptationKPIResponse,
    AgentTraceResponse,
    InsightAskRequest,
    InsightAskResponse,
    InsightResponse,
    RecommendationFeedbackCreate,
    VoiceFeedbackCreate,
)
from services import antigravity_agent, cache_service, gemini_service, insight_engine


router = APIRouter()


async def _kpis(user_id: int, db: AsyncSession) -> dict:
    voice_total = await db.scalar(
        select(func.count()).select_from(VoiceFeedback).where(VoiceFeedback.user_id == user_id)
    )
    voice_correct = await db.scalar(
        select(func.count())
        .select_from(VoiceFeedback)
        .where(VoiceFeedback.user_id == user_id, VoiceFeedback.is_correct.is_(True))
    )
    rec_total = await db.scalar(
        select(func.count())
        .select_from(RecommendationFeedback)
        .where(RecommendationFeedback.user_id == user_id)
    )
    rec_accepted = await db.scalar(
        select(func.count())
        .select_from(RecommendationFeedback)
        .where(RecommendationFeedback.user_id == user_id, RecommendationFeedback.accepted.is_(True))
    )
    voice_total = int(voice_total or 0)
    voice_correct = int(voice_correct or 0)
    rec_total = int(rec_total or 0)
    rec_accepted = int(rec_accepted or 0)
    return {
        "voice_feedback_total": voice_total,
        "voice_parse_accuracy_pct": round((voice_correct / voice_total) * 100, 1) if voice_total else 0.0,
        "recommendation_feedback_total": rec_total,
        "recommendation_acceptance_pct": round((rec_accepted / rec_total) * 100, 1) if rec_total else 0.0,
    }


async def _week_transactions(user_id: int, db: AsyncSession) -> list:
    today = date.today()
    start = today - timedelta(days=today.weekday())
    end = start + timedelta(days=6)
    return (
        await db.scalars(
            select(Transaction)
            .where(Transaction.user_id == user_id, Transaction.date >= start, Transaction.date <= end)
            .order_by(Transaction.date.asc())
        )
    ).all()


async def _enrich_insight_payload(payload: dict, user_id: int, db: AsyncSession) -> dict:
    rows = await _week_transactions(user_id, db)
    if rows:
        summary = insight_engine.calculate_weekly_summary(rows)
        payload["top_expenses"] = summary.get("top_expenses", [])
    else:
        payload["top_expenses"] = []
    payload["kpis"] = await _kpis(user_id, db)
    return payload


def _decode_insight(row: Insight) -> dict:
    return {
        "id": row.id,
        "user_id": row.user_id,
        "session_id": row.session_id,
        "week_start": row.week_start,
        "week_end": row.week_end,
        "total_sales": row.total_sales,
        "total_expenses": row.total_expenses,
        "profit": row.profit,
        "top_items": json.loads(row.top_items or "[]"),
        "top_expenses": [],
        "recommendations": json.loads(row.recommendations or "[]"),
        "key_insight": row.key_insight,
        "report_text": row.report_text,
        "kpis": {},
        "created_at": row.created_at,
    }


@router.post("/generate/{user_id}", response_model=InsightResponse)
async def generate_insight(user_id: int, db: AsyncSession = Depends(get_db)):
    today = date.today()
    start = today - timedelta(days=today.weekday())
    end = start + timedelta(days=6)
    rows = (
        await db.scalars(
            select(Transaction)
            .where(Transaction.user_id == user_id, Transaction.date >= start, Transaction.date <= end)
            .order_by(Transaction.date.asc())
        )
    ).all()
    if not rows:
        raise HTTPException(status_code=400, detail="Is hafte koi transaction record nahi hai")
    result = await antigravity_agent.run_insight_workflow(user_id, rows, db)
    result = await _enrich_insight_payload(result, user_id, db)
    await cache_service.invalidate(f"insight:{user_id}:latest")
    return result


@router.get("/{user_id}/latest", response_model=InsightResponse)
async def latest_insight(user_id: int, db: AsyncSession = Depends(get_db)):
    cache_key = f"insight:{user_id}:latest"
    cached = await cache_service.get_cached(cache_key)
    if cached is not None:
        cached = await _enrich_insight_payload(dict(cached), user_id, db)
        return cached
    row = await db.scalar(
        select(Insight)
        .where(Insight.user_id == user_id)
        .order_by(desc(Insight.created_at))
        .limit(1)
    )
    if not row:
        raise HTTPException(status_code=404, detail="Report abhi generate nahi hui")
    payload = _decode_insight(row)
    payload = await _enrich_insight_payload(payload, user_id, db)
    result = InsightResponse(**payload).model_dump(mode="json")
    await cache_service.set_cached(cache_key, result, ttl_seconds=600)
    return result


@router.get("/{user_id}/sessions")
async def insight_sessions(user_id: int, db: AsyncSession = Depends(get_db)):
    rows = (
        await db.scalars(
            select(Insight)
            .where(Insight.user_id == user_id)
            .order_by(desc(Insight.created_at))
            .limit(20)
        )
    ).all()
    return [
        {
            "insight_id": row.id,
            "session_id": row.session_id,
            "summary": row.key_insight,
            "created_at": row.created_at,
        }
        for row in rows
    ]


@router.get("/{user_id}/trace", response_model=list[AgentTraceResponse])
async def latest_trace(user_id: int, db: AsyncSession = Depends(get_db)):
    insight = await db.scalar(
        select(Insight)
        .where(Insight.user_id == user_id)
        .order_by(desc(Insight.created_at))
        .limit(1)
    )
    if not insight:
        raise HTTPException(status_code=404, detail="Trace abhi available nahi")
    rows = (
        await db.scalars(
            select(AgentTrace)
            .where(AgentTrace.user_id == user_id, AgentTrace.session_id == insight.session_id)
            .order_by(AgentTrace.step_number.asc())
        )
    ).all()
    return rows


@router.get("/{user_id}/trace/{session_id}", response_model=list[AgentTraceResponse])
async def trace_by_session(user_id: int, session_id: str, db: AsyncSession = Depends(get_db)):
    rows = (
        await db.scalars(
            select(AgentTrace)
            .where(AgentTrace.user_id == user_id, AgentTrace.session_id == session_id)
            .order_by(AgentTrace.step_number.asc())
        )
    ).all()
    if not rows:
        raise HTTPException(status_code=404, detail="Trace abhi available nahi")
    return rows


@router.post("/feedback/voice")
async def save_voice_feedback(payload: VoiceFeedbackCreate, db: AsyncSession = Depends(get_db)):
    row = VoiceFeedback(
        user_id=payload.user_id,
        source_transaction_id=payload.source_transaction_id,
        session_id=payload.session_id,
        raw_transcript=payload.raw_transcript,
        parsed_payload=json.dumps(payload.parsed_payload or {}, ensure_ascii=False),
        corrected_payload=json.dumps(payload.corrected_payload or {}, ensure_ascii=False),
        is_correct=payload.is_correct,
    )
    db.add(row)
    await db.flush()
    return {"saved": True, "feedback_id": row.id}


@router.post("/feedback/recommendation")
async def save_recommendation_feedback(
    payload: RecommendationFeedbackCreate, db: AsyncSession = Depends(get_db)
):
    insight = await db.get(Insight, payload.insight_id)
    if not insight or insight.user_id != payload.user_id:
        raise HTTPException(status_code=404, detail="Insight nahi mili")
    row = RecommendationFeedback(
        user_id=payload.user_id,
        insight_id=payload.insight_id,
        session_id=insight.session_id,
        recommendation_text=payload.recommendation_text,
        accepted=payload.accepted,
    )
    db.add(row)
    await db.flush()
    return {"saved": True, "feedback_id": row.id}


@router.get("/{user_id}/kpis", response_model=AdaptationKPIResponse)
async def adaptation_kpis(user_id: int, db: AsyncSession = Depends(get_db)):
    return {"user_id": user_id, **(await _kpis(user_id, db))}


@router.post("/{user_id}/ask", response_model=InsightAskResponse)
async def ask_insight_question(
    user_id: int,
    payload: InsightAskRequest,
    db: AsyncSession = Depends(get_db),
):
    rows = await _week_transactions(user_id, db)
    summary = insight_engine.calculate_weekly_summary(rows) if rows else {}
    insight_row = await db.scalar(
        select(Insight)
        .where(Insight.user_id == user_id)
        .order_by(desc(Insight.created_at))
        .limit(1)
    )
    context = {
        "summary": summary,
        "key_insight": insight_row.key_insight if insight_row else "",
        "recommendations": json.loads(insight_row.recommendations or "[]") if insight_row else [],
    }
    answer = await gemini_service.ask_finance_question(payload.question, context)
    return {"answer": answer}


@router.post("/{user_id}/learning/refine")
async def refine_learning(user_id: int, db: AsyncSession = Depends(get_db)):
    rows = await _week_transactions(user_id, db)
    if rows:
        await antigravity_agent.run_insight_workflow(user_id, rows, db)
        await cache_service.invalidate(f"insight:{user_id}:latest")
    return {"refined": True}


@router.post("/{user_id}/learning/clear")
async def clear_learning(user_id: int, db: AsyncSession = Depends(get_db)):
    await db.execute(delete(VoiceFeedback).where(VoiceFeedback.user_id == user_id))
    await db.execute(delete(RecommendationFeedback).where(RecommendationFeedback.user_id == user_id))
    return {"cleared": True}
