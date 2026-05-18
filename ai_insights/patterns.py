"""
Pattern detection over aggregated transaction data.
Each detector returns a list of Pattern dicts:
  {type, item, message, severity}   severity: "high" | "medium" | "low"
"""

from __future__ import annotations


# ── helpers ───────────────────────────────────────────────────────────────────

def _mean(values: list[float]) -> float:
    return sum(values) / len(values) if values else 0.0


# ── detectors ─────────────────────────────────────────────────────────────────

def detect_slow_day(daily_totals: list[dict], threshold: float = 0.70) -> list[dict]:
    """
    Flag weekdays whose average sales fall below `threshold` × overall mean.
    """
    if not daily_totals:
        return []

    avg_values = [d["avg_sales"] for d in daily_totals]
    overall_mean = _mean(avg_values)
    if overall_mean == 0:
        return []

    patterns = []
    for d in daily_totals:
        if d["avg_sales"] < overall_mean * threshold:
            patterns.append({
                "type": "slow_day",
                "item": None,
                "weekday": d["weekday_name"],
                "weekday_num": d["weekday_num"],
                "message": f"{d['weekday_name']} ko bikri hamesha kam rehti hai "
                           f"(avg Rs. {d['avg_sales']:.0f} vs mean Rs. {overall_mean:.0f})",
                "severity": "medium",
            })
    return patterns


def detect_margin_shrink(item_summary: list[dict], shrink_threshold: float = 0.10) -> list[dict]:
    """
    Flag items whose current margin is more than `shrink_threshold` below
    the overall average margin across all items this period.
    """
    items_with_margin = [i for i in item_summary if i["margin"] is not None]
    if len(items_with_margin) < 2:
        return []

    avg_margin = _mean([i["margin"] for i in items_with_margin])
    patterns = []
    for item in items_with_margin:
        if avg_margin > 0 and (avg_margin - item["margin"]) / avg_margin >= shrink_threshold:
            pct = round((avg_margin - item["margin"]) * 100, 1)
            patterns.append({
                "type": "margin_shrink",
                "item": item["item_name"],
                "weekday": None,
                "message": f"{item['item_name']} ka margin ghat raha hai "
                           f"(margin: {item['margin']*100:.1f}%, avg: {avg_margin*100:.1f}%)",
                "severity": "high" if pct >= 20 else "medium",
            })
    return patterns


def detect_top_seller(item_summary: list[dict]) -> list[dict]:
    """Flag the single highest-revenue item this week."""
    sellers = [i for i in item_summary if i["revenue"] > 0]
    if not sellers:
        return []
    top = sellers[0]  # already sorted by revenue DESC from db.py
    return [{
        "type": "top_seller",
        "item": top["item_name"],
        "weekday": None,
        "message": f"{top['item_name']} is hafte sab se ziada bika "
                   f"(Rs. {top['revenue']:.0f}, {top['qty_sold']:.0f} units)",
        "severity": "low",
    }]


def detect_dead_stock(
    current_summary: list[dict],
    all_transactions: list[dict],
) -> list[dict]:
    """
    Items that were sold before but have zero sales in the current window.
    """
    current_sold = {i["item_name"] for i in current_summary if i["revenue"] > 0}
    ever_sold = {t["item_name"] for t in all_transactions if t["type"] == "sale"}
    dead = ever_sold - current_sold

    return [
        {
            "type": "dead_stock",
            "item": item,
            "weekday": None,
            "message": f"{item} is hafte bilkul nahi bika — stock check karein",
            "severity": "medium",
        }
        for item in dead
    ]


def detect_sales_spike(daily_totals: list[dict], spike_factor: float = 2.0) -> list[dict]:
    """Flag any weekday whose avg sales exceed spike_factor × overall mean."""
    if not daily_totals:
        return []

    avg_values = [d["avg_sales"] for d in daily_totals]
    overall_mean = _mean(avg_values)
    if overall_mean == 0:
        return []

    patterns = []
    for d in daily_totals:
        if d["avg_sales"] >= overall_mean * spike_factor:
            patterns.append({
                "type": "sales_spike",
                "item": None,
                "weekday": d["weekday_name"],
                "weekday_num": d["weekday_num"],
                "message": f"{d['weekday_name']} ko bikri zyada hoti hai "
                           f"(avg Rs. {d['avg_sales']:.0f}) — yeh mauqa hai",
                "severity": "low",
            })
    return patterns


# ── public entry point ────────────────────────────────────────────────────────

def detect_patterns(
    daily_totals: list[dict],
    item_summary: list[dict],
    all_transactions: list[dict],
) -> list[dict]:
    """
    Run all detectors and return a deduplicated, severity-sorted pattern list.
    Severity order: high > medium > low
    """
    severity_rank = {"high": 0, "medium": 1, "low": 2}

    patterns: list[dict] = []
    patterns.extend(detect_margin_shrink(item_summary))
    patterns.extend(detect_slow_day(daily_totals))
    patterns.extend(detect_dead_stock(item_summary, all_transactions))
    patterns.extend(detect_sales_spike(daily_totals))
    patterns.extend(detect_top_seller(item_summary))

    patterns.sort(key=lambda p: severity_rank.get(p["severity"], 9))
    return patterns
