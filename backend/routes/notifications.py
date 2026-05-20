from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models import Insight, User
from schemas import NotificationSettings, NotificationSettingsResponse
from services import whatsapp_service


router = APIRouter()


@router.post("/whatsapp/{user_id}")
async def send_whatsapp(user_id: int, db: AsyncSession = Depends(get_db)):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User nahi mila")
    insight = await db.scalar(
        select(Insight)
        .where(Insight.user_id == user_id)
        .order_by(desc(Insight.created_at))
        .limit(1)
    )
    if not insight:
        raise HTTPException(status_code=400, detail="Pehle report generate karen")
    payload = whatsapp_service.insight_to_dict(insight)
    message = whatsapp_service.format_report_for_whatsapp(payload)
    return whatsapp_service.send_whatsapp_message(user.phone_number, message)


@router.put("/settings/{user_id}", response_model=NotificationSettingsResponse)
async def update_settings(user_id: int, payload: NotificationSettings, db: AsyncSession = Depends(get_db)):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User nahi mila")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(user, key, value)
    await db.flush()
    await db.refresh(user)
    return NotificationSettingsResponse(
        user_id=user.id,
        notification_day=user.notification_day,
        notification_time=user.notification_time,
        notifications_enabled=user.notifications_enabled,
    )


@router.get("/settings/{user_id}", response_model=NotificationSettingsResponse)
async def get_settings(user_id: int, db: AsyncSession = Depends(get_db)):
    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User nahi mila")
    return NotificationSettingsResponse(
        user_id=user.id,
        notification_day=user.notification_day,
        notification_time=user.notification_time,
        notifications_enabled=user.notifications_enabled,
    )
