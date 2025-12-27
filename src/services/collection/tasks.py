"""
Celery Tasks for Data Collection
"""
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, Optional

from celery import shared_task
from celery.schedules import crontab
from bson import ObjectId

from src.models.database import connect_mongodb_sync
from src.models.mongodb_models import Source
from src.services.collection.collection_service import CollectionService
from src.services.collection.statistics import EurostatService, KSHService

logger = logging.getLogger(__name__)


@shared_task(name="collection.collect_facebook_posts")
def collect_facebook_posts_task(source_id: str) -> Dict[str, Any]:
    """
    Celery task to collect posts from a Facebook source
    
    Args:
        source_id: Source ID to collect from
        
    Returns:
        Collection result dictionary
    """
    logger.info(f"Starting Facebook collection task for source {source_id}")
    
    try:
        db = connect_mongodb_sync()
        
        # Get source
        source_doc = db.sources.find_one({"_id": ObjectId(source_id)})
        if not source_doc:
            error_msg = f"Source {source_id} not found"
            logger.error(error_msg)
            return {
                'source_id': source_id,
                'success': False,
                'error': error_msg
            }
        
        # Check if source is active
        source = Source.from_dict(source_doc)
        if not source.is_active:
            logger.info(f"Source {source_id} is not active, skipping")
            return {
                'source_id': source_id,
                'success': False,
                'error': 'Source is not active'
            }
        
        # Check if source type is facebook
        if source.source_type != "facebook":
            error_msg = f"Source {source_id} is not a Facebook source"
            logger.error(error_msg)
            return {
                'source_id': source_id,
                'success': False,
                'error': error_msg
            }
        
        # Collect posts
        collection_service = CollectionService()
        result = collection_service.collect_facebook_posts(source)
        
        # Update last collection timestamp
        db.sources.update_one(
            {"_id": ObjectId(source_id)},
            {"$set": {"last_collected_at": datetime.utcnow()}}
        )
        
        result['success'] = result['posts_saved'] > 0 or len(result.get('errors', [])) == 0
        return result
        
    except Exception as e:
        error_msg = f"Error in collect_facebook_posts_task: {str(e)}"
        logger.error(error_msg, exc_info=True)
        return {
            'source_id': source_id,
            'success': False,
            'error': error_msg
        }


@shared_task(name="collection.collect_all_active_sources")
def collect_all_active_sources_task() -> Dict[str, Any]:
    """
    Celery task to collect from all active sources
    
    Returns:
        Dictionary with collection results for all sources
    """
    logger.info("Starting collection task for all active sources")
    
    try:
        db = connect_mongodb_sync()
        collection_service = CollectionService()
        
        # Get all active sources
        sources = db.sources.find({"is_active": True})
        
        results = {
            'total_sources': 0,
            'successful': 0,
            'failed': 0,
            'source_results': []
        }
        
        for source_doc in sources:
            source = Source.from_dict(source_doc)
            results['total_sources'] += 1
            
            try:
                # Collect based on source type
                result = collection_service.collect_from_source(source)
                
                # Update last collection timestamp
                db.sources.update_one(
                    {"_id": source._id},
                    {"$set": {"last_collected_at": datetime.utcnow()}}
                )
                
                if result.get('posts_saved', 0) > 0 or len(result.get('errors', [])) == 0:
                    results['successful'] += 1
                else:
                    results['failed'] += 1
                
                results['source_results'].append(result)
                
            except Exception as e:
                logger.error(f"Error collecting from source {source._id}: {e}")
                results['failed'] += 1
                results['source_results'].append({
                    'source_id': str(source._id),
                    'success': False,
                    'error': str(e)
                })
        
        logger.info(
            f"Collection task completed: "
            f"{results['successful']}/{results['total_sources']} successful"
        )
        
        return results
        
    except Exception as e:
        error_msg = f"Error in collect_all_active_sources_task: {str(e)}"
        logger.error(error_msg, exc_info=True)
        return {
            'success': False,
            'error': error_msg
        }


@shared_task(name="statistics.collect_eurostat_dataset")
def collect_eurostat_dataset_task(
    dataset_code: str,
    filters: Optional[Dict[str, List[str]]] = None,
    last_n_periods: int = 10,
    store: bool = True
) -> Dict[str, Any]:
    """
    Celery task to collect EUROSTAT dataset
    
    Args:
        dataset_code: EUROSTAT dataset code (e.g., 'tps00001')
        filters: Optional dimension filters
        last_n_periods: Number of latest time periods to fetch
        store: Whether to store in MongoDB
        
    Returns:
        Dictionary with collection result
    """
    logger.info(f"Starting EUROSTAT dataset collection: {dataset_code}")
    
    try:
        eurostat_service = EurostatService()
        
        # Collect dataset
        dataset_data = eurostat_service.collect_dataset(
            dataset_code=dataset_code,
            filters=filters,
            last_n_periods=last_n_periods,
            store=store
        )
        
        if dataset_data:
            logger.info(f"EUROSTAT dataset {dataset_code} collected successfully")
            return {
                'success': True,
                'dataset_code': dataset_code,
                'data_points': len(dataset_data.get('value', [])) if isinstance(dataset_data, dict) else 0,
                'stored': store
            }
        else:
            logger.warning(f"EUROSTAT dataset {dataset_code} collection failed")
            return {
                'success': False,
                'dataset_code': dataset_code,
                'error': 'Failed to retrieve dataset data'
            }
    
    except Exception as e:
        error_msg = f"Error collecting EUROSTAT dataset {dataset_code}: {str(e)}"
        logger.error(error_msg, exc_info=True)
        return {
            'success': False,
            'dataset_code': dataset_code,
            'error': error_msg
        }


@shared_task(name="statistics.update_eurostat_datasets")
def update_eurostat_datasets_task(
    dataset_codes: Optional[List[str]] = None,
    last_n_periods: int = 10
) -> Dict[str, Any]:
    """
    Celery task to update multiple EUROSTAT datasets
    
    Args:
        dataset_codes: List of dataset codes to update (None = update all tracked)
        last_n_periods: Number of latest time periods to fetch
        
    Returns:
        Dictionary with update results
    """
    logger.info("Starting EUROSTAT datasets update task")
    
    try:
        db = connect_mongodb_sync()
        eurostat_service = EurostatService()
        
        # Get dataset codes to update
        if dataset_codes is None:
            # Get all tracked datasets from MongoDB
            tracked = db.statistics.find(
                {"source": "eurostat"},
                {"dataset_code": 1}
            )
            dataset_codes = [doc["dataset_code"] for doc in tracked]
        
        results = {
            'total_datasets': len(dataset_codes),
            'successful': 0,
            'failed': 0,
            'dataset_results': []
        }
        
        for dataset_code in dataset_codes:
            try:
                dataset_data = eurostat_service.collect_dataset(
                    dataset_code=dataset_code,
                    last_n_periods=last_n_periods,
                    store=True
                )
                
                if dataset_data:
                    results['successful'] += 1
                    results['dataset_results'].append({
                        'dataset_code': dataset_code,
                        'success': True
                    })
                else:
                    results['failed'] += 1
                    results['dataset_results'].append({
                        'dataset_code': dataset_code,
                        'success': False,
                        'error': 'Failed to retrieve data'
                    })
            
            except Exception as e:
                logger.error(f"Error updating dataset {dataset_code}: {e}")
                results['failed'] += 1
                results['dataset_results'].append({
                    'dataset_code': dataset_code,
                    'success': False,
                    'error': str(e)
                })
        
        logger.info(
            f"EUROSTAT update task completed: "
            f"{results['successful']}/{results['total_datasets']} successful"
        )
        
        return results
    
    except Exception as e:
        error_msg = f"Error in update_eurostat_datasets_task: {str(e)}"
        logger.error(error_msg, exc_info=True)
        return {
            'success': False,
            'error': error_msg
        }


@shared_task(name="statistics.collect_ksh_dataset")
def collect_ksh_dataset_task(
    dataset_code: str,
    filters: Optional[Dict[str, List[str]]] = None,
    last_n_periods: int = 10,
    store: bool = True,
    source: str = "auto"
) -> Dict[str, Any]:
    """
    Celery task to collect KSH dataset
    
    Args:
        dataset_code: KSH dataset code
        filters: Optional dimension filters
        last_n_periods: Number of latest time periods to fetch
        store: Whether to store in MongoDB
        source: Source type ("auto", "eurostat_hu", "ksh_stadat")
        
    Returns:
        Dictionary with collection result
    """
    logger.info(f"Starting KSH dataset collection: {dataset_code}")
    
    try:
        ksh_service = KSHService()
        
        # Collect dataset
        dataset_data = ksh_service.collect_dataset(
            dataset_code=dataset_code,
            filters=filters,
            last_n_periods=last_n_periods,
            store=store,
            source=source
        )
        
        if dataset_data:
            logger.info(f"KSH dataset {dataset_code} collected successfully")
            return {
                'success': True,
                'dataset_code': dataset_code,
                'data_points': len(dataset_data.get('value', [])) if isinstance(dataset_data, dict) else 0,
                'stored': store,
                'source': dataset_data.get('source', source)
            }
        else:
            logger.warning(f"KSH dataset {dataset_code} collection failed")
            return {
                'success': False,
                'dataset_code': dataset_code,
                'error': 'Failed to retrieve dataset data'
            }
    
    except Exception as e:
        error_msg = f"Error collecting KSH dataset {dataset_code}: {str(e)}"
        logger.error(error_msg, exc_info=True)
        return {
            'success': False,
            'dataset_code': dataset_code,
            'error': error_msg
        }


def get_collection_schedule_for_source(source: Source) -> Optional[Dict[str, Any]]:
    """
    Get Celery Beat schedule configuration for a source
    
    Supports hours, minutes, and seconds in source config
    
    Args:
        source: Source object
        
    Returns:
        Schedule dictionary for Celery Beat, or None if not scheduled
    """
    config = source.config or {}
    schedule_config = config.get('collection_schedule')
    
    if not schedule_config:
        return None
    
    # Parse schedule configuration
    # Format: {"interval": "seconds", "value": 3600}
    # or: {"hours": 1, "minutes": 30, "seconds": 0}
    # or: {"cron": "0 */6 * * *"} for cron format
    
    if 'cron' in schedule_config:
        # Cron format
        cron_parts = schedule_config['cron'].split()
        if len(cron_parts) == 5:
            return {
                'task': 'collection.collect_facebook_posts',
                'schedule': crontab(
                    minute=cron_parts[0],
                    hour=cron_parts[1],
                    day_of_month=cron_parts[2],
                    month_of_year=cron_parts[3],
                    day_of_week=cron_parts[4]
                ),
                'args': [str(source._id)]
            }
    
    # Interval format
    total_seconds = 0
    
    if 'interval' in schedule_config and 'value' in schedule_config:
        interval_type = schedule_config['interval']
        value = schedule_config['value']
        
        if interval_type == 'seconds':
            total_seconds = value
        elif interval_type == 'minutes':
            total_seconds = value * 60
        elif interval_type == 'hours':
            total_seconds = value * 3600
        elif interval_type == 'days':
            total_seconds = value * 86400
    else:
        # Component format: hours, minutes, seconds
        total_seconds = (
            schedule_config.get('hours', 0) * 3600 +
            schedule_config.get('minutes', 0) * 60 +
            schedule_config.get('seconds', 0)
        )
    
    if total_seconds <= 0:
        return None
    
    return {
        'task': 'collection.collect_facebook_posts',
        'schedule': total_seconds,
        'args': [str(source._id)]
    }

