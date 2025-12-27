"""
Google Custom Search API Service
"""
import logging
import os
from typing import List, Dict, Any, Optional
from datetime import datetime
import requests
from urllib.parse import quote_plus

from src.config.settings import get_settings

logger = logging.getLogger(__name__)


class GoogleSearchService:
    """Service for searching using Google Custom Search API"""
    
    def __init__(self):
        self.settings = get_settings()
        self.api_key = os.getenv("GOOGLE_SEARCH_API_KEY", getattr(self.settings, "GOOGLE_SEARCH_API_KEY", None))
        self.search_engine_id = os.getenv("GOOGLE_SEARCH_ENGINE_ID", getattr(self.settings, "GOOGLE_SEARCH_ENGINE_ID", None))
        self.base_url = "https://www.googleapis.com/customsearch/v1"
        self.max_results_per_query = 10
        self.rate_limit_delay = 1.0  # seconds between requests
    
    def is_configured(self) -> bool:
        """Check if Google Search API is configured"""
        return bool(self.api_key and self.search_engine_id)
    
    def search(
        self,
        query: str,
        num_results: int = 10,
        language: str = "hu",
        date_restrict: Optional[str] = None,
        site_search: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Perform a Google search
        
        Args:
            query: Search query
            num_results: Number of results to return (max 10 per request)
            language: Language code (e.g., 'hu' for Hungarian, 'en' for English)
            date_restrict: Date restriction (e.g., 'd' for past day, 'w' for week, 'm' for month, 'y' for year)
            site_search: Restrict search to specific site (e.g., 'site:ksh.hu')
            
        Returns:
            List of search result dictionaries
        """
        if not self.is_configured():
            logger.warning("Google Search API not configured. Set GOOGLE_SEARCH_API_KEY and GOOGLE_SEARCH_ENGINE_ID")
            return []
        
        results = []
        
        try:
            # Limit num_results to API maximum
            num_results = min(num_results, self.max_results_per_query)
            
            # Build search query
            search_query = query
            if site_search:
                search_query = f"site:{site_search} {query}"
            
            # Prepare request parameters
            params = {
                "key": self.api_key,
                "cx": self.search_engine_id,
                "q": search_query,
                "num": num_results,
                "lr": f"lang_{language}",  # Language restriction
                "safe": "active",  # Safe search
            }
            
            if date_restrict:
                params["dateRestrict"] = date_restrict
            
            # Make API request
            response = requests.get(self.base_url, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            
            # Parse results
            if "items" in data:
                for item in data["items"]:
                    results.append({
                        "title": item.get("title", ""),
                        "link": item.get("link", ""),
                        "snippet": item.get("snippet", ""),
                        "display_link": item.get("displayLink", ""),
                        "source": "google",
                        "timestamp": datetime.utcnow().isoformat()
                    })
            
            logger.info(f"Google Search: Found {len(results)} results for query: {query}")
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Google Search API error: {e}")
        except Exception as e:
            logger.error(f"Error in Google search: {e}")
        
        return results
    
    def search_for_fact_check(
        self,
        claim: str,
        keywords: List[str],
        num_results: int = 5,
        language: str = "hu"
    ) -> List[Dict[str, Any]]:
        """
        Search for fact-checking references
        
        Args:
            claim: The claim to fact-check
            keywords: Keywords extracted from the claim
            num_results: Number of results to return
            language: Language code
            
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
            language=language,
            date_restrict="y"  # Last year
        )
        
        # Convert to reference format
        references = []
        for result in search_results:
            references.append({
                "type": "external_web",
                "source": "google_search",
                "title": result["title"],
                "url": result["link"],
                "snippet": result["snippet"],
                "relevance_score": 0.8,  # Could be improved with text similarity
                "timestamp": result["timestamp"]
            })
        
        return references
    
    def search_statistics(
        self,
        query: str,
        site: str = "ksh.hu",
        num_results: int = 5
    ) -> List[Dict[str, Any]]:
        """
        Search for statistics on specific sites (e.g., KSH, EUROSTAT)
        
        Args:
            query: Search query
            site: Site to search (e.g., 'ksh.hu', 'ec.europa.eu')
            num_results: Number of results
            
        Returns:
            List of search results
        """
        return self.search(
            query=query,
            num_results=num_results,
            site_search=site,
            language="hu"
        )

