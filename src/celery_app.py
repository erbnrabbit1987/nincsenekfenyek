"""
Celery Application Configuration
"""
import os
from celery import Celery
from src.config.settings import get_settings

settings = get_settings()

# Override with environment variables if set (for Docker)
# This ensures we use the correct Redis host in Docker network
broker_url = os.getenv("CELERY_BROKER_URL", settings.CELERY_BROKER_URL)
result_backend = os.getenv("CELERY_RESULT_BACKEND", settings.CELERY_RESULT_BACKEND)

# Fallback: if REDIS_URL is set but CELERY_BROKER_URL is not, use REDIS_URL
if not broker_url or "localhost" in broker_url:
    redis_url = os.getenv("REDIS_URL")
    if redis_url:
        broker_url = redis_url
        result_backend = redis_url

celery_app = Celery(
    "nincsenekfenyek",
    broker=broker_url,
    backend=result_backend,
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


