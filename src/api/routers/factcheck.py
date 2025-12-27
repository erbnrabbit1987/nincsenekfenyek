"""
Fact-check API Routes
"""
from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

from src.services.factcheck.tasks import factcheck_post_task
from src.services.factcheck.factcheck_service import FactCheckService
from src.models.database import connect_mongodb_sync
from bson import ObjectId

router = APIRouter(prefix="/api/factcheck", tags=["factcheck"])


class FactCheckTriggerRequest(BaseModel):
    manual_sources: Optional[List[str]] = None


class FactCheckTriggerResponse(BaseModel):
    post_id: str
    task_id: str
    status: str
    message: str


class ClaimResponse(BaseModel):
    text: str
    type: str
    confidence: float
    entities: Optional[List[dict]] = None
    numbers: Optional[List[str]] = None


class ReferenceResponse(BaseModel):
    type: str
    source: str
    url: Optional[str] = None
    content: Optional[str] = None
    relevance_score: float


class FactCheckResultResponse(BaseModel):
    id: str
    post_id: str
    claims: List[ClaimResponse]
    verdict: str
    confidence: float
    references: List[ReferenceResponse]
    checked_at: datetime
    checked_by: Optional[str] = None
    metadata: dict

    class Config:
        from_attributes = True


@router.post("/{post_id}", response_model=FactCheckTriggerResponse)
async def trigger_factcheck(
    post_id: str,
    request: Optional[FactCheckTriggerRequest] = None,
    background_tasks: BackgroundTasks = None
):
    """
    Manually trigger fact-checking for a post
    
    Args:
        post_id: Post ID to fact-check
        request: Optional request with manual sources
        
    Returns:
        Task information
    """
    try:
        # Verify post exists
        db = connect_mongodb_sync()
        post_doc = db.posts.find_one({"_id": ObjectId(post_id)})
        if not post_doc:
            raise HTTPException(status_code=404, detail="Post not found")
        
        # Trigger fact-check task
        manual_sources = request.manual_sources if request else None
        task = factcheck_post_task.delay(post_id, manual_sources)
        
        return FactCheckTriggerResponse(
            post_id=post_id,
            task_id=task.id,
            status="queued",
            message=f"Fact-check task queued for post {post_id}"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error triggering fact-check: {str(e)}"
        )


@router.get("/{post_id}", response_model=FactCheckResultResponse)
async def get_factcheck_result(post_id: str):
    """
    Get fact-check result for a post
    
    Args:
        post_id: Post ID
        
    Returns:
        Fact-check result
    """
    try:
        # Verify post exists
        db = connect_mongodb_sync()
        post_doc = db.posts.find_one({"_id": ObjectId(post_id)})
        if not post_doc:
            raise HTTPException(status_code=404, detail="Post not found")
        
        # Get fact-check result
        factcheck_service = FactCheckService()
        result = factcheck_service.get_factcheck_result(post_id)
        
        if not result:
            raise HTTPException(
                status_code=404,
                detail="Fact-check result not found for this post"
            )
        
        # Convert to response model
        claims = [
            ClaimResponse(
                text=claim.get('text', ''),
                type=claim.get('type', 'statement'),
                confidence=claim.get('confidence', 0.5),
                entities=claim.get('entities'),
                numbers=claim.get('numbers')
            )
            for claim in result.claims
        ]
        
        references = [
            ReferenceResponse(
                type=ref.get('type', 'unknown'),
                source=ref.get('source', 'unknown'),
                url=ref.get('url'),
                content=ref.get('content'),
                relevance_score=ref.get('relevance_score', 0.5)
            )
            for ref in result.references
        ]
        
        return FactCheckResultResponse(
            id=str(result._id),
            post_id=result.post_id,
            claims=claims,
            verdict=result.verdict,
            confidence=result.confidence,
            references=references,
            checked_at=result.checked_at,
            checked_by=result.checked_by,
            metadata=result.metadata
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error getting fact-check result: {str(e)}"
        )


@router.get("/results/list", response_model=List[FactCheckResultResponse])
async def list_factcheck_results(
    post_id: Optional[str] = None,
    verdict: Optional[str] = None,
    limit: int = 50,
    skip: int = 0
):
    """
    List fact-check results with optional filtering
    
    Args:
        post_id: Optional post ID filter
        verdict: Optional verdict filter (verified, disputed, false, true, partially_true)
        limit: Maximum number of results to return
        skip: Number of results to skip
        
    Returns:
        List of fact-check results
    """
    try:
        db = connect_mongodb_sync()
        factcheck_service = FactCheckService()
        
        from src.models.mongodb_models import FactCheckResult
        
        query = {}
        if post_id:
            query["post_id"] = post_id
        if verdict:
            if verdict not in FactCheckResult.VERDICT_CHOICES:
                raise HTTPException(
                    status_code=400,
                    detail=f"Invalid verdict: {verdict}. Must be one of {FactCheckResult.VERDICT_CHOICES}"
                )
            query["verdict"] = verdict
        
        # Get results sorted by checked_at descending
        cursor = (
            db.factcheck_results
            .find(query)
            .sort("checked_at", -1)
            .skip(skip)
            .limit(limit)
        )
        
        results = []
        for result_doc in cursor:
            result = factcheck_service.get_factcheck_result(result_doc["post_id"])
            if result:
                # Convert to response (same as get_factcheck_result)
                claims = [
                    ClaimResponse(
                        text=claim.get('text', ''),
                        type=claim.get('type', 'statement'),
                        confidence=claim.get('confidence', 0.5),
                        entities=claim.get('entities'),
                        numbers=claim.get('numbers')
                    )
                    for claim in result.claims
                ]
                
                references = [
                    ReferenceResponse(
                        type=ref.get('type', 'unknown'),
                        source=ref.get('source', 'unknown'),
                        url=ref.get('url'),
                        content=ref.get('content'),
                        relevance_score=ref.get('relevance_score', 0.5)
                    )
                    for ref in result.references
                ]
                
                results.append(FactCheckResultResponse(
                    id=str(result._id),
                    post_id=result.post_id,
                    claims=claims,
                    verdict=result.verdict,
                    confidence=result.confidence,
                    references=references,
                    checked_at=result.checked_at,
                    checked_by=result.checked_by,
                    metadata=result.metadata
                ))
        
        return results
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error listing fact-check results: {str(e)}"
        )

