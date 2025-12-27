"""
RSS Feed Reader Service
General-purpose RSS/Atom feed reader for collecting articles from any RSS feed
"""
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime
import requests
import feedparser
from bs4 import BeautifulSoup
import re
from urllib.parse import urlparse

from src.models.database import connect_mongodb_sync

logger = logging.getLogger(__name__)


class RSSReaderService:
    """Service for reading RSS and Atom feeds"""
    
    def __init__(self):
        self.db = connect_mongodb_sync()
    
    def validate_feed_url(self, feed_url: str) -> bool:
        """
        Validate RSS feed URL
        
        Args:
            feed_url: RSS feed URL to validate
            
        Returns:
            True if valid, False otherwise
        """
        try:
            parsed = urlparse(feed_url)
            if not parsed.scheme or not parsed.netloc:
                return False
            
            # Try to fetch and parse feed
            response = requests.get(feed_url, timeout=10, headers={
                "User-Agent": "Mozilla/5.0 (compatible; NincsenekFenyek/1.0; +https://github.com/nincsenekfenyek)"
            })
            response.raise_for_status()
            
            feed = feedparser.parse(response.content)
            return feed.entries is not None and len(feed.entries) > 0
        
        except Exception as e:
            logger.warning(f"Feed URL validation failed: {e}")
            return False
    
    def fetch_feed(
        self,
        feed_url: str,
        max_items: int = 50,
        timeout: int = 30
    ) -> Dict[str, Any]:
        """
        Fetch and parse RSS/Atom feed
        
        Args:
            feed_url: RSS feed URL
            max_items: Maximum number of items to fetch
            timeout: Request timeout in seconds
            
        Returns:
            Dictionary with feed metadata and entries
        """
        try:
            response = requests.get(feed_url, timeout=timeout, headers={
                "User-Agent": "Mozilla/5.0 (compatible; NincsenekFenyek/1.0; +https://github.com/nincsenekfenyek)"
            })
            response.raise_for_status()
            
            # Parse feed
            feed = feedparser.parse(response.content)
            
            if feed.bozo and feed.bozo_exception:
                logger.warning(f"RSS feed parsing warning for {feed_url}: {feed.bozo_exception}")
            
            # Extract feed metadata
            feed_info = {
                "title": feed.feed.get("title", ""),
                "description": feed.feed.get("description", ""),
                "link": feed.feed.get("link", feed_url),
                "language": feed.feed.get("language", ""),
                "updated": feed.feed.get("updated", ""),
                "feed_type": feed.version if hasattr(feed, "version") else "unknown"
            }
            
            # Parse entries
            entries = []
            for entry in feed.entries[:max_items]:
                try:
                    parsed_entry = self._parse_entry(entry, feed_url)
                    if parsed_entry:
                        entries.append(parsed_entry)
                except Exception as e:
                    logger.error(f"Error parsing feed entry: {e}")
                    continue
            
            logger.info(f"RSS Feed: Fetched {len(entries)} items from {feed_url}")
            
            return {
                "feed_info": feed_info,
                "entries": entries,
                "feed_url": feed_url,
                "fetched_at": datetime.utcnow()
            }
        
        except requests.exceptions.RequestException as e:
            logger.error(f"Error fetching RSS feed {feed_url}: {e}")
            raise
        except Exception as e:
            logger.error(f"Error parsing RSS feed {feed_url}: {e}")
            raise
    
    def _parse_entry(self, entry: Any, feed_url: str) -> Optional[Dict[str, Any]]:
        """
        Parse RSS/Atom feed entry
        
        Args:
            entry: FeedParser entry object
            feed_url: Original feed URL for reference
            
        Returns:
            Entry dictionary or None
        """
        try:
            # Extract title and link
            title = entry.get("title", "").strip()
            link = entry.get("link", "")
            
            if not title and not link:
                return None
            
            # Extract published date
            published = None
            if hasattr(entry, "published_parsed") and entry.published_parsed:
                try:
                    published = datetime(*entry.published_parsed[:6])
                except:
                    pass
            
            if not published and hasattr(entry, "updated_parsed") and entry.updated_parsed:
                try:
                    published = datetime(*entry.updated_parsed[:6])
                except:
                    pass
            
            if not published and hasattr(entry, "published"):
                try:
                    from dateutil import parser
                    published = parser.parse(entry.published)
                except:
                    pass
            
            if not published:
                published = datetime.utcnow()
            
            # Extract content
            content = ""
            if hasattr(entry, "content") and entry.content:
                content = entry.content[0].get("value", "")
            elif hasattr(entry, "summary"):
                content = entry.summary
            elif hasattr(entry, "description"):
                content = entry.description
            
            # Clean HTML from content
            if content:
                soup = BeautifulSoup(content, "html.parser")
                content = soup.get_text(strip=True)
            
            # Extract description (first 500 chars of content or summary)
            description = content[:500] if content else title
            
            # Generate entry ID from link or title
            entry_id = self._generate_entry_id(link, title, entry)
            
            # Extract tags/categories
            tags = []
            if hasattr(entry, "tags"):
                tags = [tag.term for tag in entry.tags]
            elif hasattr(entry, "category"):
                if isinstance(entry.category, list):
                    tags = entry.category
                else:
                    tags = [entry.category]
            
            # Extract author
            author = None
            if hasattr(entry, "author"):
                author = entry.author
            elif hasattr(entry, "author_detail"):
                author = entry.author_detail.get("name", "")
            
            entry_data = {
                "entry_id": entry_id,
                "title": title,
                "content": content,
                "description": description,
                "link": link,
                "published_at": published,
                "author": author,
                "tags": tags,
                "feed_url": feed_url,
                "collected_at": datetime.utcnow(),
                "metadata": {
                    "guid": entry.get("id", link),
                    "raw_entry": {
                        "title": title,
                        "link": link,
                        "author": author
                    }
                }
            }
            
            return entry_data
        
        except Exception as e:
            logger.error(f"Error parsing feed entry: {e}")
            return None
    
    def _generate_entry_id(self, url: str, title: str, entry: Any) -> str:
        """Generate unique entry ID"""
        # Try to use GUID if available
        if hasattr(entry, "id") and entry.id:
            guid = entry.id
            # Clean GUID
            guid_clean = re.sub(r'[^a-zA-Z0-9]', '_', guid)[:50]
            return f"rss_{guid_clean}"
        
        # Try to extract ID from URL
        if url:
            match = re.search(r'/(\d+)/', url)
            if match:
                return f"rss_{match.group(1)}"
            
            # Extract domain and hash URL
            parsed = urlparse(url)
            domain = parsed.netloc.replace('.', '_')
            import hashlib
            url_hash = hashlib.md5(url.encode()).hexdigest()[:12]
            return f"rss_{domain}_{url_hash}"
        
        # Fallback: hash title
        if title:
            import hashlib
            title_hash = hashlib.md5(title.encode()).hexdigest()[:12]
            return f"rss_{title_hash}"
        
        # Last resort: timestamp
        return f"rss_{int(datetime.utcnow().timestamp())}"
    
    def store_entries(
        self,
        entries: List[Dict[str, Any]],
        feed_url: str,
        source_id: Optional[str] = None,
        feed_name: Optional[str] = None
    ) -> int:
        """
        Store feed entries in MongoDB
        
        Args:
            entries: List of entry dictionaries
            feed_url: RSS feed URL
            source_id: Optional source ID for tracking
            feed_name: Optional feed name
            
        Returns:
            Number of entries stored
        """
        stored_count = 0
        
        for entry in entries:
            try:
                entry_id = entry.get("entry_id")
                if not entry_id:
                    continue
                
                # Check if entry already exists
                existing = self.db.posts.find_one({
                    "metadata.entry_id": entry_id,
                    "metadata.feed_url": feed_url
                })
                
                if existing:
                    continue
                
                # Prepare post document
                post_doc = {
                    "source_id": source_id or f"rss_{feed_url}",
                    "source": "rss",
                    "source_type": "news",
                    "content": entry.get("content", entry.get("description", "")),
                    "title": entry.get("title", ""),
                    "posted_at": entry.get("published_at", datetime.utcnow()),
                    "collected_at": datetime.utcnow(),
                    "metadata": {
                        "entry_id": entry_id,
                        "feed_url": feed_url,
                        "feed_name": feed_name or entry.get("feed_url", ""),
                        "link": entry.get("link"),
                        "author": entry.get("author"),
                        "tags": entry.get("tags", []),
                        "description": entry.get("description", ""),
                        "guid": entry.get("metadata", {}).get("guid")
                    }
                }
                
                # Insert into database
                self.db.posts.insert_one(post_doc)
                stored_count += 1
                
            except Exception as e:
                logger.error(f"Error storing RSS entry: {e}")
                continue
        
        logger.info(f"RSS Feed: Stored {stored_count} new entries from {feed_url}")
        return stored_count
    
    def collect_feed(
        self,
        feed_url: str,
        max_items: int = 50,
        store: bool = True,
        source_id: Optional[str] = None,
        feed_name: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Collect entries from RSS feed
        
        Args:
            feed_url: RSS feed URL
            max_items: Maximum items to fetch
            store: Whether to store in database
            source_id: Optional source ID
            feed_name: Optional feed name
            
        Returns:
            Dictionary with collection results
        """
        # Fetch feed
        feed_data = self.fetch_feed(feed_url, max_items)
        
        entries = feed_data.get("entries", [])
        
        # Store entries if requested
        stored_count = 0
        if store and entries:
            stored_count = self.store_entries(
                entries,
                feed_url,
                source_id,
                feed_name or feed_data.get("feed_info", {}).get("title", "")
            )
        
        return {
            "success": True,
            "feed_url": feed_url,
            "feed_info": feed_data.get("feed_info", {}),
            "entries_fetched": len(entries),
            "entries_stored": stored_count,
            "entries": entries[:10] if not store else []  # Return samples if not storing
        }
    
    def search_entries(
        self,
        query: str,
        feed_url: Optional[str] = None,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """
        Search for entries in stored RSS feed entries
        
        Args:
            query: Search query
            feed_url: Optional feed URL filter
            limit: Maximum results
            
        Returns:
            List of matching entries
        """
        try:
            search_filter = {
                "source": "rss",
                "$or": [
                    {"content": {"$regex": query, "$options": "i"}},
                    {"title": {"$regex": query, "$options": "i"}},
                    {"metadata.description": {"$regex": query, "$options": "i"}}
                ]
            }
            
            if feed_url:
                search_filter["metadata.feed_url"] = feed_url
            
            entries = list(
                self.db.posts.find(search_filter)
                .sort("posted_at", -1)
                .limit(limit)
            )
            
            return entries
            
        except Exception as e:
            logger.error(f"Error searching RSS entries: {e}")
            return []
    
    def list_feeds(self, source_id: Optional[str] = None) -> List[Dict[str, Any]]:
        """
        List all RSS feeds from stored entries
        
        Args:
            source_id: Optional source ID filter
            
        Returns:
            List of feed information dictionaries
        """
        try:
            filter_query = {"source": "rss"}
            if source_id:
                filter_query["source_id"] = source_id
            
            # Group by feed_url
            pipeline = [
                {"$match": filter_query},
                {"$group": {
                    "_id": "$metadata.feed_url",
                    "feed_name": {"$first": "$metadata.feed_name"},
                    "count": {"$sum": 1},
                    "latest_entry": {"$max": "$posted_at"},
                    "source_id": {"$first": "$source_id"}
                }},
                {"$sort": {"latest_entry": -1}}
            ]
            
            feeds = list(self.db.posts.aggregate(pipeline))
            
            return [
                {
                    "feed_url": feed["_id"],
                    "feed_name": feed.get("feed_name", ""),
                    "entry_count": feed.get("count", 0),
                    "latest_entry": feed.get("latest_entry"),
                    "source_id": feed.get("source_id")
                }
                for feed in feeds
            ]
        
        except Exception as e:
            logger.error(f"Error listing RSS feeds: {e}")
            return []

