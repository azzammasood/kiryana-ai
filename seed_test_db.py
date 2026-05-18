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
    ("Atta",       18, 22),   # (item, cost/unit, sell/unit)
    ("Chawal",     90, 110),
    ("Chai patti", 400, 500),
    ("Daal",       120, 150),
    ("Tel",        300, 360),
    ("Namak",      50, 60),
    ("Sugar",      130, 155),
]

WEEKDAY_MULTIPLIERS = [0.6, 1.0, 1.1, 1.0, 0.5, 1.4, 1.2]  # Sun–Sat


def seed():
    conn = sqlite3.connect(DB_PATH)
    conn.executescript("""
        DROP TABLE IF EXISTS transactions;
        DROP TABLE IF EXISTS users;
        DROP TABLE IF EXISTS vendors;

        CREATE TABLE users (
            id INTEGER PRIMARY KEY,
            name TEXT,
            phone TEXT
        );

        CREATE TABLE vendors (
            id INTEGER PRIMARY KEY,
            name TEXT
        );

        CREATE TABLE transactions (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id     INTEGER,
            date        TEXT,
            item_name   TEXT,
            quantity    REAL,
            unit_price  REAL,
            total_amount REAL,
            type        TEXT CHECK(type IN ('sale','expense')),
            vendor_id   INTEGER
        );
    """)

    conn.execute("INSERT INTO users VALUES (?,?,?)", (USER_ID, "Haji Sahib", "+923001234567"))
    conn.execute("INSERT INTO vendors VALUES (?,?)", (1, "City Wholesale"))

    today = datetime.now()
    rows = []

    for days_back in range(35):
        date = (today - timedelta(days=days_back)).strftime("%Y-%m-%d")
        weekday = (today - timedelta(days=days_back)).weekday()  # Mon=0
        # map to Sun=0 for multipliers: Mon→1, Tue→2 ... Sun→0
        sqlite_weekday = (weekday + 1) % 7
        multiplier = WEEKDAY_MULTIPLIERS[sqlite_weekday]

        for item_name, cost_u, sell_u in ITEMS:
            if random.random() < 0.15:
                continue  # occasional missing day per item

            qty = round(random.uniform(2, 10) * multiplier, 1)

            # expense (purchase from vendor)
            rows.append((USER_ID, date, item_name, qty, cost_u, qty * cost_u, "expense", 1))
            # sale
            rows.append((USER_ID, date, item_name, qty, sell_u, qty * sell_u, "sale", None))

    conn.executemany(
        "INSERT INTO transactions (user_id,date,item_name,quantity,unit_price,total_amount,type,vendor_id) "
        "VALUES (?,?,?,?,?,?,?,?)",
        rows,
    )
    conn.commit()
    conn.close()
    print(f"Seeded {len(rows)} rows into {DB_PATH}")


def test_pipeline():
    from ai_insights import run_insight_pipeline
    import json

    result = run_insight_pipeline(user_id=USER_ID, db_path=DB_PATH)

    print("\n" + "="*60)
    print("WEEK TOTALS:")
    print(json.dumps(result["week_totals"], indent=2))

    print("\nPATTERNS DETECTED:")
    for p in result["patterns"]:
        print(f"  [{p['severity'].upper()}] {p['type']} — {p['message']}")

    print("\nRECOMMENDATIONS:")
    for r in result["recommendations"]:
        print(f"  ({r['source']}) {r['action_roman_urdu']}")

    print("\nWHATSAPP REPORT:")
    print("-"*40)
    print(result["report_text"])
    print("-"*40)


if __name__ == "__main__":
    seed()
    test_pipeline()
