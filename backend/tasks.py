import asyncio

from sqlalchemy import desc, select

from celery_app import celery
from database import AsyncSessionLocal
from models import Insight, User
from services import whatsapp_service


@celery.task(name="tasks.send_weekly_reports_to_all")
def send_weekly_reports_to_all():
    asyncio.run(_send_all())


async def _send_all():
    async with AsyncSessionLocal() as db:
        users = await db.scalars(select(User).where(User.notifications_enabled == True))
        for user in users:
            insight = await db.scalar(
                select(Insight)
                .where(Insight.user_id == user.id)
                .order_by(desc(Insight.created_at))
                .limit(1)
            )
            if insight:
                message = whatsapp_service.format_report_for_whatsapp(insight.__dict__)
                whatsapp_service.send_whatsapp_message(user.phone_number, message)


@celery.task(name="tasks.send_report_to_user")
def send_report_to_user(user_id: int):
    asyncio.run(_send_one(user_id))


async def _send_one(user_id: int):
    async with AsyncSessionLocal() as db:
        user = await db.get(User, user_id)
        if not user:
            return False
        insight = await db.scalar(
            select(Insight)
            .where(Insight.user_id == user.id)
            .order_by(desc(Insight.created_at))
            .limit(1)
        )
        if not insight:
            return False
        message = whatsapp_service.format_report_for_whatsapp(insight.__dict__)
        return whatsapp_service.send_whatsapp_message(user.phone_number, message)
