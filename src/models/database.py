"""
Database Connection and Configuration
"""
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo import MongoClient
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from typing import Optional

from src.config.settings import get_settings

settings = get_settings()

# MongoDB Connections
mongodb_client: Optional[AsyncIOMotorClient] = None
mongodb_sync_client: Optional[MongoClient] = None
mongodb_database = None

# PostgreSQL Connections (előkészítés)
postgres_engine = None
postgres_session = None
PostgreSQLBase = declarative_base()


async def connect_mongodb():
    """Connect to MongoDB"""
    global mongodb_client, mongodb_database
    mongodb_client = AsyncIOMotorClient(settings.MONGODB_URL)
    mongodb_database = mongodb_client[settings.MONGODB_DB_NAME]
    return mongodb_database


def connect_mongodb_sync():
    """Connect to MongoDB synchronously (for Celery workers)"""
    global mongodb_sync_client
    mongodb_sync_client = MongoClient(settings.MONGODB_URL)
    return mongodb_sync_client[settings.MONGODB_DB_NAME]


async def disconnect_mongodb():
    """Disconnect from MongoDB"""
    global mongodb_client
    if mongodb_client:
        mongodb_client.close()


def init_postgresql():
    """Initialize PostgreSQL connection (előkészítés)"""
    global postgres_engine, postgres_session
    postgres_engine = create_engine(
        settings.POSTGRESQL_URL,
        pool_pre_ping=True,
        echo=settings.DEBUG
    )
    postgres_session = sessionmaker(
        autocommit=False,
        autoflush=False,
        bind=postgres_engine
    )
    return postgres_engine


def get_postgres_session():
    """Get PostgreSQL session"""
    if not postgres_session:
        init_postgresql()
    db = postgres_session()
    try:
        yield db
    finally:
        db.close()


async def get_mongodb():
    """Get MongoDB database instance"""
    if not mongodb_database:
        await connect_mongodb()
    return mongodb_database


