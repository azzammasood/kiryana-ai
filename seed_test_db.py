"""
Run this once to create test.db with realistic sample data, then test the pipeline.
Usage:  python seed_test_db.py
"""

import sqlite3
import random
from datetime import datetime, timedelta

DB_PATH = "test.db"
USER_ID = 1

ITEMS = [
    ("آٹا",       18, 22),   # (item, cost/unit, sell/unit)
    ("چاول",      90, 110),
    ("چائے پتی",  400, 500),
    ("دال",       120, 150),
    ("تیل",       300, 360),
    ("نمک",       50, 60),
    ("چینی",      130, 155),
]

WEEKDAY_MULTIPLIERS = [0.6, 1.0, 1.1, 1.0, 0.5, 1.4, 1.2]  # Sun–Sat


def seed():
    conn = sqlite3.connect(DB_PATH)
    conn.executescript("""
        DROP TABLE IF EXISTS agent_traces;
        DROP TABLE IF EXISTS insights;
        DROP TABLE IF EXISTS transactions;
        DROP TABLE IF EXISTS users;

        CREATE TABLE users (
            id                   INTEGER PRIMARY KEY,
            phone_number         TEXT UNIQUE,
            name                 TEXT DEFAULT 'Dukandaar',
            language             TEXT DEFAULT 'ur',
            notification_day     TEXT DEFAULT 'Sunday',
            notification_time    TEXT DEFAULT '10:00',
            notifications_enabled INTEGER DEFAULT 1,
            created_at           TEXT DEFAULT (datetime('now'))
        );

        CREATE TABLE transactions (
            id               INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id          INTEGER NOT NULL,
            item_name        TEXT NOT NULL,
            quantity         REAL,
            unit             TEXT,
            amount           REAL NOT NULL,
            transaction_type TEXT NOT NULL CHECK(transaction_type IN ('sale', 'expense')),
            raw_text         TEXT,
            audio_url        TEXT,
            date             TEXT NOT NULL,
            created_at       TEXT DEFAULT (datetime('now'))
        );

        CREATE TABLE insights (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id         INTEGER NOT NULL,
            session_id      TEXT NOT NULL,
            week_start      TEXT NOT NULL,
            week_end        TEXT NOT NULL,
            total_sales     REAL NOT NULL,
            total_expenses  REAL NOT NULL,
            profit          REAL NOT NULL,
            top_items       TEXT,
            recommendations TEXT,
            key_insight     TEXT,
            report_text     TEXT,
            created_at      TEXT DEFAULT (datetime('now'))
        );

        CREATE TABLE agent_traces (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id     INTEGER NOT NULL,
            session_id  TEXT NOT NULL,
            step_number INTEGER NOT NULL,
            step_label  TEXT NOT NULL,
            step_detail TEXT,
            status      TEXT DEFAULT 'success',
            created_at  TEXT DEFAULT (datetime('now'))
        );
    """)

    conn.execute(
        "INSERT INTO users (id, phone_number, name) VALUES (?,?,?)",
        (USER_ID, "+923001234567", "حاجی صاحب"),
    )

    today = datetime.now()
    rows = []

    for days_back in range(35):
        date = (today - timedelta(days=days_back)).strftime("%Y-%m-%d")
        weekday = (today - timedelta(days=days_back)).weekday()  # Mon=0
        sqlite_weekday = (weekday + 1) % 7  # Sun=0
        multiplier = WEEKDAY_MULTIPLIERS[sqlite_weekday]

        for item_name, cost_u, sell_u in ITEMS:
            if random.random() < 0.15:
                continue

            qty = round(random.uniform(2, 10) * multiplier, 1)

            rows.append((USER_ID, item_name, qty, "kg", qty * cost_u, "expense", date))
            rows.append((USER_ID, item_name, qty, "kg", qty * sell_u, "sale",    date))

    conn.executemany(
        "INSERT INTO transactions (user_id, item_name, quantity, unit, amount, transaction_type, date) "
        "VALUES (?,?,?,?,?,?,?)",
        rows,
    )
    conn.commit()
    conn.close()
    print(f"Seeded {len(rows)} rows into {DB_PATH}")


def test_pipeline():
    import json
    from ai_insights import run_insight_pipeline

    result = run_insight_pipeline(user_id=USER_ID, db_path=DB_PATH)

    print("\n" + "="*60)
    print("WEEK TOTALS:")
    print(f"  Sales:    Rs. {result['total_sales']:,.0f}")
    print(f"  Expenses: Rs. {result['total_expenses']:,.0f}")
    print(f"  Profit:   Rs. {result['profit']:,.0f}")
    print(f"  Week:     {result['week_start']} → {result['week_end']}")
    print(f"  Session:  {result['session_id']}")

    print("\nTOP ITEMS:")
    for i in result["top_items"]:
        print(f"  {i['item_name']} — Rs. {i['amount']:,.0f}")

    print("\nKEY INSIGHT:")
    print(f"  {result['key_insight']}")

    print("\nRECOMMENDATIONS:")
    for r in result["recommendations"]:
        print(f"  • {r}")

    print("\nWHATSAPP REPORT:")
    print("-"*50)
    print(result["report_text"])
    print("-"*50)

    # verify it was saved to DB
    conn = sqlite3.connect(DB_PATH)
    saved = conn.execute(
        "SELECT id, session_id FROM insights WHERE user_id=? ORDER BY id DESC LIMIT 1",
        (USER_ID,),
    ).fetchone()
    traces = conn.execute(
        "SELECT step_number, step_label, step_detail FROM agent_traces WHERE session_id=? ORDER BY step_number",
        (result["session_id"],),
    ).fetchall()
    conn.close()

    print(f"\nSAVED TO DB: insights.id={saved[0]}")
    print("AGENT TRACES:")
    for t in traces:
        print(f"  [{t[0]}] {t[1]}: {t[2]}")


if __name__ == "__main__":
    seed()
    test_pipeline()
