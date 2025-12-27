"""
MTI (Magyar Távirati Iroda) Service
Integrates with MTI RSS feeds to collect news articles
"""
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime
import requests
import feedparser
from bs4 import BeautifulSoup
import re

from src.models.database import connect_mongodb_sync

logger = logging.getLogger(__name__)


class MTIService:
    """Service for collecting news from MTI RSS feeds"""
    
    BASE_URL = "https://www.mti.hu"
    # Common MTI RSS feed URLs (these may need to be updated based on actual MTI structure)
    RSS_FEEDS = {
        "all": "https://www.mti.hu/rss",
        "domestic": "https://www.mti.hu/rss/belfold",
        "international": "https://www.mti.hu/rss/kulfold",
        "economy": "https://www.mti.hu/rss/gazdasag",
        "politics": "https://www.mti.hu/rss/politika",
        "sports": "https://www.mti.hu/rss/sport",
        "culture": "https://www.mti.hu/rss/kultura",
    }
    
    def __init__(self):
        self.db = connect_mongodb_sync()
    
    def get_available_feeds(self) -> Dict[str, str]:
        """Get list of available RSS feeds"""
        return self.RSS_FEEDS.copy()
    
    def fetch_feed(
        self,
        feed_type: str = "all",
        feed_url: Optional[str] = None,
        max_items: int = 50
    ) -> List[Dict[str, Any]]:
        """
        Fetch articles from MTI RSS feed
        
        Args:
            feed_type: Feed type (all, domestic, international, economy, politics, sports, culture)
            feed_url: Custom RSS feed URL (overrides feed_type)
            max_items: Maximum number of items to fetch
            
        Returns:
            List of article dictionaries
        """
        articles = []
        
        # Determine feed URL
        if feed_url:
            url = feed_url
        elif feed_type in self.RSS_FEEDS:
            url = self.RSS_FEEDS[feed_type]
        else:
            logger.warning(f"Unknown feed type: {feed_type}, using 'all'")
            url = self.RSS_FEEDS["all"]
        
        try:
            # Fetch RSS feed
            response = requests.get(url, timeout=30, headers={
                "User-Agent": "Mozilla/5.0 (compatible; NincsenekFenyek/1.0; +https://github.com/nincsenekfenyek)"
            })
            response.raise_for_status()
            
            # Parse RSS feed
            feed = feedparser.parse(response.content)
            
            if feed.bozo and feed.bozo_exception:
                logger.warning(f"RSS feed parsing warning: {feed.bozo_exception}")
            
            # Extract articles
            for entry in feed.entries[:max_items]:
                try:
                    article = self._parse_entry(entry, feed_type)
                    if article:
                        articles.append(article)
                except Exception as e:
                    logger.error(f"Error parsing RSS entry: {e}")
                    continue
            
            logger.info(f"MTI: Fetched {len(articles)} articles from {feed_type} feed")
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error fetching MTI RSS feed {url}: {e}")
        except Exception as e:
            logger.error(f"Error parsing MTI RSS feed: {e}")
        
        return articles
    
    def _parse_entry(self, entry: Any, category: str) -> Optional[Dict[str, Any]]:
        """
        Parse RSS feed entry into article dictionary
        
        Args:
            entry: FeedParser entry object
            category: Article category
            
        Returns:
            Article dictionary or None
        """
        try:
            # Extract title and link
            title = entry.get("title", "").strip()
            link = entry.get("link", "")
            
            if not title or not link:
                return None
            
            # Extract published date
            published = None
            if hasattr(entry, "published_parsed") and entry.published_parsed:
                try:
                    published = datetime(*entry.published_parsed[:6])
                except:
                    pass
            
            if not published and hasattr(entry, "published"):
                try:
                    # Try to parse date string
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
            
            # Clean HTML from content
            if content:
                soup = BeautifulSoup(content, "html.parser")
                content = soup.get_text(strip=True)
            
            # Extract description
            description = content[:500] if content else title
            
            # Generate article ID from link
            article_id = self._generate_article_id(link)
            
            # Extract tags/categories
            tags = []
            if hasattr(entry, "tags"):
                tags = [tag.term for tag in entry.tags]
            
            article = {
                "article_id": article_id,
                "title": title,
                "content": content,
                "description": description,
                "link": link,
                "published_at": published,
                "category": category,
                "tags": tags,
                "source": "mti",
                "collected_at": datetime.utcnow()
            }
            
            return article
        
        except Exception as e:
            logger.error(f"Error parsing RSS entry: {e}")
            return None
    
    def _generate_article_id(self, url: str) -> str:
        """Generate unique article ID from URL"""
        # Extract ID from URL or hash the URL
        match = re.search(r'/(\d+)/', url)
        if match:
            return f"mti_{match.group(1)}"
        
        # Fallback: hash the URL
        import hashlib
        url_hash = hashlib.md5(url.encode()).hexdigest()[:12]
        return f"mti_{url_hash}"
    
    def store_articles(self, articles: List[Dict[str, Any]], source_id: Optional[str] = None) -> int:
        """
        Store articles in MongoDB
        
        Args:
            articles: List of article dictionaries
            source_id: Optional source ID for tracking
            
        Returns:
            Number of articles stored
        """
        stored_count = 0
        
        for article in articles:
            try:
                article_id = article.get("article_id")
                if not article_id:
                    continue
                
                # Check if article already exists
                existing = self.db.posts.find_one({
                    "metadata.article_id": article_id,
                    "source": "mti"
                })
                
                if existing:
                    continue
                
                # Prepare post document
                post_doc = {
                    "source_id": source_id or "mti_default",
                    "source": "mti",
                    "source_type": "news",
                    "content": article.get("content", article.get("description", "")),
                    "title": article.get("title", ""),
                    "posted_at": article.get("published_at", datetime.utcnow()),
                    "collected_at": datetime.utcnow(),
                    "metadata": {
                        "article_id": article_id,
                        "link": article.get("link"),
                        "category": article.get("category", "all"),
                        "tags": article.get("tags", []),
                        "description": article.get("description", "")
                    }
                }
                
                # Insert into database
                self.db.posts.insert_one(post_doc)
                stored_count += 1
                
            except Exception as e:
                logger.error(f"Error storing MTI article: {e}")
                continue
        
        logger.info(f"MTI: Stored {stored_count} new articles")
        return stored_count
    
    def collect_articles(
        self,
        feed_type: str = "all",
        feed_url: Optional[str] = None,
        max_items: int = 50,
        store: bool = True,
        source_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Collect articles from MTI RSS feed
        
        Args:
            feed_type: Feed type
            feed_url: Custom feed URL
            max_items: Maximum items to fetch
            store: Whether to store in database
            source_id: Optional source ID
            
        Returns:
            Dictionary with collection results
        """
        # Fetch articles
        articles = self.fetch_feed(feed_type, feed_url, max_items)
        
        # Store articles if requested
        stored_count = 0
        if store and articles:
            stored_count = self.store_articles(articles, source_id)
        
        return {
            "success": True,
            "feed_type": feed_type,
            "articles_fetched": len(articles),
            "articles_stored": stored_count,
            "articles": articles[:10] if not store else []  # Return samples if not storing
        }
    
    def search_articles(
        self,
        query: str,
        category: Optional[str] = None,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """
        Search for articles in stored MTI articles
        
        Args:
            query: Search query
            category: Optional category filter
            limit: Maximum results
            
        Returns:
            List of matching articles
        """
        try:
            search_filter = {
                "source": "mti",
                "$or": [
                    {"content": {"$regex": query, "$options": "i"}},
                    {"title": {"$regex": query, "$options": "i"}},
                    {"metadata.description": {"$regex": query, "$options": "i"}}
                ]
            }
            
            if category:
                search_filter["metadata.category"] = category
            
            articles = list(
                self.db.posts.find(search_filter)
                .sort("posted_at", -1)
                .limit(limit)
            )
            
            return articles
            
        except Exception as e:
            logger.error(f"Error searching MTI articles: {e}")
            return []

