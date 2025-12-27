"""
Statistics API Routes
"""
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, List, Dict, Any

from src.services.collection.statistics import EurostatService
from src.services.collection.tasks import collect_eurostat_dataset_task, update_eurostat_datasets_task
from src.models.database import connect_mongodb_sync

router = APIRouter(prefix="/api/statistics", tags=["statistics"])


class DatasetSearchResponse(BaseModel):
    query: str
    results: List[Dict[str, Any]]


class DatasetInfoResponse(BaseModel):
    code: str
    label: str
    source: str
    metadata: Optional[Dict[str, Any]] = None


class DatasetCollectionResponse(BaseModel):
    success: bool
    dataset_code: str
    task_id: Optional[str] = None
    message: str


@router.get("/eurostat/search", response_model=DatasetSearchResponse)
async def search_eurostat_datasets(
    query: str = Query(..., description="Search query"),
    language: str = Query("en", description="Language code")
):
    """Search for EUROSTAT datasets"""
    try:
        eurostat_service = EurostatService()
        results = eurostat_service.search_datasets(query, language)
        return {
            "query": query,
            "results": results
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error searching datasets: {str(e)}")


@router.get("/eurostat/dataset/{dataset_code}", response_model=DatasetInfoResponse)
async def get_eurostat_dataset_info(
    dataset_code: str,
    language: str = Query("en", description="Language code")
):
    """Get EUROSTAT dataset information"""
    try:
        eurostat_service = EurostatService()
        info = eurostat_service.get_dataset_info(dataset_code, language)
        
        if not info:
            raise HTTPException(status_code=404, detail=f"Dataset {dataset_code} not found")
        
        return {
            "code": info["code"],
            "label": info["label"],
            "source": info["source"],
            "metadata": info
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error getting dataset info: {str(e)}")


@router.post("/eurostat/collect/{dataset_code}", response_model=DatasetCollectionResponse)
async def collect_eurostat_dataset(
    dataset_code: str,
    last_n_periods: int = Query(10, description="Number of latest time periods"),
    store: bool = Query(True, description="Store in MongoDB"),
    background: bool = Query(False, description="Run in background")
):
    """Collect EUROSTAT dataset (synchronously or as background task)"""
    try:
        if background:
            # Run as Celery task
            task = collect_eurostat_dataset_task.delay(
                dataset_code=dataset_code,
                last_n_periods=last_n_periods,
                store=store
            )
            return {
                "success": True,
                "dataset_code": dataset_code,
                "task_id": task.id,
                "message": f"Collection task started for dataset {dataset_code}"
            }
        else:
            # Run synchronously
            eurostat_service = EurostatService()
            dataset_data = eurostat_service.collect_dataset(
                dataset_code=dataset_code,
                last_n_periods=last_n_periods,
                store=store
            )
            
            if dataset_data:
                return {
                    "success": True,
                    "dataset_code": dataset_code,
                    "message": f"Dataset {dataset_code} collected successfully"
                }
            else:
                raise HTTPException(
                    status_code=500,
                    detail=f"Failed to collect dataset {dataset_code}"
                )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error collecting dataset: {str(e)}")


@router.get("/eurostat/stored/{dataset_code}")
async def get_stored_eurostat_dataset(dataset_code: str):
    """Get stored EUROSTAT dataset from MongoDB"""
    try:
        eurostat_service = EurostatService()
        stored_data = eurostat_service.get_stored_dataset(dataset_code)
        
        if not stored_data:
            raise HTTPException(
                status_code=404,
                detail=f"Dataset {dataset_code} not found in database"
            )
        
        return stored_data
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error retrieving stored dataset: {str(e)}")


@router.get("/eurostat/stored")
async def list_stored_eurostat_datasets():
    """List all stored EUROSTAT datasets"""
    try:
        db = connect_mongodb_sync()
        datasets = list(db.statistics.find(
            {"source": "eurostat"},
            {"dataset_code": 1, "metadata": 1, "updated_at": 1, "collected_at": 1}
        ))
        
        return {
            "count": len(datasets),
            "datasets": datasets
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error listing datasets: {str(e)}")


@router.post("/eurostat/update")
async def update_eurostat_datasets(
    dataset_codes: Optional[List[str]] = None,
    last_n_periods: int = Query(10, description="Number of latest time periods"),
    background: bool = Query(True, description="Run in background")
):
    """Update multiple EUROSTAT datasets"""
    try:
        if background:
            # Run as Celery task
            task = update_eurostat_datasets_task.delay(
                dataset_codes=dataset_codes,
                last_n_periods=last_n_periods
            )
            return {
                "success": True,
                "task_id": task.id,
                "message": "Update task started"
            }
        else:
            # Run synchronously
            eurostat_service = EurostatService()
            results = {
                "total_datasets": len(dataset_codes) if dataset_codes else 0,
                "successful": 0,
                "failed": 0,
                "dataset_results": []
            }
            
            if dataset_codes:
                for dataset_code in dataset_codes:
                    dataset_data = eurostat_service.collect_dataset(
                        dataset_code=dataset_code,
                        last_n_periods=last_n_periods,
                        store=True
                    )
                    if dataset_data:
                        results["successful"] += 1
                    else:
                        results["failed"] += 1
            
            return results
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error updating datasets: {str(e)}")

