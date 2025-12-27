"""
Magyar Közlöny Service
Integrates with Magyar Közlöny official publications website
"""
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime
import requests
from bs4 import BeautifulSoup
import re

from src.models.database import connect_mongodb_sync

logger = logging.getLogger(__name__)


class MagyarKozlonyService:
    """Service for collecting official publications from Magyar Közlöny"""
    
    BASE_URL = "https://magyarkozlony.hu"
    MAIN_PAGE = f"{BASE_URL}/"
    
    def __init__(self):
        self.db = connect_mongodb_sync()
    
    def fetch_latest_publications(
        self,
        max_items: int = 50,
        year: Optional[int] = None
    ) -> List[Dict[str, Any]]:
        """
        Fetch latest publications from Magyar Közlöny
        
        Args:
            max_items: Maximum number of publications to fetch
            year: Optional year filter
            
        Returns:
            List of publication dictionaries
        """
        publications = []
        
        try:
            # Fetch main page or year-specific page
            url = f"{self.BASE_URL}/" if not year else f"{self.BASE_URL}/?ev={year}"
            
            response = requests.get(url, timeout=30, headers={
                "User-Agent": "Mozilla/5.0 (compatible; NincsenekFenyek/1.0; +https://github.com/nincsenekfenyek)"
            })
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Parse publication list (adjust selectors based on actual structure)
            # Common patterns: table rows, list items, divs with publication info
            publication_items = soup.find_all(['tr', 'li', 'div'], class_=re.compile(r'publication|kozlony|item|entry', re.I))
            
            # If no specific class found, try alternative selectors
            if not publication_items:
                # Try table rows
                tables = soup.find_all('table')
                if tables:
                    for table in tables[:1]:  # First table
                        publication_items = table.find_all('tr')[1:]  # Skip header
            
            for item in publication_items[:max_items]:
                try:
                    publication = self._parse_publication_item(item)
                    if publication:
                        publications.append(publication)
                except Exception as e:
                    logger.debug(f"Error parsing publication item: {e}")
                    continue
            
            logger.info(f"Magyar Közlöny: Fetched {len(publications)} publications")
            
        except requests.exceptions.RequestException as e:
            logger.error(f"Error fetching Magyar Közlöny: {e}")
        except Exception as e:
            logger.error(f"Error parsing Magyar Közlöny: {e}")
        
        return publications
    
    def _parse_publication_item(self, item: Any) -> Optional[Dict[str, Any]]:
        """
        Parse a publication item from HTML
        
        Args:
            item: BeautifulSoup element
            
        Returns:
            Publication dictionary or None
        """
        try:
            # Find links (PDF or detail page)
            link_elem = item.find('a', href=re.compile(r'\.pdf|kozlony|publication', re.I))
            if not link_elem:
                link_elem = item.find('a')
            
            if not link_elem:
                return None
            
            link = link_elem.get('href', '')
            if link and not link.startswith('http'):
                link = f"{self.BASE_URL}{link}" if link.startswith('/') else f"{self.BASE_URL}/{link}"
            
            # Extract text content
            text = item.get_text(strip=True)
            
            # Try to extract publication number, date, title
            publication_number = self._extract_publication_number(text, link)
            publication_date = self._extract_date(text)
            title = link_elem.get_text(strip=True) or text[:200]
            
            # Generate publication ID
            publication_id = self._generate_publication_id(link, publication_number)
            
            # Extract additional metadata
            metadata = {
                "link": link,
                "is_pdf": link.lower().endswith('.pdf'),
                "raw_text": text[:500]  # First 500 chars
            }
            
            publication = {
                "publication_id": publication_id,
                "title": title,
                "publication_number": publication_number,
                "publication_date": publication_date or datetime.utcnow(),
                "link": link,
                "source": "magyar_kozlony",
                "collected_at": datetime.utcnow(),
                "metadata": metadata
            }
            
            return publication
        
        except Exception as e:
            logger.error(f"Error parsing publication item: {e}")
            return None
    
    def _extract_publication_number(self, text: str, url: str) -> Optional[str]:
        """Extract publication number from text or URL"""
        # Try patterns like: "1/2024", "2024/1", "Közlöny 1/2024"
        patterns = [
            r'(?:Közlöny\s*)?(\d+/\d{4})',
            r'(\d{4}/\d+)',
            r'Nr\.\s*(\d+)',
            r'#(\d+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, text, re.I)
            if match:
                return match.group(1)
        
        # Try to extract from URL
        match = re.search(r'/(\d+)/', url)
        if match:
            return match.group(1)
        
        return None
    
    def _extract_date(self, text: str) -> Optional[datetime]:
        """Extract date from text"""
        # Try common date patterns
        date_patterns = [
            r'(\d{4})\.\s*(\d{1,2})\.\s*(\d{1,2})\.',  # 2024.12.27.
            r'(\d{1,2})\.\s*(\d{1,2})\.\s*(\d{4})',    # 27.12.2024
            r'(\d{4})-(\d{2})-(\d{2})',                 # 2024-12-27
        ]
        
        for pattern in date_patterns:
            match = re.search(pattern, text)
            if match:
                try:
                    if len(match.group(1)) == 4:  # Year first
                        year, month, day = match.groups()
                    else:  # Day first
                        day, month, year = match.groups()
                    return datetime(int(year), int(month), int(day))
                except:
                    continue
        
        return None
    
    def _generate_publication_id(self, url: str, publication_number: Optional[str]) -> str:
        """Generate unique publication ID"""
        if publication_number:
            return f"kozlony_{publication_number.replace('/', '_')}"
        
        # Fallback: hash the URL
        import hashlib
        url_hash = hashlib.md5(url.encode()).hexdigest()[:12]
        return f"kozlony_{url_hash}"
    
    def fetch_publication_details(self, publication_url: str) -> Optional[Dict[str, Any]]:
        """
        Fetch detailed information for a publication
        
        Args:
            publication_url: URL of the publication
            
        Returns:
            Detailed publication dictionary or None
        """
        try:
            # Skip if it's a PDF link
            if publication_url.lower().endswith('.pdf'):
                return {
                    "link": publication_url,
                    "type": "pdf",
                    "downloadable": True
                }
            
            response = requests.get(publication_url, timeout=30)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Extract full content (adjust selectors based on actual structure)
            content_elem = soup.find(['div', 'article', 'main'], class_=re.compile(r'content|article|publication', re.I))
            if not content_elem:
                content_elem = soup.find('body')
            
            content = content_elem.get_text(strip=True) if content_elem else ""
            
            # Extract metadata
            metadata = {
                "full_content": content[:5000],  # First 5000 chars
                "html_content": str(content_elem)[:10000] if content_elem else ""
            }
            
            return metadata
        
        except Exception as e:
            logger.error(f"Error fetching publication details: {e}")
            return None
    
    def store_publications(self, publications: List[Dict[str, Any]], source_id: Optional[str] = None) -> int:
        """
        Store publications in MongoDB
        
        Args:
            publications: List of publication dictionaries
            source_id: Optional source ID for tracking
            
        Returns:
            Number of publications stored
        """
        stored_count = 0
        
        for publication in publications:
            try:
                publication_id = publication.get("publication_id")
                if not publication_id:
                    continue
                
                # Check if publication already exists
                existing = self.db.posts.find_one({
                    "metadata.publication_id": publication_id,
                    "source": "magyar_kozlony"
                })
                
                if existing:
                    continue
                
                # Prepare post document
                post_doc = {
                    "source_id": source_id or "magyar_kozlony_default",
                    "source": "magyar_kozlony",
                    "source_type": "official_publication",
                    "content": publication.get("title", ""),
                    "title": publication.get("title", ""),
                    "posted_at": publication.get("publication_date", datetime.utcnow()),
                    "collected_at": datetime.utcnow(),
                    "metadata": {
                        "publication_id": publication_id,
                        "publication_number": publication.get("publication_number"),
                        "link": publication.get("link"),
                        "is_pdf": publication.get("metadata", {}).get("is_pdf", False),
                        "description": publication.get("title", "")
                    }
                }
                
                # Insert into database
                self.db.posts.insert_one(post_doc)
                stored_count += 1
                
            except Exception as e:
                logger.error(f"Error storing Magyar Közlöny publication: {e}")
                continue
        
        logger.info(f"Magyar Közlöny: Stored {stored_count} new publications")
        return stored_count
    
    def collect_publications(
        self,
        max_items: int = 50,
        year: Optional[int] = None,
        store: bool = True,
        source_id: Optional[str] = None,
        fetch_details: bool = False
    ) -> Dict[str, Any]:
        """
        Collect publications from Magyar Közlöny
        
        Args:
            max_items: Maximum items to fetch
            year: Optional year filter
            store: Whether to store in database
            source_id: Optional source ID
            fetch_details: Whether to fetch detailed content
            
        Returns:
            Dictionary with collection results
        """
        # Fetch publications
        publications = self.fetch_latest_publications(max_items, year)
        
        # Optionally fetch details
        if fetch_details:
            for pub in publications:
                link = pub.get("link")
                if link and not link.lower().endswith('.pdf'):
                    details = self.fetch_publication_details(link)
                    if details:
                        pub["details"] = details
        
        # Store publications if requested
        stored_count = 0
        if store and publications:
            stored_count = self.store_publications(publications, source_id)
        
        return {
            "success": True,
            "year": year,
            "publications_fetched": len(publications),
            "publications_stored": stored_count,
            "publications": publications[:10] if not store else []  # Return samples if not storing
        }
    
    def search_publications(
        self,
        query: str,
        year: Optional[int] = None,
        limit: int = 20
    ) -> List[Dict[str, Any]]:
        """
        Search for publications in stored Magyar Közlöny publications
        
        Args:
            query: Search query
            year: Optional year filter
            limit: Maximum results
            
        Returns:
            List of matching publications
        """
        try:
            search_filter = {
                "source": "magyar_kozlony",
                "$or": [
                    {"content": {"$regex": query, "$options": "i"}},
                    {"title": {"$regex": query, "$options": "i"}},
                    {"metadata.description": {"$regex": query, "$options": "i"}},
                    {"metadata.publication_number": {"$regex": query, "$options": "i"}}
                ]
            }
            
            if year:
                search_filter["posted_at"] = {
                    "$gte": datetime(year, 1, 1),
                    "$lt": datetime(year + 1, 1, 1)
                }
            
            publications = list(
                self.db.posts.find(search_filter)
                .sort("posted_at", -1)
                .limit(limit)
            )
            
            return publications
            
        except Exception as e:
            logger.error(f"Error searching Magyar Közlöny publications: {e}")
            return []

