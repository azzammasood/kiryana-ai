"""
Weekly profit/loss report generator.
Produces a WhatsApp-ready Roman Urdu message string.
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
    Returns a formatted Roman Urdu WhatsApp message.

    week_totals  : {"this_week": {"revenue": X, "expenses": Y}, "last_week": {...}}
    item_summary : list from db.get_item_summary()
    patterns     : list from patterns.detect_patterns()
    recommendations: list from recommender.get_recommendations()
    """
    this = week_totals.get("this_week", {})
    last = week_totals.get("last_week", {})

    revenue  = this.get("revenue", 0)
    expenses = this.get("expenses", 0)
    profit   = revenue - expenses

    last_profit = last.get("revenue", 0) - last.get("expenses", 0)

    # profit trend
    if last_profit > 0:
        change_pct = ((profit - last_profit) / last_profit) * 100
        if change_pct >= 5:
            trend_line = f"📈 Pichle hafte se {change_pct:.0f}% zyada munafa"
        elif change_pct <= -5:
            trend_line = f"📉 Pichle hafte se {abs(change_pct):.0f}% kam munafa"
        else:
            trend_line = "➡️ Pichle hafte jaisa hi munafa raha"
    else:
        trend_line = ""

    # top items section
    top = _top_items(item_summary)
    top_lines = ""
    if top:
        top_lines = "\n\n🏆 *Sab se ziada bikne wali cheezein:*"
        for idx, item in enumerate(top, 1):
            top_lines += f"\n{idx}. {item['item_name']} — {_format_amount(item['revenue'])}"

    # top insight + recommendation
    insight_line = ""
    rec_line = ""
    if patterns:
        p = patterns[0]  # highest severity first
        insight_line = f"\n\n💡 *Insight:* {p['message']}"
    if recommendations:
        r = recommendations[0]
        rec_line = f"\n✅ *Mashwara:* {r['action_roman_urdu']}"

    profit_emoji = "📈" if profit >= 0 else "📉"
    profit_label = "Munafa" if profit >= 0 else "Nuqsan"

    lines = [
        "📊 *Hafte Ki Report*",
        "",
        f"💰 Kamai:   {_format_amount(revenue)}",
        f"💸 Kharcha: {_format_amount(expenses)}",
        f"{profit_emoji} {profit_label}: {_format_amount(abs(profit))}",
    ]

    if trend_line:
        lines.append(trend_line)

    report = "\n".join(lines)
    report += top_lines
    report += insight_line
    report += rec_line

    return report
