"""
Source Management Service
"""
from typing import List, Optional
from bson import ObjectId
from datetime import datetime

from src.models.database import get_mongodb
from src.models.mongodb_models import Source, SourceGroup


class SourceService:
    """Service for managing sources and source groups"""
    
    @staticmethod
    async def create_source_group(
        name: str,
        user_id: str,
        description: Optional[str] = None
    ) -> SourceGroup:
        """Create a new source group"""
        db = await get_mongodb()
        source_group = SourceGroup(
            name=name,
            user_id=user_id,
            description=description
        )
        
        result = await db.source_groups.insert_one(source_group.to_dict())
        source_group._id = result.inserted_id
        return source_group
    
    @staticmethod
    async def get_source_groups(user_id: str) -> List[SourceGroup]:
        """Get all source groups for a user"""
        db = await get_mongodb()
        cursor = db.source_groups.find({"user_id": user_id})
        groups = []
        async for doc in cursor:
            groups.append(SourceGroup.from_dict(doc))
        return groups
    
    @staticmethod
    async def get_source_group(group_id: str) -> Optional[SourceGroup]:
        """Get a source group by ID"""
        db = await get_mongodb()
        doc = await db.source_groups.find_one({"_id": ObjectId(group_id)})
        if doc:
            return SourceGroup.from_dict(doc)
        return None
    
    @staticmethod
    async def create_source(
        source_type: str,
        identifier: str,
        source_group_id: str,
        config: Optional[dict] = None
    ) -> Source:
        """Create a new source"""
        db = await get_mongodb()
        
        # Validate source group exists
        group = await SourceService.get_source_group(source_group_id)
        if not group:
            raise ValueError(f"Source group {source_group_id} not found")
        
        source = Source(
            source_type=source_type,
            identifier=identifier,
            source_group_id=source_group_id,
            config=config or {}
        )
        
        result = await db.sources.insert_one(source.to_dict())
        source._id = result.inserted_id
        return source
    
    @staticmethod
    async def get_sources(source_group_id: Optional[str] = None) -> List[Source]:
        """Get sources, optionally filtered by group"""
        db = await get_mongodb()
        query = {}
        if source_group_id:
            query["source_group_id"] = source_group_id
        
        cursor = db.sources.find(query)
        sources = []
        async for doc in cursor:
            sources.append(Source.from_dict(doc))
        return sources
    
    @staticmethod
    async def get_source(source_id: str) -> Optional[Source]:
        """Get a source by ID"""
        db = await get_mongodb()
        doc = await db.sources.find_one({"_id": ObjectId(source_id)})
        if doc:
            return Source.from_dict(doc)
        return None
    
    @staticmethod
    async def update_source(source_id: str, updates: dict) -> Optional[Source]:
        """Update a source"""
        db = await get_mongodb()
        updates["updated_at"] = datetime.utcnow()
        
        result = await db.sources.find_one_and_update(
            {"_id": ObjectId(source_id)},
            {"$set": updates},
            return_document=True
        )
        
        if result:
            return Source.from_dict(result)
        return None
    
    @staticmethod
    async def delete_source(source_id: str) -> bool:
        """Delete a source"""
        db = await get_mongodb()
        result = await db.sources.delete_one({"_id": ObjectId(source_id)})
        return result.deleted_count > 0

