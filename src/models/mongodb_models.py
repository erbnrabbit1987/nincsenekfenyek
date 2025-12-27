"""
MongoDB Models (using plain dictionaries for flexibility)
"""
from datetime import datetime
from typing import Optional, Dict, Any, List
from bson import ObjectId


class SourceGroup:
    """Source Group Model"""
    def __init__(
        self,
        name: str,
        user_id: str,
        description: Optional[str] = None,
        created_at: Optional[datetime] = None,
        _id: Optional[ObjectId] = None
    ):
        self._id = _id or ObjectId()
        self.name = name
        self.user_id = user_id
        self.description = description
        self.created_at = created_at or datetime.utcnow()
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            "_id": self._id,
            "name": self.name,
            "user_id": self.user_id,
            "description": self.description,
            "created_at": self.created_at,
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "SourceGroup":
        """Create from dictionary"""
        return cls(
            _id=data.get("_id"),
            name=data["name"],
            user_id=data["user_id"],
            description=data.get("description"),
            created_at=data.get("created_at"),
        )


class Source:
    """Source Model"""
    SOURCE_TYPES = ["facebook", "news", "statistics"]
    
    def __init__(
        self,
        source_type: str,
        identifier: str,
        source_group_id: str,
        config: Optional[Dict[str, Any]] = None,
        is_active: bool = True,
        created_at: Optional[datetime] = None,
        _id: Optional[ObjectId] = None
    ):
        if source_type not in self.SOURCE_TYPES:
            raise ValueError(f"Invalid source type: {source_type}")
        
        self._id = _id or ObjectId()
        self.source_type = source_type
        self.identifier = identifier  # URL, username, etc.
        self.source_group_id = source_group_id
        self.config = config or {}
        self.is_active = is_active
        self.created_at = created_at or datetime.utcnow()
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            "_id": self._id,
            "source_type": self.source_type,
            "identifier": self.identifier,
            "source_group_id": self.source_group_id,
            "config": self.config,
            "is_active": self.is_active,
            "created_at": self.created_at,
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Source":
        """Create from dictionary"""
        return cls(
            _id=data.get("_id"),
            source_type=data["source_type"],
            identifier=data["identifier"],
            source_group_id=data["source_group_id"],
            config=data.get("config", {}),
            is_active=data.get("is_active", True),
            created_at=data.get("created_at"),
        )


class Post:
    """Post/Article Model"""
    def __init__(
        self,
        source_id: str,
        content: str,
        posted_at: datetime,
        metadata: Optional[Dict[str, Any]] = None,
        collected_at: Optional[datetime] = None,
        _id: Optional[ObjectId] = None
    ):
        self._id = _id or ObjectId()
        self.source_id = source_id
        self.content = content
        self.posted_at = posted_at
        self.metadata = metadata or {}
        self.collected_at = collected_at or datetime.utcnow()
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            "_id": self._id,
            "source_id": self.source_id,
            "content": self.content,
            "posted_at": self.posted_at,
            "metadata": self.metadata,
            "collected_at": self.collected_at,
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "Post":
        """Create from dictionary"""
        return cls(
            _id=data.get("_id"),
            source_id=data["source_id"],
            content=data["content"],
            posted_at=data["posted_at"],
            metadata=data.get("metadata", {}),
            collected_at=data.get("collected_at"),
        )


class FactCheckResult:
    """Fact-check Result Model"""
    VERDICT_CHOICES = ["verified", "disputed", "false", "true", "partially_true"]
    
    def __init__(
        self,
        post_id: str,
        claims: List[Dict[str, Any]],
        verdict: str,
        confidence: float,
        references: List[Dict[str, Any]],
        checked_at: Optional[datetime] = None,
        checked_by: Optional[str] = None,
        metadata: Optional[Dict[str, Any]] = None,
        _id: Optional[ObjectId] = None
    ):
        if verdict not in self.VERDICT_CHOICES:
            raise ValueError(f"Invalid verdict: {verdict}. Must be one of {self.VERDICT_CHOICES}")
        
        if not 0.0 <= confidence <= 1.0:
            raise ValueError(f"Confidence must be between 0.0 and 1.0, got {confidence}")
        
        self._id = _id or ObjectId()
        self.post_id = post_id
        self.claims = claims  # List of extracted claims
        self.verdict = verdict
        self.confidence = confidence
        self.references = references  # List of reference sources
        self.checked_at = checked_at or datetime.utcnow()
        self.checked_by = checked_by  # User ID or 'system'
        self.metadata = metadata or {}
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary"""
        return {
            "_id": self._id,
            "post_id": self.post_id,
            "claims": self.claims,
            "verdict": self.verdict,
            "confidence": self.confidence,
            "references": self.references,
            "checked_at": self.checked_at,
            "checked_by": self.checked_by,
            "metadata": self.metadata,
        }
    
    @classmethod
    def from_dict(cls, data: Dict[str, Any]) -> "FactCheckResult":
        """Create from dictionary"""
        return cls(
            _id=data.get("_id"),
            post_id=data["post_id"],
            claims=data.get("claims", []),
            verdict=data["verdict"],
            confidence=data["confidence"],
            references=data.get("references", []),
            checked_at=data.get("checked_at"),
            checked_by=data.get("checked_by"),
            metadata=data.get("metadata", {}),
        )
