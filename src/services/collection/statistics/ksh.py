"""
KSH (Központi Statisztikai Hivatal) Service
Integrates with KSH STADAT database to fetch Hungarian statistical data

Note: KSH does not provide a public REST API, so this service uses:
- Web scraping from KSH STADAT portal
- File downloads (CSV/Excel)
- EUROSTAT API with Hungarian data filters (as alternative)
"""
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime
import requests
from bs4 import BeautifulSoup
import re

from src.models.database import connect_mongodb_sync
from src.services.collection.statistics.eurostat import EurostatService

logger = logging.getLogger(__name__)


class KSHService:
    """Service for interacting with KSH STADAT database"""
    
    BASE_URL = "https://www.ksh.hu"
    STADAT_URL = "https://www.ksh.hu/stadat_files/hun/hun/xls/hun/stadat_nyito.html"
    
    def __init__(self):
        self.db = connect_mongodb_sync()
        # Use EUROSTAT as alternative source for Hungarian statistics
        self.eurostat_service = EurostatService()
    
    def search_datasets(
        self,
        query: str,
        language: str = "hu"
    ) -> List[Dict[str, Any]]:
        """
        Search for datasets in KSH STADAT database
        
        Since KSH doesn't have a public API, this searches:
        1. EUROSTAT with Hungarian (HU) filter
        2. KSH STADAT portal (if accessible)
        
        Args:
            query: Search query in Hungarian
            language: Language code (default: "hu")
            
        Returns:
            List of dataset metadata dictionaries
        """
        results = []
        
        # Search EUROSTAT for Hungarian statistics
        try:
            eurostat_results = self.eurostat_service.search_datasets(query)
            for result in eurostat_results:
                # Filter for Hungarian data or datasets with HU in code/description
                if "hu" in result.get("code", "").lower() or "hungary" in result.get("label", "").lower():
                    results.append({
                        "code": result["code"],
                        "label": result["label"],
                        "source": "eurostat_hu",
                        "last_updated": result.get("last_updated", "")
                    })
        except Exception as e:
            logger.warning(f"Error searching EUROSTAT for Hungarian data: {e}")
        
        # Try to search KSH STADAT portal (web scraping)
        try:
            stadat_results = self._search_stadat_portal(query)
            results.extend(stadat_results)
        except Exception as e:
            logger.warning(f"Error searching KSH STADAT portal: {e}")
        
        logger.info(f"KSH: Found {len(results)} datasets for query: {query}")
        return results
    
    def _search_stadat_portal(self, query: str) -> List[Dict[str, Any]]:
        """
        Search KSH STADAT portal (web scraping)
        
        Args:
            query: Search query
            
        Returns:
            List of dataset metadata dictionaries
        """
        results = []
        
        try:
            # KSH STADAT portal URL
            url = f"{self.BASE_URL}/stadat"
            params = {
                "lang": "hu",
                "szul_terulet": "all",
                "query": query
            }
            
            response = requests.get(url, params=params, timeout=30)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Parse search results (adjust selectors based on actual KSH portal structure)
            # This is a placeholder - actual implementation depends on KSH portal structure
            result_items = soup.find_all('div', class_=re.compile(r'result|table|dataset', re.I))
            
            for item in result_items[:20]:  # Limit to 20 results
                title_elem = item.find('a') or item.find('h3') or item.find('h4')
                if title_elem:
                    title = title_elem.get_text(strip=True)
                    link = title_elem.get('href', '') if title_elem.name == 'a' else ''
                    
                    results.append({
                        "code": self._extract_code_from_link(link),
                        "label": title,
                        "source": "ksh_stadat",
                        "url": f"{self.BASE_URL}{link}" if link and not link.startswith('http') else link,
                        "last_updated": ""
                    })
        
        except requests.exceptions.RequestException as e:
            logger.error(f"Error accessing KSH STADAT portal: {e}")
        except Exception as e:
            logger.error(f"Error parsing KSH STADAT portal: {e}")
        
        return results
    
    def _extract_code_from_link(self, link: str) -> str:
        """Extract dataset code from KSH link"""
        if not link:
            return ""
        
        # Try to extract code from URL patterns like /stadat/xxx/xxx/xxx
        match = re.search(r'/(\w+)/?$', link)
        if match:
            return match.group(1)
        
        return link.split('/')[-1] if '/' in link else link
    
    def get_dataset_info(
        self,
        dataset_code: str,
        source: str = "auto"
    ) -> Optional[Dict[str, Any]]:
        """
        Get metadata for a specific dataset
        
        Args:
            dataset_code: Dataset code
            source: Source type ("auto", "eurostat_hu", "ksh_stadat")
            
        Returns:
            Dataset metadata dictionary or None
        """
        # Try EUROSTAT first if source is auto or eurostat_hu
        if source in ("auto", "eurostat_hu"):
            try:
                info = self.eurostat_service.get_dataset_info(dataset_code, language="hu")
                if info:
                    return {
                        **info,
                        "source": "eurostat_hu",
                        "ksh_related": True
                    }
            except Exception as e:
                logger.debug(f"EUROSTAT info not available for {dataset_code}: {e}")
        
        # Try to get from stored data
        stored = self.get_stored_dataset(dataset_code)
        if stored:
            return stored.get("metadata", {})
        
        return None
    
    def get_dataset_data(
        self,
        dataset_code: str,
        filters: Optional[Dict[str, List[str]]] = None,
        source: str = "eurostat_hu",
        last_n_periods: Optional[int] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Get data for a specific dataset
        
        Args:
            dataset_code: Dataset code
            filters: Dictionary of dimension filters (add "geo": ["HU"] for Hungary)
            source: Source type
            last_n_periods: Limit to last N time periods
            
        Returns:
            Dataset data dictionary or None
        """
        # Use EUROSTAT with Hungarian filter
        if source in ("auto", "eurostat_hu"):
            try:
                # Ensure Hungarian filter is set
                if filters is None:
                    filters = {}
                if "geo" not in filters:
                    filters["geo"] = ["HU"]  # Hungary
                elif "HU" not in filters["geo"]:
                    filters["geo"].append("HU")
                
                data = self.eurostat_service.get_dataset_data(
                    dataset_code=dataset_code,
                    filters=filters,
                    language="hu",
                    last_n_periods=last_n_periods
                )
                
                if data:
                    return {
                        **data,
                        "source": "eurostat_hu",
                        "country": "Hungary"
                    }
            except Exception as e:
                logger.error(f"Error getting EUROSTAT data for {dataset_code}: {e}")
        
        # Try KSH STADAT download (if dataset_code corresponds to KSH)
        if source in ("auto", "ksh_stadat"):
            try:
                data = self._download_ksh_dataset(dataset_code)
                if data:
                    return data
            except Exception as e:
                logger.error(f"Error getting KSH STADAT data for {dataset_code}: {e}")
        
        return None
    
    def _download_ksh_dataset(self, dataset_code: str) -> Optional[Dict[str, Any]]:
        """
        Download dataset from KSH STADAT portal
        
        Args:
            dataset_code: Dataset code or table ID
            
        Returns:
            Dataset data dictionary or None
        """
        # Placeholder for KSH file download
        # KSH typically provides Excel/CSV downloads
        # This would need to be implemented based on actual KSH portal structure
        
        logger.warning(f"Direct KSH STADAT download not fully implemented for {dataset_code}")
        logger.info("Consider using EUROSTAT API with geo=HU filter as alternative")
        
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
                "source": "ksh",
                "data": dataset_data,
                "metadata": metadata or {},
                "collected_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            }
            
            # Upsert document
            self.db.statistics.update_one(
                {"dataset_code": dataset_code, "source": "ksh"},
                {"$set": document},
                upsert=True
            )
            
            logger.info(f"KSH: Stored dataset {dataset_code} in MongoDB")
            return True
        
        except Exception as e:
            logger.error(f"Error storing KSH dataset: {e}")
            return False
    
    def collect_dataset(
        self,
        dataset_code: str,
        filters: Optional[Dict[str, List[str]]] = None,
        last_n_periods: Optional[int] = 10,
        store: bool = True,
        source: str = "auto"
    ) -> Optional[Dict[str, Any]]:
        """
        Collect and optionally store a dataset
        
        Args:
            dataset_code: Dataset code
            filters: Optional dimension filters
            last_n_periods: Number of latest time periods to fetch
            store: Whether to store in MongoDB
            source: Source type ("auto", "eurostat_hu", "ksh_stadat")
            
        Returns:
            Dataset data dictionary or None
        """
        # Get dataset info
        metadata = self.get_dataset_info(dataset_code, source)
        
        # Get dataset data
        dataset_data = self.get_dataset_data(
            dataset_code=dataset_code,
            filters=filters,
            source=source,
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
            # Try KSH source first
            document = self.db.statistics.find_one({
                "dataset_code": dataset_code,
                "source": "ksh"
            })
            
            if document:
                return document
            
            # Try EUROSTAT source with HU filter
            document = self.db.statistics.find_one({
                "dataset_code": dataset_code,
                "source": "eurostat",
                "data.source": "eurostat_hu"
            })
            
            return document
        except Exception as e:
            logger.error(f"Error retrieving stored KSH dataset: {e}")
            return None
    
    def search_for_statistics(
        self,
        keywords: List[str],
        max_results: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Search for Hungarian statistics relevant to fact-checking
        
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
            # Add Hungarian-specific keywords
            queries.append(" ".join(keywords[:2]) + " Magyarország")
        
        # Search for each query
        seen_codes = set()
        for query in queries[:3]:  # Limit to 3 queries
            datasets = self.search_datasets(query)
            for dataset in datasets:
                if dataset["code"] not in seen_codes and len(results) < max_results:
                    results.append(dataset)
                    seen_codes.add(dataset["code"])
        
        return results[:max_results]

