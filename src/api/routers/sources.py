"""
Source Management API Routes
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List

from src.services.core.source_service import SourceService

router = APIRouter(prefix="/api/sources", tags=["sources"])


# Request/Response Models
class SourceGroupCreate(BaseModel):
    name: str
    description: Optional[str] = None


class SourceGroupResponse(BaseModel):
    id: str
    name: str
    description: Optional[str]
    user_id: str
    created_at: str

    class Config:
        from_attributes = True


class SourceCreate(BaseModel):
    source_type: str
    identifier: str
    source_group_id: str
    config: Optional[dict] = None


class SourceResponse(BaseModel):
    id: str
    source_type: str
    identifier: str
    source_group_id: str
    config: dict
    is_active: bool
    created_at: str

    class Config:
        from_attributes = True


@router.get("/groups", response_model=List[SourceGroupResponse])
async def get_source_groups(user_id: str):
    """Get all source groups for a user"""
    groups = await SourceService.get_source_groups(user_id)
    return [
        SourceGroupResponse(
            id=str(group._id),
            name=group.name,
            description=group.description,
            user_id=group.user_id,
            created_at=group.created_at.isoformat(),
        )
        for group in groups
    ]


@router.post("/groups", response_model=SourceGroupResponse, status_code=201)
async def create_source_group(group: SourceGroupCreate, user_id: str):
    """Create a new source group"""
    new_group = await SourceService.create_source_group(
        name=group.name,
        user_id=user_id,
        description=group.description
    )
    return SourceGroupResponse(
        id=str(new_group._id),
        name=new_group.name,
        description=new_group.description,
        user_id=new_group.user_id,
        created_at=new_group.created_at.isoformat(),
    )


@router.get("/groups/{group_id}", response_model=SourceGroupResponse)
async def get_source_group(group_id: str):
    """Get a source group by ID"""
    group = await SourceService.get_source_group(group_id)
    if not group:
        raise HTTPException(status_code=404, detail="Source group not found")
    return SourceGroupResponse(
        id=str(group._id),
        name=group.name,
        description=group.description,
        user_id=group.user_id,
        created_at=group.created_at.isoformat(),
    )


@router.get("", response_model=List[SourceResponse])
async def get_sources(source_group_id: Optional[str] = None):
    """Get sources, optionally filtered by group"""
    sources = await SourceService.get_sources(source_group_id)
    return [
        SourceResponse(
            id=str(source._id),
            source_type=source.source_type,
            identifier=source.identifier,
            source_group_id=source.source_group_id,
            config=source.config,
            is_active=source.is_active,
            created_at=source.created_at.isoformat(),
        )
        for source in sources
    ]


@router.post("", response_model=SourceResponse, status_code=201)
async def create_source(source: SourceCreate):
    """Create a new source"""
    try:
        new_source = await SourceService.create_source(
            source_type=source.source_type,
            identifier=source.identifier,
            source_group_id=source.source_group_id,
            config=source.config
        )
        return SourceResponse(
            id=str(new_source._id),
            source_type=new_source.source_type,
            identifier=new_source.identifier,
            source_group_id=new_source.source_group_id,
            config=new_source.config,
            is_active=new_source.is_active,
            created_at=new_source.created_at.isoformat(),
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/{source_id}", response_model=SourceResponse)
async def get_source(source_id: str):
    """Get a source by ID"""
    source = await SourceService.get_source(source_id)
    if not source:
        raise HTTPException(status_code=404, detail="Source not found")
    return SourceResponse(
        id=str(source._id),
        source_type=source.source_type,
        identifier=source.identifier,
        source_group_id=source.source_group_id,
        config=source.config,
        is_active=source.is_active,
        created_at=source.created_at.isoformat(),
    )


@router.delete("/{source_id}", status_code=204)
async def delete_source(source_id: str):
    """Delete a source"""
    deleted = await SourceService.delete_source(source_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Source not found")

