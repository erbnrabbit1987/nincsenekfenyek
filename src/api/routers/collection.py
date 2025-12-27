"""
Collection API Routes
"""
from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

from src.services.collection.tasks import (
    collect_facebook_posts_task,
    collect_mti_feed_task,
    collect_magyar_kozlony_task
)
from src.services.collection.news import MTIService, MagyarKozlonyService
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


# MTI News Collection endpoints

@router.post("/mti/collect")
async def collect_mti_news(
    feed_type: str = Query("all", description="Feed type: all, domestic, international, economy, politics, sports, culture"),
    feed_url: Optional[str] = Query(None, description="Custom RSS feed URL (overrides feed_type)"),
    max_items: int = Query(50, description="Maximum number of articles to fetch"),
    background: bool = Query(False, description="Run in background")
):
    """Collect articles from MTI RSS feed"""
    try:
        if background:
            # Run as Celery task
            task = collect_mti_feed_task.delay(
                feed_type=feed_type,
                feed_url=feed_url,
                max_items=max_items
            )
            return {
                "success": True,
                "task_id": task.id,
                "message": f"MTI collection task started for feed: {feed_type}"
            }
        else:
            # Run synchronously
            mti_service = MTIService()
            result = mti_service.collect_articles(
                feed_type=feed_type,
                feed_url=feed_url,
                max_items=max_items,
                store=True
            )
            
            return {
                "success": True,
                "feed_type": feed_type,
                "articles_fetched": result.get("articles_fetched", 0),
                "articles_stored": result.get("articles_stored", 0)
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error collecting MTI news: {str(e)}")


@router.get("/mti/feeds")
async def list_mti_feeds():
    """List available MTI RSS feeds"""
    try:
        mti_service = MTIService()
        feeds = mti_service.get_available_feeds()
        return {
            "feeds": feeds
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error listing MTI feeds: {str(e)}")


@router.get("/mti/search")
async def search_mti_articles(
    query: str = Query(..., description="Search query"),
    category: Optional[str] = Query(None, description="Category filter"),
    limit: int = Query(20, description="Maximum results")
):
    """Search for MTI articles"""
    try:
        mti_service = MTIService()
        articles = mti_service.search_articles(
            query=query,
            category=category,
            limit=limit
        )
        return {
            "query": query,
            "count": len(articles),
            "articles": articles
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error searching MTI articles: {str(e)}")


# Magyar Közlöny endpoints

@router.post("/kozlony/collect")
async def collect_magyar_kozlony(
    max_items: int = Query(50, description="Maximum number of publications to fetch"),
    year: Optional[int] = Query(None, description="Year filter"),
    fetch_details: bool = Query(False, description="Fetch detailed content"),
    background: bool = Query(False, description="Run in background")
):
    """Collect official publications from Magyar Közlöny"""
    try:
        if background:
            # Run as Celery task
            task = collect_magyar_kozlony_task.delay(
                max_items=max_items,
                year=year,
                fetch_details=fetch_details
            )
            return {
                "success": True,
                "task_id": task.id,
                "message": f"Magyar Közlöny collection task started (year: {year})"
            }
        else:
            # Run synchronously
            kozlony_service = MagyarKozlonyService()
            result = kozlony_service.collect_publications(
                max_items=max_items,
                year=year,
                store=True,
                fetch_details=fetch_details
            )
            
            return {
                "success": True,
                "year": year,
                "publications_fetched": result.get("publications_fetched", 0),
                "publications_stored": result.get("publications_stored", 0)
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error collecting Magyar Közlöny: {str(e)}")


@router.get("/kozlony/search")
async def search_magyar_kozlony(
    query: str = Query(..., description="Search query"),
    year: Optional[int] = Query(None, description="Year filter"),
    limit: int = Query(20, description="Maximum results")
):
    """Search for Magyar Közlöny publications"""
    try:
        kozlony_service = MagyarKozlonyService()
        publications = kozlony_service.search_publications(
            query=query,
            year=year,
            limit=limit
        )
        return {
            "query": query,
            "year": year,
            "count": len(publications),
            "publications": publications
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error searching Magyar Közlöny: {str(e)}")


