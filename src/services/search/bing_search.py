"""
Bing Web Search API Service
"""
import logging
import os
from typing import List, Dict, Any, Optional
from datetime import datetime
import requests
import time

from src.config.settings import get_settings

logger = logging.getLogger(__name__)


class BingSearchService:
    """Service for searching using Bing Web Search API"""
    
    def __init__(self):
        self.settings = get_settings()
        self.api_key = os.getenv("BING_SEARCH_API_KEY", getattr(self.settings, "BING_SEARCH_API_KEY", None))
        self.base_url = "https://api.bing.microsoft.com/v7.0/search"
        self.max_results_per_query = 50
        self.rate_limit_delay = 0.5  # seconds between requests
        self.last_request_time = 0
    
    def is_configured(self) -> bool:
        """Check if Bing Search API is configured"""
        return bool(self.api_key)
    
    def _rate_limit(self):
        """Rate limiting to avoid exceeding API limits"""
        current_time = time.time()
        time_since_last = current_time - self.last_request_time
        if time_since_last < self.rate_limit_delay:
            time.sleep(self.rate_limit_delay - time_since_last)
        self.last_request_time = time.time()
    
    def search(
        self,
        query: str,
        num_results: int = 10,
        market: str = "hu-HU",
        safe_search: str = "Strict",
        freshness: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Perform a Bing search
        
        Args:
            query: Search query
            num_results: Number of results to return (max 50 per request)
            market: Market code (e.g., 'hu-HU' for Hungary, 'en-US' for US)
            safe_search: Safe search setting ('Off', 'Moderate', 'Strict')
            freshness: Date filter ('Day', 'Week', 'Month', 'Year')
            
        Returns:
            List of search result dictionaries
        """
        if not self.is_configured():
            logger.warning("Bing Search API not configured. Set BING_SEARCH_API_KEY")
            return []
        
        results = []
        
        try:
            self._rate_limit()
            
            # Limit num_results to API maximum
            num_results = min(num_results, self.max_results_per_query)
            
            # Prepare headers
            headers = {
                "Ocp-Apim-Subscription-Key": self.api_key
            }
            
            # Prepare request parameters
            params = {
                "q": query,
                "count": num_results,
                "mkt": market,
                "safeSearch": safe_search,
                "textDecorations": False,
                "textFormat": "Raw"
            }
            
            if freshness:
                params["freshness"] = freshness
            
            # Make API request
            response = requests.get(self.base_url, headers=headers, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            
            # Parse web pages results
            if "webPages" in data and "value" in data["webPages"]:
                for item in data["webPages"]["value"]:
                    results.append({
                        "title": item.get("name", ""),
                        "link": item.get("url", ""),
                        "snippet": item.get("snippet", ""),
                        "display_url": item.get("displayUrl", ""),
                        "source": "bing",
                        "timestamp": datetime.utcnow().isoformat()
                    })
            
            logger.info(f"Bing Search: Found {len(results)} results for query: {query}")
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Bing Search API error: {e}")
            if hasattr(e.response, "text"):
                logger.error(f"Response: {e.response.text}")
        except Exception as e:
            logger.error(f"Error in Bing search: {e}")
        
        return results
    
    def search_for_fact_check(
        self,
        claim: str,
        keywords: List[str],
        num_results: int = 5,
        market: str = "hu-HU"
    ) -> List[Dict[str, Any]]:
        """
        Search for fact-checking references
        
        Args:
            claim: The claim to fact-check
            keywords: Keywords extracted from the claim
            num_results: Number of results to return
            market: Market code
            
        Returns:
            List of reference dictionaries
        """
        # Build search query from keywords and claim
        query_parts = []
        
        # Add keywords
        if keywords:
            query_parts.extend(keywords[:3])  # Use top 3 keywords
        
        # Add fact-check related terms in Hungarian
        fact_check_terms = ["tényellenőrzés", "fact-check", "igazság"]
        query_parts.extend([f'"{term}"' for term in fact_check_terms[:1]])
        
        # Combine with claim excerpt (first 100 chars)
        claim_excerpt = claim[:100].replace('"', '')
        query = " ".join(query_parts + [claim_excerpt])
        
        # Search
        search_results = self.search(
            query=query,
            num_results=num_results,
            market=market,
            freshness="Year"  # Last year
        )
        
        # Convert to reference format
        references = []
        for result in search_results:
            references.append({
                "type": "external_web",
                "source": "bing_search",
                "title": result["title"],
                "url": result["link"],
                "snippet": result["snippet"],
                "relevance_score": 0.8,  # Could be improved with text similarity
                "timestamp": result["timestamp"]
            })
        
        return references

