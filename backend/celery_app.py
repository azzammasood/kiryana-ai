from celery import Celery
from celery.schedules import crontab

from config import settings


celery = Celery(
    "kiryana_tasks",
    broker=settings.redis_url,
    backend=settings.redis_url,
    include=["tasks"],
)

celery.conf.beat_schedule = {
    "send-weekly-reports": {
        "task": "tasks.send_weekly_reports_to_all",
        "schedule": crontab(hour=10, minute=0, day_of_week="sunday"),
    }
}
celery.conf.timezone = "Asia/Karachi"
