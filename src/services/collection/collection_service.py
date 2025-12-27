"""
Collection Service
Coordinates data collection from various sources
"""
import logging
from typing import List, Dict, Optional, Any
from datetime import datetime

from src.models.database import connect_mongodb_sync
from src.models.mongodb_models import Source, Post
from src.services.collection.facebook_scraper import FacebookScraper
from src.services.collection.news import MTIService, MagyarKozlonyService

logger = logging.getLogger(__name__)


class CollectionService:
    """Service for collecting data from sources"""
    
    def __init__(self):
        self.db = connect_mongodb_sync()
    
    def _post_exists(self, post_id: str, source_id: str) -> bool:
        """Check if a post already exists in the database"""
        existing = self.db.posts.find_one({
            "metadata.post_id": post_id,
            "source_id": source_id
        })
        return existing is not None
    
    def _save_posts(self, posts: List[Dict[str, Any]]) -> int:
        """
        Save posts to database, skipping duplicates
        
        Args:
            posts: List of post dictionaries
            
        Returns:
            Number of new posts saved
        """
        saved_count = 0
        
        for post_data in posts:
            try:
                post_id = post_data.get('post_id')
                source_id = post_data.get('source_id')
                
                if not post_id or not source_id:
                    logger.warning("Post missing post_id or source_id, skipping")
                    continue
                
                # Check if post already exists
                if self._post_exists(post_id, source_id):
                    logger.debug(f"Post {post_id} already exists, skipping")
                    continue
                
                # Create Post object
                post = Post(
                    source_id=source_id,
                    content=post_data.get('content', ''),
                    posted_at=post_data.get('posted_at', datetime.utcnow()),
                    metadata={
                        'post_id': post_id,
                        **post_data.get('metadata', {})
                    },
                    collected_at=post_data.get('collected_at', datetime.utcnow())
                )
                
                # Save to database
                result = self.db.posts.insert_one(post.to_dict())
                if result.inserted_id:
                    saved_count += 1
                    logger.info(f"Saved new post {post_id} from source {source_id}")
                
            except Exception as e:
                logger.error(f"Error saving post: {e}")
        
        return saved_count
    
    def collect_facebook_posts(
        self,
        source: Source,
        max_posts: int = 20,
        scroll_count: int = 3
    ) -> Dict[str, Any]:
        """
        Collect posts from a Facebook source
        
        Args:
            source: Source object with Facebook profile info
            max_posts: Maximum number of posts to collect
            scroll_count: Number of scrolls to perform
            
        Returns:
            Dictionary with collection results
        """
        logger.info(f"Starting Facebook collection for source {source._id}")
        
        result = {
            'source_id': str(source._id),
            'source_type': source.source_type,
            'posts_found': 0,
            'posts_saved': 0,
            'errors': []
        }
        
        try:
            # Initialize scraper
            with FacebookScraper(headless=True) as scraper:
                # Collect posts
                posts = scraper.scrape_profile(
                    identifier=source.identifier,
                    source_id=str(source._id),
                    max_posts=max_posts,
                    scroll_count=scroll_count
                )
                
                result['posts_found'] = len(posts)
                
                # Save posts to database
                if posts:
                    saved = self._save_posts(posts)
                    result['posts_saved'] = saved
                    logger.info(
                        f"Collected {len(posts)} posts, "
                        f"saved {saved} new posts for source {source._id}"
                    )
                else:
                    logger.warning(f"No posts found for source {source._id}")
        
        except Exception as e:
            error_msg = f"Error collecting Facebook posts: {str(e)}"
            logger.error(error_msg)
            result['errors'].append(error_msg)
        
        return result
    
    def collect_mti_news(
        self,
        source: Source,
        max_posts: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Collect news articles from MTI RSS feed
        
        Args:
            source: Source object with MTI feed configuration
            max_posts: Maximum number of articles to collect (optional)
            
        Returns:
            Dictionary with collection results
        """
        logger.info(f"Starting MTI collection for source {source._id}")
        
        result = {
            'source_id': str(source._id),
            'source_type': source.source_type,
            'posts_found': 0,
            'posts_saved': 0,
            'errors': []
        }
        
        try:
            mti_service = MTIService()
            
            # Get feed configuration from source
            feed_type = source.config.get('feed_type', 'all')
            feed_url = source.config.get('feed_url')
            max_items = max_posts or source.config.get('max_items', 50)
            
            # Collect articles
            collection_result = mti_service.collect_articles(
                feed_type=feed_type,
                feed_url=feed_url,
                max_items=max_items,
                store=True,
                source_id=str(source._id)
            )
            
            result['posts_found'] = collection_result.get('articles_fetched', 0)
            result['posts_saved'] = collection_result.get('articles_stored', 0)
            
            logger.info(
                f"MTI collection: found {result['posts_found']} articles, "
                f"saved {result['posts_saved']} new articles for source {source._id}"
            )
        
        except Exception as e:
            error_msg = f"Error collecting MTI news: {str(e)}"
            logger.error(error_msg)
            result['errors'].append(error_msg)
        
        return result
    
    def collect_magyar_kozlony(
        self,
        source: Source,
        max_posts: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Collect official publications from Magyar Közlöny
        
        Args:
            source: Source object with Magyar Közlöny configuration
            max_posts: Maximum number of publications to collect (optional)
            
        Returns:
            Dictionary with collection results
        """
        logger.info(f"Starting Magyar Közlöny collection for source {source._id}")
        
        result = {
            'source_id': str(source._id),
            'source_type': source.source_type,
            'posts_found': 0,
            'posts_saved': 0,
            'errors': []
        }
        
        try:
            kozlony_service = MagyarKozlonyService()
            
            # Get configuration from source
            max_items = max_posts or source.config.get('max_items', 50)
            year = source.config.get('year')
            fetch_details = source.config.get('fetch_details', False)
            
            # Collect publications
            collection_result = kozlony_service.collect_publications(
                max_items=max_items,
                year=year,
                store=True,
                source_id=str(source._id),
                fetch_details=fetch_details
            )
            
            result['posts_found'] = collection_result.get('publications_fetched', 0)
            result['posts_saved'] = collection_result.get('publications_stored', 0)
            
            logger.info(
                f"Magyar Közlöny collection: found {result['posts_found']} publications, "
                f"saved {result['posts_saved']} new publications for source {source._id}"
            )
        
        except Exception as e:
            error_msg = f"Error collecting Magyar Közlöny: {str(e)}"
            logger.error(error_msg)
            result['errors'].append(error_msg)
        
        return result
    
    def collect_from_source(
        self,
        source: Source,
        max_posts: Optional[int] = None
    ) -> Dict[str, Any]:
        """
        Collect data from a source based on its type
        
        Args:
            source: Source object
            max_posts: Maximum number of items to collect (optional)
            
        Returns:
            Dictionary with collection results
        """
        if source.source_type == "facebook":
            max_posts = max_posts or source.config.get('max_posts', 20)
            return self.collect_facebook_posts(source, max_posts=max_posts)
        
        elif source.source_type == "news":
            # MTI RSS feed collection
            return self.collect_mti_news(source, max_posts=max_posts)
        
        elif source.source_type == "official_publication":
            # Magyar Közlöny collection
            return self.collect_magyar_kozlony(source, max_posts=max_posts)
        
        elif source.source_type == "statistics":
            # Statistics collection - to be implemented
            logger.warning("Statistics collection not yet implemented")
            return {
                'source_id': str(source._id),
                'source_type': source.source_type,
                'posts_found': 0,
                'posts_saved': 0,
                'errors': ['Statistics collection not yet implemented']
            }
        
        else:
            error_msg = f"Unknown source type: {source.source_type}"
            logger.error(error_msg)
            return {
                'source_id': str(source._id),
                'source_type': source.source_type,
                'posts_found': 0,
                'posts_saved': 0,
                'errors': [error_msg]
            }


