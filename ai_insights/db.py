import sqlite3
from datetime import datetime, timedelta


def _connect(db_path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def get_transactions(user_id: int, db_path: str, days: int = 7) -> list[dict]:
    cutoff = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")
    with _connect(db_path) as conn:
        rows = conn.execute(
            """
            SELECT id, date, item_name, quantity, unit_price, total_amount, type, vendor_id
            FROM transactions
            WHERE user_id = ? AND date >= ?
            ORDER BY date DESC
            """,
            (user_id, cutoff),
        ).fetchall()
    return [dict(r) for r in rows]


def get_item_summary(user_id: int, db_path: str, days: int = 7) -> list[dict]:
    """
    Per-item totals for the window.
    revenue  = sum of total_amount where type='sale'
    cost     = sum of total_amount where type='expense'
    margin   = (revenue - cost) / revenue  (None when revenue is 0)
    """
    cutoff = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")
    with _connect(db_path) as conn:
        rows = conn.execute(
            """
            SELECT
                item_name,
                SUM(CASE WHEN type='sale'    THEN total_amount ELSE 0 END) AS revenue,
                SUM(CASE WHEN type='expense' THEN total_amount ELSE 0 END) AS cost,
                SUM(CASE WHEN type='sale'    THEN quantity     ELSE 0 END) AS qty_sold
            FROM transactions
            WHERE user_id = ? AND date >= ?
            GROUP BY item_name
            ORDER BY revenue DESC
            """,
            (user_id, cutoff),
        ).fetchall()

    results = []
    for r in rows:
        d = dict(r)
        rev = d["revenue"] or 0
        cost = d["cost"] or 0
        d["margin"] = round((rev - cost) / rev, 4) if rev > 0 else None
        results.append(d)
    return results


def get_daily_totals(user_id: int, db_path: str, days: int = 30) -> list[dict]:
    """
    Average daily sales grouped by weekday (0=Sunday … 6=Saturday, SQLite strftime).
    Returns list of {weekday_num, weekday_name, avg_sales}.
    """
    cutoff = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")
    weekday_names = ["Itwar", "Somwar", "Mangal", "Budh", "Jumerat", "Juma", "Hafta"]
    with _connect(db_path) as conn:
        rows = conn.execute(
            """
            SELECT
                CAST(strftime('%w', date) AS INTEGER) AS weekday_num,
                AVG(daily_total) AS avg_sales
            FROM (
                SELECT date,
                       SUM(CASE WHEN type='sale' THEN total_amount ELSE 0 END) AS daily_total
                FROM transactions
                WHERE user_id = ? AND date >= ?
                GROUP BY date
            )
            GROUP BY weekday_num
            ORDER BY weekday_num
            """,
            (user_id, cutoff),
        ).fetchall()

    return [
        {
            "weekday_num": r["weekday_num"],
            "weekday_name": weekday_names[r["weekday_num"]],
            "avg_sales": round(r["avg_sales"] or 0, 2),
        }
        for r in rows
    ]


def get_item_margin_trend(user_id: int, db_path: str, item_name: str) -> list[dict]:
    """Weekly margin for a specific item over the last 8 weeks."""
    with _connect(db_path) as conn:
        rows = conn.execute(
            """
            SELECT
                strftime('%Y-W%W', date) AS week,
                SUM(CASE WHEN type='sale'    THEN total_amount ELSE 0 END) AS revenue,
                SUM(CASE WHEN type='expense' THEN total_amount ELSE 0 END) AS cost
            FROM transactions
            WHERE user_id = ? AND item_name = ?
              AND date >= date('now', '-56 days')
            GROUP BY week
            ORDER BY week
            """,
            (user_id, item_name),
        ).fetchall()

    results = []
    for r in rows:
        rev = r["revenue"] or 0
        cost = r["cost"] or 0
        results.append({
            "week": r["week"],
            "margin": round((rev - cost) / rev, 4) if rev > 0 else None,
        })
    return results


def get_week_totals(user_id: int, db_path: str) -> dict:
    """Current-week and previous-week revenue / expense totals."""
    with _connect(db_path) as conn:
        def _totals(start: str, end: str) -> dict:
            row = conn.execute(
                """
                SELECT
                    SUM(CASE WHEN type='sale'    THEN total_amount ELSE 0 END) AS revenue,
                    SUM(CASE WHEN type='expense' THEN total_amount ELSE 0 END) AS expenses
                FROM transactions
                WHERE user_id = ? AND date BETWEEN ? AND ?
                """,
                (user_id, start, end),
            ).fetchone()
            return {
                "revenue": row["revenue"] or 0,
                "expenses": row["expenses"] or 0,
            }

        today = datetime.now()
        # week starts Monday
        this_monday = (today - timedelta(days=today.weekday())).strftime("%Y-%m-%d")
        last_monday = (today - timedelta(days=today.weekday() + 7)).strftime("%Y-%m-%d")
        last_sunday = (today - timedelta(days=today.weekday() + 1)).strftime("%Y-%m-%d")
        today_str = today.strftime("%Y-%m-%d")

        return {
            "this_week": _totals(this_monday, today_str),
            "last_week": _totals(last_monday, last_sunday),
        }
