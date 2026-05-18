"""
Orchestrator — single entry point Ahmad calls from the backend.

Flow:  fetch data → detect patterns → get recommendations → generate report
"""

from __future__ import annotations
from .db import get_transactions, get_item_summary, get_daily_totals, get_week_totals
from .patterns import detect_patterns
from .recommender import get_recommendations
from .report import generate_report


def run_insight_pipeline(user_id: int, db_path: str) -> dict:
    """
    Returns:
    {
        "patterns":        list[dict],   # detected business patterns
        "recommendations": list[dict],   # one action per pattern
        "report_text":     str,          # WhatsApp-ready Roman Urdu message
        "top_insight":     dict | None,  # highest-severity pattern (for frontend card)
        "week_totals":     dict,         # revenue / expenses / profit summary
    }
    """
    # 1 — fetch
    transactions  = get_transactions(user_id, db_path, days=30)
    item_summary  = get_item_summary(user_id, db_path, days=7)
    daily_totals  = get_daily_totals(user_id, db_path, days=30)
    week_totals   = get_week_totals(user_id, db_path)

    # 2 — detect
    patterns = detect_patterns(daily_totals, item_summary, transactions)

    # 3 — recommend
    recommendations = get_recommendations(patterns)

    # 4 — report
    report_text = generate_report(week_totals, item_summary, patterns, recommendations)

    return {
        "patterns":        patterns,
        "recommendations": recommendations,
        "report_text":     report_text,
        "top_insight":     patterns[0] if patterns else None,
        "week_totals":     {
            "revenue":  week_totals["this_week"]["revenue"],
            "expenses": week_totals["this_week"]["expenses"],
            "profit":   week_totals["this_week"]["revenue"] - week_totals["this_week"]["expenses"],
        },
    }
