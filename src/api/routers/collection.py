"""
Collection API Routes
"""
from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

from src.services.collection.tasks import collect_facebook_posts_task
from src.services.core.source_service import SourceService
from src.models.database import connect_mongodb_sync

router = APIRouter(prefix="/api/collection", tags=["collection"])


class CollectionTriggerResponse(BaseModel):
    source_id: str
    task_id: str
    status: str
    message: str


class PostResponse(BaseModel):
    id: str
    source_id: str
    content: str
    posted_at: datetime
    collected_at: datetime
    metadata: dict

    class Config:
        from_attributes = True


class CollectionStatusResponse(BaseModel):
    source_id: str
    is_active: bool
    last_collected_at: Optional[datetime]
    last_collection_status: Optional[str]


@router.post("/trigger/{source_id}", response_model=CollectionTriggerResponse)
async def trigger_collection(source_id: str, background_tasks: BackgroundTasks):
    """
    Manually trigger collection for a source
    
    Args:
        source_id: Source ID to collect from
        
    Returns:
        Task information
    """
    try:
        # Verify source exists
        source = await SourceService.get_source(source_id)
        if not source:
            raise HTTPException(status_code=404, detail="Source not found")
        
        if not source.is_active:
            raise HTTPException(
                status_code=400,
                detail="Source is not active"
            )
        
        # Trigger collection task
        task = collect_facebook_posts_task.delay(source_id)
        
        return CollectionTriggerResponse(
            source_id=source_id,
            task_id=task.id,
            status="queued",
            message=f"Collection task queued for source {source_id}"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error triggering collection: {str(e)}"
        )


@router.get("/status/{source_id}", response_model=CollectionStatusResponse)
async def get_collection_status(source_id: str):
    """
    Get collection status for a source
    
    Args:
        source_id: Source ID
        
    Returns:
        Collection status information
    """
    try:
        source = await SourceService.get_source(source_id)
        if not source:
            raise HTTPException(status_code=404, detail="Source not found")
        
        db = connect_mongodb_sync()
        source_doc = db.sources.find_one({"_id": source._id})
        
        last_collected_at = source_doc.get("last_collected_at") if source_doc else None
        
        return CollectionStatusResponse(
            source_id=source_id,
            is_active=source.is_active,
            last_collected_at=last_collected_at,
            last_collection_status="unknown"  # Could be improved with task status tracking
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error getting collection status: {str(e)}"
        )


@router.get("/posts", response_model=List[PostResponse])
async def get_posts(
    source_id: Optional[str] = None,
    limit: int = 50,
    skip: int = 0
):
    """
    Get posts with optional filtering
    
    Args:
        source_id: Optional source ID filter
        limit: Maximum number of posts to return
        skip: Number of posts to skip
        
    Returns:
        List of posts
    """
    try:
        db = connect_mongodb_sync()
        
        query = {}
        if source_id:
            query["source_id"] = source_id
        
        # Get posts sorted by posted_at descending
        cursor = (
            db.posts
            .find(query)
            .sort("posted_at", -1)
            .skip(skip)
            .limit(limit)
        )
        
        posts = []
        for post_doc in cursor:
            posts.append(PostResponse(
                id=str(post_doc["_id"]),
                source_id=post_doc["source_id"],
                content=post_doc["content"],
                posted_at=post_doc["posted_at"],
                collected_at=post_doc["collected_at"],
                metadata=post_doc.get("metadata", {})
            ))
        
        return posts
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error getting posts: {str(e)}"
        )


@router.get("/posts/{post_id}", response_model=PostResponse)
async def get_post(post_id: str):
    """
    Get a specific post by ID
    
    Args:
        post_id: Post ID
        
    Returns:
        Post details
    """
    try:
        from bson import ObjectId
        
        db = connect_mongodb_sync()
        post_doc = db.posts.find_one({"_id": ObjectId(post_id)})
        
        if not post_doc:
            raise HTTPException(status_code=404, detail="Post not found")
        
        return PostResponse(
            id=str(post_doc["_id"]),
            source_id=post_doc["source_id"],
            content=post_doc["content"],
            posted_at=post_doc["posted_at"],
            collected_at=post_doc["collected_at"],
            metadata=post_doc.get("metadata", {})
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error getting post: {str(e)}"
        )


