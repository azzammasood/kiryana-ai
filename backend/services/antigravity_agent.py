from __future__ import annotations

import json
import logging
import re
import uuid

from google.cloud import aiplatform
from google.oauth2 import service_account
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from config import settings
from models import AgentTrace, Insight, RecommendationFeedback
from services import gemini_service, insight_engine


logger = logging.getLogger(__name__)


async def _log_step(
    db: AsyncSession,
    user_id: int,
    session_id: str,
    step_number: int,
    step_label: str,
    step_detail: str,
    status: str = "success",
) -> None:
    db.add(
        AgentTrace(
            user_id=user_id,
            session_id=session_id,
            step_number=step_number,
            step_label=step_label,
            step_detail=step_detail,
            status=status,
        )
    )
    await db.flush()


async def _try_vertex_agent(step_name: str) -> str:
    try:
        credentials = service_account.Credentials.from_service_account_file(
            settings.google_application_credentials,
            scopes=["https://www.googleapis.com/auth/cloud-platform"],
        )
        aiplatform.init(
            project=settings.google_cloud_project,
            location=settings.google_cloud_location,
            credentials=credentials,
        )
        raise RuntimeError("Vertex AI Agent Builder runtime endpoint is not configured for this prototype")
    except Exception as exc:
        logger.info("Vertex AI fallback for %s: %s", step_name, exc)
        return f"Vertex AI Agent Builder fallback used: {exc}"


def _keywords(text: str) -> set[str]:
    return {word for word in re.findall(r"[a-zA-Z]{4,}", text.lower()) if word not in {"your", "with", "this", "that"}}


async def _adapt_recommendations_with_feedback(
    user_id: int, recommendations: list[str], db: AsyncSession
) -> tuple[list[str], dict]:
    rows = (
        await db.scalars(
            select(RecommendationFeedback)
            .where(RecommendationFeedback.user_id == user_id)
            .order_by(desc(RecommendationFeedback.created_at))
            .limit(80)
        )
    ).all()
    if not rows:
        return recommendations[:3], {"accepted_samples": 0, "rejected_samples": 0}

    accepted = [row.recommendation_text for row in rows if row.accepted]
    rejected = [row.recommendation_text for row in rows if not row.accepted]
    rejected_words = set().union(*[_keywords(text) for text in rejected]) if rejected else set()

    adapted: list[str] = []
    for rec in recommendations:
        rec_words = _keywords(rec)
        if rec.lower() in {r.lower() for r in rejected}:
            continue
        if rejected_words and rec_words and len(rec_words & rejected_words) >= 2:
            continue
        adapted.append(rec)

    for preferred in accepted:
        if len(adapted) >= 3:
            break
        if preferred not in adapted:
            adapted.append(preferred)

    if not adapted:
        adapted = recommendations[:3]
    return adapted[:3], {"accepted_samples": len(accepted), "rejected_samples": len(rejected)}


def _contextual_key_insight(summary: dict, generated: dict) -> str:
    sales = float(summary.get("total_sales") or 0)
    expenses = float(summary.get("total_expenses") or 0)
    generated_key = (generated.get("key_insight") or "").strip()
    top_expenses = summary.get("top_expenses") or []
    if sales <= 0 and expenses > 0:
        lead_item = top_expenses[0]["item_name"] if top_expenses else "kharcha"
        return (
            f"Is hafte bikri zero hai, lekin Rs. {expenses:.0f} kharcha record hua "
            f"(jaise {lead_item}). Pehli sale log karein aur stock plan banayein."
        )
    if generated_key:
        return generated_key
    if sales > 0:
        return f"Is hafte bikri Rs. {sales:.0f} aur kharcha Rs. {expenses:.0f} record hua."
    return "Is hafte ka data stable raha."


async def run_insight_workflow(user_id: int, transactions: list, db: AsyncSession) -> dict:
    session_id = str(uuid.uuid4())
    week_start, week_end = insight_engine.current_week_range()

    await _log_step(
        db,
        user_id,
        session_id,
        1,
        "Data Collection",
        f"Collected {len(transactions)} transactions for analysis",
    )

    summary = insight_engine.calculate_weekly_summary(transactions)
    branch_insights = insight_engine.run_branch_insights(transactions)
    await _log_step(
        db,
        user_id,
        session_id,
        2,
        "Pattern Recognition",
        f"Computing totals with ai-insights branch rules. Patterns found: {len(branch_insights.get('patterns', []))}",
    )

    anomaly_detail = await _try_vertex_agent("Anomaly Detection")
    anomaly = await gemini_service.detect_anomalies(summary["transactions_list"])
    await _log_step(
        db,
        user_id,
        session_id,
        3,
        "Anomaly Detection",
        f"Scanning for unusual sales patterns. {anomaly_detail}. Observation: {anomaly or 'No major anomaly found.'}",
    )

    generation_detail = await _try_vertex_agent("Insight Generation")
    generated = await gemini_service.generate_insights(summary)
    await _log_step(
        db,
        user_id,
        session_id,
        4,
        "Insight Generation",
        f"Generating AI-powered business recommendations. {generation_detail}",
    )

    planning_detail = await _try_vertex_agent("Action Planning")
    recommendations = list(generated.get("recommendations", []))[:3]
    branch_recs = [
        rec.get("action_urdu")
        for rec in branch_insights.get("recommendations", [])
        if rec.get("action_urdu")
    ]
    for rec in branch_recs:
        if len(recommendations) >= 3:
            break
        if rec not in recommendations:
            recommendations.append(rec)
    if anomaly:
        trend_tip = anomaly.strip()
        if trend_tip.lower().startswith("trend check:"):
            trend_tip = trend_tip.split(":", 1)[-1].strip()
        if trend_tip and trend_tip not in recommendations:
            recommendations = [*recommendations[:2], trend_tip][:3]
    recommendations, feedback_stats = await _adapt_recommendations_with_feedback(
        user_id, recommendations, db
    )
    await _log_step(
        db,
        user_id,
        session_id,
        5,
        "Action Planning",
        "Structuring recommendations into actionable steps. "
        f"{planning_detail}. Adapted with feedback "
        f"(accepted={feedback_stats['accepted_samples']}, rejected={feedback_stats['rejected_samples']}).",
    )

    report_text = generated.get("report_text") or branch_insights.get("report_text") or (
        f"Assalam o Alaikum, is hafte bikri Rs. {summary['total_sales']:.0f}, "
        f"kharcha Rs. {summary['total_expenses']:.0f}, aur faida Rs. {summary['profit']:.0f} raha."
    )
    await _log_step(
        db,
        user_id,
        session_id,
        6,
        "Report Compilation",
        "Compiling weekly WhatsApp report",
    )

    insight = Insight(
        user_id=user_id,
        session_id=session_id,
        week_start=week_start,
        week_end=week_end,
        total_sales=summary["total_sales"],
        total_expenses=summary["total_expenses"],
        profit=summary["profit"],
        top_items=json.dumps(summary["top_items"], ensure_ascii=False),
        recommendations=json.dumps(recommendations, ensure_ascii=False),
        key_insight=_contextual_key_insight(summary, generated)
        or (branch_insights.get("patterns") or [{}])[0].get("message")
        or anomaly
        or "Is hafte ka data stable raha.",
        report_text=report_text,
    )
    db.add(insight)
    await db.flush()
    await db.refresh(insight)

    await _log_step(
        db,
        user_id,
        session_id,
        7,
        "Execution Complete",
        "Insight saved to database. Report ready.",
    )

    return {
        "id": insight.id,
        "user_id": insight.user_id,
        "session_id": insight.session_id,
        "week_start": insight.week_start,
        "week_end": insight.week_end,
        "total_sales": insight.total_sales,
        "total_expenses": insight.total_expenses,
        "profit": insight.profit,
        "top_items": summary["top_items"],
        "top_expenses": summary.get("top_expenses", []),
        "recommendations": recommendations,
        "key_insight": insight.key_insight,
        "report_text": insight.report_text,
        "created_at": insight.created_at,
    }
