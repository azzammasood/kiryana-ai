from __future__ import annotations

from collections import defaultdict
from datetime import date, timedelta
import sys

from paths import resolve_repo_root


REPO_ROOT = resolve_repo_root()
if str(REPO_ROOT) not in sys.path:
    sys.path.append(str(REPO_ROOT))


def current_week_range(today: date | None = None) -> tuple[date, date]:
    today = today or date.today()
    start = today - timedelta(days=today.weekday())
    return start, start + timedelta(days=6)


def calculate_weekly_summary(transactions: list) -> dict:
    total_sales = sum(float(t.amount) for t in transactions if t.transaction_type == "sale")
    total_expenses = sum(float(t.amount) for t in transactions if t.transaction_type == "expense")
    profit = total_sales - total_expenses
    sale_totals: dict[str, float] = defaultdict(float)
    expense_totals: dict[str, float] = defaultdict(float)
    for t in transactions:
        if t.transaction_type == "sale":
            sale_totals[t.item_name] += float(t.amount)
        elif t.transaction_type == "expense":
            expense_totals[t.item_name] += float(t.amount)
    top_items = [
        {"item_name": name, "amount": amount, "kind": "sale"}
        for name, amount in sorted(sale_totals.items(), key=lambda row: row[1], reverse=True)[:5]
    ]
    top_expenses = [
        {"item_name": name, "amount": amount, "kind": "expense"}
        for name, amount in sorted(expense_totals.items(), key=lambda row: row[1], reverse=True)[:5]
    ]
    transactions_list = [
        {
            "item_name": t.item_name,
            "quantity": t.quantity,
            "unit": t.unit,
            "amount": t.amount,
            "transaction_type": t.transaction_type,
            "date": str(t.date),
        }
        for t in transactions
    ]
    return {
        "total_sales": total_sales,
        "total_expenses": total_expenses,
        "profit": profit,
        "top_items": top_items,
        "top_expenses": top_expenses,
        "transactions_list": transactions_list,
    }


def short_term_trend_observation(transactions_list: list[dict]) -> str:
    """Roman Urdu trend tip from even 1–2 days of ledger data."""
    if not transactions_list:
        return (
            "Abhi kam entries hain — rozana voice se sale/expense log karein taake trend clear ho."
        )

    by_date: dict[str, dict[str, float]] = defaultdict(lambda: {"sale": 0.0, "expense": 0.0})
    item_sales: dict[str, float] = defaultdict(float)

    for row in transactions_list:
        if not isinstance(row, dict):
            continue
        day = str(row.get("date") or "")[:10] or "unknown"
        amount = float(row.get("amount") or 0)
        tx_type = row.get("transaction_type") or "sale"
        if tx_type == "sale":
            by_date[day]["sale"] += amount
            item_sales[str(row.get("item_name") or "item")] += amount
        else:
            by_date[day]["expense"] += amount

    dates = sorted(d for d in by_date.keys() if d != "unknown")
    top_name, top_amount = (
        max(item_sales.items(), key=lambda pair: pair[1]) if item_sales else (None, 0.0)
    )

    if len(dates) >= 2:
        first, last = dates[0], dates[-1]
        sales_delta = by_date[last]["sale"] - by_date[first]["sale"]
        if sales_delta > 0:
            return (
                f"Pehle din se aakhri din tak bikri barh rahi hai (taqreeban Rs. {sales_delta:.0f}). "
                f"Is rujhan ko barqarar rakhein."
            )
        if sales_delta < 0:
            return (
                f"Bikri pehle din se kam ho rahi hai (taqreeban Rs. {abs(sales_delta):.0f}). "
                "Counter display aur rate board check karein."
            )
        return "Do din ki bikri barabar hai — top items ka stock ready rakhein."

    if top_name and top_amount > 0:
        return (
            f"{top_name} ab tak sab se zyada bikne wali cheez hai (Rs. {top_amount:.0f}). "
            "Is item ka stock zyada rakhein."
        )

    total_sale = sum(v["sale"] for v in by_date.values())
    total_exp = sum(v["expense"] for v in by_date.values())
    if total_sale > total_exp:
        return "Choti data set mein bikri kharchay se zyada hai — acha shuruat hai, rozana log jari rakhein."
    return "Rozana 2–3 voice entries se 1 hafte mein strong trend ban jayega."


def run_branch_insights(transactions: list) -> dict:
    try:
        from ai_insights.patterns import detect_patterns
        from ai_insights.recommender import get_recommendations
        from ai_insights.report import generate_report
    except Exception as exc:
        return {"patterns": [], "recommendations": [], "report_text": "", "error": str(exc)}

    by_weekday: dict[int, dict] = {}
    item_summary: dict[str, dict] = {}
    all_transactions = []
    for t in transactions:
        weekday = t.date.weekday() + 1
        bucket = by_weekday.setdefault(
            weekday,
            {"weekday_num": weekday, "weekday_name": t.date.strftime("%A"), "avg_sales": 0.0, "_days": set()},
        )
        bucket["_days"].add(t.date)
        if t.transaction_type == "sale":
            bucket["avg_sales"] += float(t.amount)

        item = item_summary.setdefault(
            t.item_name,
            {"item_name": t.item_name, "revenue": 0.0, "qty_sold": 0.0, "cost": 0.0, "margin": None},
        )
        if t.transaction_type == "sale":
            item["revenue"] += float(t.amount)
            item["qty_sold"] += float(t.quantity or 1)
        else:
            item["cost"] += float(t.amount)

        all_transactions.append(
            {
                "item_name": t.item_name,
                "transaction_type": t.transaction_type,
                "amount": float(t.amount),
                "quantity": float(t.quantity or 0),
                "date": str(t.date),
            }
        )

    daily_totals = []
    for bucket in by_weekday.values():
        day_count = max(len(bucket.pop("_days")), 1)
        bucket["avg_sales"] = bucket["avg_sales"] / day_count
        daily_totals.append(bucket)

    items = []
    for item in item_summary.values():
        if item["revenue"] > 0:
            item["margin"] = (item["revenue"] - item["cost"]) / item["revenue"]
        items.append(item)
    items.sort(key=lambda row: row["revenue"], reverse=True)

    patterns = detect_patterns(daily_totals, items, all_transactions)
    recommendations = get_recommendations(patterns)
    summary = calculate_weekly_summary(transactions)
    report_text = generate_report(
        {
            "this_week": {"revenue": summary["total_sales"], "expenses": summary["total_expenses"]},
            "last_week": {"revenue": 0, "expenses": 0},
        },
        items,
        patterns,
        recommendations,
    )
    return {"patterns": patterns, "recommendations": recommendations, "report_text": report_text}
