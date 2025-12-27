"""
Celery Tasks for Fact-checking
"""
import logging
from typing import Dict, Any, List, Optional

from celery import shared_task
from bson import ObjectId

from src.models.database import connect_mongodb_sync
from src.models.mongodb_models import Post
from src.services.factcheck.factcheck_service import FactCheckService

logger = logging.getLogger(__name__)


@shared_task(name="factcheck.check_post")
def factcheck_post_task(
    post_id: str,
    manual_sources: Optional[List[str]] = None
) -> Dict[str, Any]:
    """
    Celery task to fact-check a post
    
    Args:
        post_id: Post ID to fact-check
        manual_sources: Optional list of manual source URLs
        
    Returns:
        Fact-check result dictionary
    """
    logger.info(f"Starting fact-check task for post {post_id}")
    
    try:
        db = connect_mongodb_sync()
        
        # Get post
        post_doc = db.posts.find_one({"_id": ObjectId(post_id)})
        if not post_doc:
            error_msg = f"Post {post_id} not found"
            logger.error(error_msg)
            return {
                'post_id': post_id,
                'success': False,
                'error': error_msg
            }
        
        post = Post.from_dict(post_doc)
        
        # Perform fact-checking
        factcheck_service = FactCheckService()
        result = factcheck_service.factcheck_post(post, manual_sources)
        
        # Save result
        saved = factcheck_service.save_factcheck_result(result)
        
        if saved:
            logger.info(
                f"Fact-check completed for post {post_id}: "
                f"verdict={result.verdict}, confidence={result.confidence}"
            )
            return {
                'post_id': post_id,
                'success': True,
                'verdict': result.verdict,
                'confidence': result.confidence,
                'claims_count': len(result.claims),
                'references_count': len(result.references)
            }
        else:
            error_msg = "Failed to save fact-check result"
            logger.error(error_msg)
            return {
                'post_id': post_id,
                'success': False,
                'error': error_msg
            }
        
    except Exception as e:
        error_msg = f"Error in factcheck_post_task: {str(e)}"
        logger.error(error_msg, exc_info=True)
        return {
            'post_id': post_id,
            'success': False,
            'error': error_msg
        }


@shared_task(name="factcheck.check_new_posts")
def factcheck_new_posts_task(source_id: Optional[str] = None) -> Dict[str, Any]:
    """
    Celery task to fact-check all new posts (without fact-check results)
    
    Args:
        source_id: Optional source ID to filter posts
        
    Returns:
        Dictionary with fact-check results
    """
    logger.info("Starting fact-check task for new posts")
    
    try:
        db = connect_mongodb_sync()
        factcheck_service = FactCheckService()
        
        # Find posts without fact-check results
        # Get all post IDs that have fact-check results
        checked_post_ids = {
            result['post_id']
            for result in db.factcheck_results.find({}, {'post_id': 1})
        }
        
        # Build query
        query = {}
        if source_id:
            query['source_id'] = source_id
        
        # Get unchecked posts
        unchecked_posts = db.posts.find(query)
        
        results = {
            'total_posts': 0,
            'checked': 0,
            'failed': 0,
            'post_results': []
        }
        
        for post_doc in unchecked_posts:
            post = Post.from_dict(post_doc)
            post_id_str = str(post._id)
            
            # Skip if already checked
            if post_id_str in checked_post_ids:
                continue
            
            results['total_posts'] += 1
            
            try:
                # Fact-check post
                result = factcheck_service.factcheck_post(post)
                
                # Save result
                saved = factcheck_service.save_factcheck_result(result)
                
                if saved:
                    results['checked'] += 1
                    results['post_results'].append({
                        'post_id': post_id_str,
                        'success': True,
                        'verdict': result.verdict,
                        'confidence': result.confidence
                    })
                else:
                    results['failed'] += 1
                    results['post_results'].append({
                        'post_id': post_id_str,
                        'success': False,
                        'error': 'Failed to save result'
                    })
                
            except Exception as e:
                logger.error(f"Error fact-checking post {post_id_str}: {e}")
                results['failed'] += 1
                results['post_results'].append({
                    'post_id': post_id_str,
                    'success': False,
                    'error': str(e)
                })
        
        logger.info(
            f"Fact-check task completed: "
            f"{results['checked']}/{results['total_posts']} posts checked"
        )
        
        return results
        
    except Exception as e:
        error_msg = f"Error in factcheck_new_posts_task: {str(e)}"
        logger.error(error_msg, exc_info=True)
        return {
            'success': False,
            'error': error_msg
        }

