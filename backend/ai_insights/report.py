"""
Weekly profit/loss report generator.
Produces a WhatsApp-ready message matching Ahmad's expected report_text format:
  English header with numbers + Urdu script for insights and recommendations.
"""

from __future__ import annotations


def _top_items(item_summary: list[dict], n: int = 3) -> list[dict]:
    return [i for i in item_summary if i["revenue"] > 0][:n]


def _format_amount(amount: float) -> str:
    return f"Rs. {amount:,.0f}"


def generate_report(
    week_totals: dict,
    item_summary: list[dict],
    patterns: list[dict],
    recommendations: list[dict],
) -> str:
    """
    Returns a formatted WhatsApp message string.

    week_totals    : from db.get_week_totals()
    item_summary   : from db.get_item_summary()
    patterns       : from patterns.detect_patterns()
    recommendations: from recommender.get_recommendations()
    """
    this = week_totals.get("this_week", {})
    last = week_totals.get("last_week", {})

    revenue  = this.get("revenue", 0)
    expenses = this.get("expenses", 0)
    profit   = revenue - expenses

    last_profit = last.get("revenue", 0) - last.get("expenses", 0)

    # profit trend line
    if last_profit > 0:
        change_pct = ((profit - last_profit) / last_profit) * 100
        if change_pct >= 5:
            trend_line = f"Trend: +{change_pct:.0f}% vs last week"
        elif change_pct <= -5:
            trend_line = f"Trend: {change_pct:.0f}% vs last week"
        else:
            trend_line = "Trend: Similar to last week"
    else:
        trend_line = ""

    # top items
    top = _top_items(item_summary)
    top_lines = ""
    if top:
        top_lines = "\nTop items: " + ", ".join(
            f"{i['item_name']} ({_format_amount(i['revenue'])})" for i in top
        )

    # Urdu insight + recommendation
    insight_line = ""
    rec_line = ""
    if patterns:
        insight_line = f"\n\nاہم بات: {patterns[0]['message']}"
    if recommendations:
        rec_line = f"\nعملی مشورہ: {recommendations[0]['action_urdu']}"

    profit_label = "Profit" if profit >= 0 else "Loss"

    lines = [
        "📊 KiryanaAI Weekly Report",
        f"Sales:    {_format_amount(revenue)}",
        f"Expenses: {_format_amount(expenses)}",
        f"{profit_label}: {_format_amount(abs(profit))}",
    ]

    if trend_line:
        lines.append(trend_line)

    report = "\n".join(lines)
    report += top_lines
    report += insight_line
    report += rec_line

    return report
