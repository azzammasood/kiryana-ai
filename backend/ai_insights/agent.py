"""
Orchestrator — single entry point Ahmad calls from the backend.

Flow:  fetch → detect → recommend → report → save insight → save traces
Returns an InsightResponse-shaped dict ready to be returned directly from
Ahmad's POST /insights/generate/{user_id} endpoint.
"""

from __future__ import annotations
import uuid
from .db import (
    get_transactions,
    get_item_summary,
    get_daily_totals,
    get_week_totals,
    save_insight,
    save_agent_trace,
)
from .patterns import detect_patterns
from .recommender import get_recommendations
from .report import generate_report


def run_insight_pipeline(user_id: int, db_path: str) -> dict:
    """
    Returns an InsightResponse dict:
    {
        session_id, week_start, week_end,
        total_sales, total_expenses, profit,
        top_items:        [{item_name, amount}],
        recommendations:  ["اردو string", ...],
        key_insight:      "اردو string",
        report_text:      "WhatsApp message string",
    }
    Also writes one row to `insights` and one row per step to `agent_traces`.
    """
    session_id = str(uuid.uuid4())
    traces: list[tuple[str, str]] = []  # (label, detail) accumulated

    # ── 1 fetch ────────────────────────────────────────────────────────────────
    transactions = get_transactions(user_id, db_path, days=30)
    item_summary = get_item_summary(user_id, db_path, days=7)
    daily_totals = get_daily_totals(user_id, db_path, days=30)
    week_totals  = get_week_totals(user_id, db_path)

    traces.append((
        "fetch_data",
        f"{len(transactions)} transactions loaded | "
        f"week: {week_totals['week_start']} → {week_totals['week_end']}",
    ))

    # ── 2 detect ───────────────────────────────────────────────────────────────
    patterns = detect_patterns(daily_totals, item_summary, transactions)

    traces.append((
        "detect_patterns",
        f"{len(patterns)} patterns detected: "
        + ", ".join(p["type"] for p in patterns) if patterns else "none",
    ))

    # ── 3 recommend ────────────────────────────────────────────────────────────
    recommendations = get_recommendations(patterns)

    traces.append((
        "generate_recommendations",
        f"{len(recommendations)} recommendations generated",
    ))

    # ── 4 report ───────────────────────────────────────────────────────────────
    report_text = generate_report(week_totals, item_summary, patterns, recommendations)

    traces.append((
        "generate_report",
        f"report generated ({len(report_text)} chars)",
    ))

    # ── 5 shape output ─────────────────────────────────────────────────────────
    this = week_totals["this_week"]
    total_sales    = this["revenue"]
    total_expenses = this["expenses"]
    profit         = total_sales - total_expenses

    top_items = [
        {"item_name": i["item_name"], "amount": i["revenue"]}
        for i in item_summary
        if i["revenue"] > 0
    ][:5]

    recommendations_list = [r["action_urdu"] for r in recommendations]

    key_insight = patterns[0]["message"] if patterns else ""

    payload = {
        "session_id":      session_id,
        "week_start":      week_totals["week_start"],
        "week_end":        week_totals["week_end"],
        "total_sales":     total_sales,
        "total_expenses":  total_expenses,
        "profit":          profit,
        "top_items":       top_items,
        "recommendations": recommendations_list,
        "key_insight":     key_insight,
        "report_text":     report_text,
    }

    # ── 6 persist ──────────────────────────────────────────────────────────────
    try:
        insight_id = save_insight(user_id, db_path, payload)
        traces.append(("save_insight", f"insight saved — id: {insight_id}"))
    except Exception as exc:
        traces.append(("save_insight", f"failed: {exc}", ))

    for step_num, (label, detail) in enumerate(traces, start=1):
        try:
            save_agent_trace(user_id, db_path, session_id, step_num, label, detail)
        except Exception:
            pass  # trace failures must never break the response

    return payload
