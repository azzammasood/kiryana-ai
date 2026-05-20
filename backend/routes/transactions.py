from __future__ import annotations

from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import delete, desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models import Transaction
from schemas import SummaryResponse, TransactionCreate, TransactionResponse
from services import cache_service


router = APIRouter()


def _range_for_filter(value: str) -> date:
    today = date.today()
    if value == "today":
        return today
    if value == "month":
        return today.replace(day=1)
    return today - timedelta(days=today.weekday())


def _transaction_dict(row: Transaction) -> dict:
    return TransactionResponse.model_validate(row).model_dump(mode="json")


async def _invalidate_user(user_id: int):
    await cache_service.invalidate(f"summary:{user_id}")
    await cache_service.invalidate_pattern(f"transactions:{user_id}:*")


@router.post("/", response_model=TransactionResponse)
async def create_transaction(payload: TransactionCreate, db: AsyncSession = Depends(get_db)):
    tx = Transaction(**payload.model_dump())
    db.add(tx)
    await db.flush()
    await db.refresh(tx)
    await _invalidate_user(tx.user_id)
    return tx


@router.get("/{user_id}", response_model=list[TransactionResponse])
async def get_transactions(
    user_id: int,
    filter: str = Query("week", pattern="^(today|week|month)$"),
    db: AsyncSession = Depends(get_db),
):
    cache_key = f"transactions:{user_id}:{filter}"
    cached = await cache_service.get_cached(cache_key)
    if cached is not None:
        return cached
    start = _range_for_filter(filter)
    rows = (
        await db.scalars(
            select(Transaction)
            .where(Transaction.user_id == user_id, Transaction.date >= start)
            .order_by(desc(Transaction.created_at))
        )
    ).all()
    result = [_transaction_dict(row) for row in rows]
    await cache_service.set_cached(cache_key, result, ttl_seconds=180)
    return result


@router.get("/{user_id}/summary", response_model=SummaryResponse)
async def get_summary(user_id: int, db: AsyncSession = Depends(get_db)):
    cache_key = f"summary:{user_id}"
    cached = await cache_service.get_cached(cache_key)
    if cached is not None:
        return cached
    today = date.today()
    rows = (
        await db.scalars(
            select(Transaction).where(Transaction.user_id == user_id, Transaction.date == today)
        )
    ).all()
    sales = sum(t.amount for t in rows if t.transaction_type == "sale")
    expenses = sum(t.amount for t in rows if t.transaction_type == "expense")
    result = {
        "today_sales": sales,
        "today_expenses": expenses,
        "today_profit": sales - expenses,
        "transaction_count": len(rows),
    }
    await cache_service.set_cached(cache_key, result, ttl_seconds=300)
    return result


@router.get("/{user_id}/recent", response_model=list[TransactionResponse])
async def get_recent(user_id: int, db: AsyncSession = Depends(get_db)):
    rows = (
        await db.scalars(
            select(Transaction)
            .where(Transaction.user_id == user_id)
            .order_by(desc(Transaction.created_at))
            .limit(3)
        )
    ).all()
    return [_transaction_dict(row) for row in rows]


@router.delete("/{transaction_id}")
async def delete_transaction(transaction_id: int, db: AsyncSession = Depends(get_db)):
    tx = await db.get(Transaction, transaction_id)
    if not tx:
        raise HTTPException(status_code=404, detail="Transaction nahi mili")
    user_id = tx.user_id
    await db.execute(delete(Transaction).where(Transaction.id == transaction_id))
    await _invalidate_user(user_id)
    return {"deleted": True}
