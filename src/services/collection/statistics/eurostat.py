"""
EUROSTAT API Service
Integrates with EUROSTAT REST API to fetch and store statistical data
"""
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime
import requests
from urllib.parse import urlencode

from src.models.database import connect_mongodb_sync

logger = logging.getLogger(__name__)


class EurostatService:
    """Service for interacting with EUROSTAT API"""
    
    BASE_URL = "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0"
    
    def __init__(self):
        self.db = connect_mongodb_sync()
    
    def search_datasets(
        self,
        query: str,
        language: str = "en"
    ) -> List[Dict[str, Any]]:
        """
        Search for datasets in EUROSTAT
        
        Args:
            query: Search query
            language: Language code (en, de, fr, etc.)
            
        Returns:
            List of dataset metadata dictionaries
        """
        results = []
        
        try:
            # EUROSTAT API endpoint for dataset search
            url = f"{self.BASE_URL}/data/datasets"
            params = {
                "lang": language,
                "format": "JSON"
            }
            
            response = requests.get(url, params=params, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            
            # Filter results by query
            query_lower = query.lower()
            if "dataset" in data:
                for dataset_code, dataset_info in data["dataset"].items():
                    label = dataset_info.get("label", "")
                    if query_lower in label.lower() or query_lower in dataset_code.lower():
                        results.append({
                            "code": dataset_code,
                            "label": label,
                            "last_updated": dataset_info.get("lastUpdate", ""),
                            "source": "eurostat"
                        })
            
            logger.info(f"EUROSTAT: Found {len(results)} datasets for query: {query}")
            
        except requests.exceptions.RequestException as e:
            logger.error(f"EUROSTAT API error during search: {e}")
        except Exception as e:
            logger.error(f"Error searching EUROSTAT datasets: {e}")
        
        return results
    
    def get_dataset_info(
        self,
        dataset_code: str,
        language: str = "en"
    ) -> Optional[Dict[str, Any]]:
        """
        Get metadata for a specific dataset
        
        Args:
            dataset_code: Dataset code (e.g., 'tps00001')
            language: Language code
            
        Returns:
            Dataset metadata dictionary or None
        """
        try:
            url = f"{self.BASE_URL}/data/{dataset_code}"
            params = {
                "lang": language,
                "format": "JSON",
                "lastTimePeriod": 1  # Only get metadata, not all data
            }
            
            response = requests.get(url, params=params, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            
            # Extract metadata
            if "label" in data:
                return {
                    "code": dataset_code,
                    "label": data.get("label", ""),
                    "source": data.get("source", ""),
                    "updated": data.get("updated", ""),
                    "dimension": data.get("dimension", {}),
                    "size": data.get("size", []),
                    "source": "eurostat"
                }
        
        except requests.exceptions.RequestException as e:
            logger.error(f"EUROSTAT API error getting dataset info: {e}")
        except Exception as e:
            logger.error(f"Error getting EUROSTAT dataset info: {e}")
        
        return None
    
    def get_dataset_data(
        self,
        dataset_code: str,
        filters: Optional[Dict[str, List[str]]] = None,
        language: str = "en",
        last_n_periods: Optional[int] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Get data for a specific dataset
        
        Args:
            dataset_code: Dataset code (e.g., 'tps00001')
            filters: Dictionary of dimension filters (e.g., {"geo": ["HU", "DE"]})
            language: Language code
            last_n_periods: Limit to last N time periods
            
        Returns:
            Dataset data dictionary or None
        """
        try:
            url = f"{self.BASE_URL}/data/{dataset_code}"
            params = {
                "lang": language,
                "format": "JSON"
            }
            
            # Add filters if provided
            if filters:
                for dimension, values in filters.items():
                    if values:
                        params[f"filterNonGeo={dimension}"] = "".join(values)
            
            # Limit time periods if specified
            if last_n_periods:
                params["lastTimePeriod"] = last_n_periods
            
            response = requests.get(url, params=params, timeout=60)
            response.raise_for_status()
            
            data = response.json()
            
            logger.info(f"EUROSTAT: Retrieved data for dataset {dataset_code}")
            
            return data
        
        except requests.exceptions.RequestException as e:
            logger.error(f"EUROSTAT API error getting dataset data: {e}")
            if hasattr(e.response, "text"):
                logger.error(f"Response: {e.response.text}")
        except Exception as e:
            logger.error(f"Error getting EUROSTAT dataset data: {e}")
        
        return None
    
    def store_dataset(
        self,
        dataset_code: str,
        dataset_data: Dict[str, Any],
        metadata: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Store dataset data in MongoDB
        
        Args:
            dataset_code: Dataset code
            dataset_data: Dataset data dictionary
            metadata: Optional metadata dictionary
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Prepare document
            document = {
                "dataset_code": dataset_code,
                "source": "eurostat",
                "data": dataset_data,
                "metadata": metadata or {},
                "collected_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            }
            
            # Upsert document
            self.db.statistics.update_one(
                {"dataset_code": dataset_code, "source": "eurostat"},
                {"$set": document},
                upsert=True
            )
            
            logger.info(f"EUROSTAT: Stored dataset {dataset_code} in MongoDB")
            return True
        
        except Exception as e:
            logger.error(f"Error storing EUROSTAT dataset: {e}")
            return False
    
    def collect_dataset(
        self,
        dataset_code: str,
        filters: Optional[Dict[str, List[str]]] = None,
        last_n_periods: Optional[int] = 10,
        store: bool = True
    ) -> Optional[Dict[str, Any]]:
        """
        Collect and optionally store a dataset
        
        Args:
            dataset_code: Dataset code
            filters: Optional dimension filters
            last_n_periods: Number of latest time periods to fetch
            store: Whether to store in MongoDB
            
        Returns:
            Dataset data dictionary or None
        """
        # Get dataset info
        metadata = self.get_dataset_info(dataset_code)
        
        # Get dataset data
        dataset_data = self.get_dataset_data(
            dataset_code=dataset_code,
            filters=filters,
            last_n_periods=last_n_periods
        )
        
        if dataset_data:
            if store:
                self.store_dataset(dataset_code, dataset_data, metadata)
            return dataset_data
        
        return None
    
    def get_stored_dataset(
        self,
        dataset_code: str
    ) -> Optional[Dict[str, Any]]:
        """
        Get stored dataset from MongoDB
        
        Args:
            dataset_code: Dataset code
            
        Returns:
            Stored dataset document or None
        """
        try:
            document = self.db.statistics.find_one({
                "dataset_code": dataset_code,
                "source": "eurostat"
            })
            return document
        except Exception as e:
            logger.error(f"Error retrieving stored dataset: {e}")
            return None
    
    def search_for_statistics(
        self,
        keywords: List[str],
        max_results: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Search for statistics relevant to fact-checking
        
        Args:
            keywords: Keywords to search for
            max_results: Maximum number of results
            
        Returns:
            List of relevant dataset metadata
        """
        results = []
        
        # Combine keywords into search queries
        queries = []
        if keywords:
            queries.append(" ".join(keywords[:3]))  # First 3 keywords
            queries.extend(keywords[:2])  # Individual keywords
        
        # Search for each query
        seen_codes = set()
        for query in queries[:3]:  # Limit to 3 queries
            datasets = self.search_datasets(query)
            for dataset in datasets:
                if dataset["code"] not in seen_codes and len(results) < max_results:
                    results.append(dataset)
                    seen_codes.add(dataset["code"])
        
        return results[:max_results]

