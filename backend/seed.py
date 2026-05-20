from __future__ import annotations

import asyncio
from datetime import date, timedelta

import httpx

from database import AsyncSessionLocal
from models import Transaction, User


ITEMS = [
    ("atta", 5, "kg", 800),
    ("doodh", 2, "litre", 220),
    ("cheeni", 1, "kg", 160),
    ("chawal", 3, "kg", 540),
    ("tel", 1, "litre", 380),
    ("sabzi", 2, "kg", 200),
    ("namak", 1, "kg", 80),
    ("daal maash", 1, "kg", 280),
    ("biscuit", 1, "dozen", 120),
    ("thanda", 6, "piece", 180),
]


async def main():
    today = date.today()
    week_start = today - timedelta(days=today.weekday())
    created_ids = []
    async with AsyncSessionLocal() as db:
        user = User(id=1, phone_number="03001234567", name="Ali Dukaan")
        await db.merge(user)
        await db.flush()
        for idx in range(25):
            item, qty, unit, amount = ITEMS[idx % len(ITEMS)]
            tx_type = "expense" if idx % 10 in {1, 5, 8} else "sale"
            tx = Transaction(
                user_id=1,
                item_name=item,
                quantity=qty,
                unit=unit,
                amount=amount,
                transaction_type=tx_type,
                raw_text=f"{item} {qty} {unit} {'kharida' if tx_type == 'expense' else 'becha'} {amount} rupay",
                date=week_start + timedelta(days=idx % 7),
            )
            db.add(tx)
            await db.flush()
            created_ids.append(tx.id)
        await db.commit()

    insight_id = None
    async with httpx.AsyncClient(timeout=60) as client:
        response = await client.post("http://localhost:8000/insights/generate/1")
        if response.is_success:
            insight_id = response.json().get("id")
        else:
            print(f"Insight generation skipped/failed: {response.status_code} {response.text}")

    print(f"Created transaction IDs: {created_ids}")
    print(f"Insight ID: {insight_id}")
    print("Seed complete. User ID: 1. App is ready.")


if __name__ == "__main__":
    asyncio.run(main())
