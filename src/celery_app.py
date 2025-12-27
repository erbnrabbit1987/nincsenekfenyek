"""
Celery Application Configuration
"""
from celery import Celery
from src.config.settings import get_settings

settings = get_settings()

celery_app = Celery(
    "nincsenekfenyek",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=[
        "src.services.collection.tasks",
        "src.services.factcheck.tasks",
    ]
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="Europe/Budapest",
    enable_utc=True,
)


