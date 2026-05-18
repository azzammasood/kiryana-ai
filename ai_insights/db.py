import json
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
            SELECT id, date, item_name, quantity, amount, transaction_type
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
    revenue  = sum of amount where transaction_type='sale'
    cost     = sum of amount where transaction_type='expense'
    margin   = (revenue - cost) / revenue  (None when revenue is 0)
    """
    cutoff = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")
    with _connect(db_path) as conn:
        rows = conn.execute(
            """
            SELECT
                item_name,
                SUM(CASE WHEN transaction_type='sale'    THEN amount ELSE 0 END) AS revenue,
                SUM(CASE WHEN transaction_type='expense' THEN amount ELSE 0 END) AS cost,
                SUM(CASE WHEN transaction_type='sale'    THEN quantity ELSE 0 END) AS qty_sold
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
    weekday_names = ["اتوار", "سوموار", "منگل", "بدھ", "جمعرات", "جمعہ", "ہفتہ"]
    with _connect(db_path) as conn:
        rows = conn.execute(
            """
            SELECT
                CAST(strftime('%w', date) AS INTEGER) AS weekday_num,
                AVG(daily_total) AS avg_sales
            FROM (
                SELECT date,
                       SUM(CASE WHEN transaction_type='sale' THEN amount ELSE 0 END) AS daily_total
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
                SUM(CASE WHEN transaction_type='sale'    THEN amount ELSE 0 END) AS revenue,
                SUM(CASE WHEN transaction_type='expense' THEN amount ELSE 0 END) AS cost
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
                    SUM(CASE WHEN transaction_type='sale'    THEN amount ELSE 0 END) AS revenue,
                    SUM(CASE WHEN transaction_type='expense' THEN amount ELSE 0 END) AS expenses
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
            "week_start": this_monday,
            "week_end": today_str,
        }


def save_insight(user_id: int, db_path: str, payload: dict) -> int:
    """Write one row to the insights table. Returns the new row id."""
    with _connect(db_path) as conn:
        cursor = conn.execute(
            """
            INSERT INTO insights
                (user_id, session_id, week_start, week_end,
                 total_sales, total_expenses, profit,
                 top_items, recommendations, key_insight, report_text)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                user_id,
                payload["session_id"],
                payload["week_start"],
                payload["week_end"],
                payload["total_sales"],
                payload["total_expenses"],
                payload["profit"],
                json.dumps(payload["top_items"], ensure_ascii=False),
                json.dumps(payload["recommendations"], ensure_ascii=False),
                payload["key_insight"],
                payload["report_text"],
            ),
        )
        return cursor.lastrowid


def save_agent_trace(
    user_id: int,
    db_path: str,
    session_id: str,
    step_number: int,
    step_label: str,
    step_detail: str,
    status: str = "success",
) -> None:
    with _connect(db_path) as conn:
        conn.execute(
            """
            INSERT INTO agent_traces
                (user_id, session_id, step_number, step_label, step_detail, status)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (user_id, session_id, step_number, step_label, step_detail, status),
        )
