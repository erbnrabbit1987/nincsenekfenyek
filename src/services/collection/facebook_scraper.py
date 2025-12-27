"""
Facebook Scraper Service
Uses Scrapy + BeautifulSoup4 + Selenium for scraping Facebook posts
"""
import re
import time
import logging
from datetime import datetime
from typing import List, Dict, Optional, Any
from urllib.parse import urlparse, parse_qs

from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.common.exceptions import TimeoutException, NoSuchElementException

logger = logging.getLogger(__name__)


class FacebookScraper:
    """Facebook profile scraper using Selenium and BeautifulSoup"""
    
    def __init__(
        self,
        headless: bool = True,
        wait_timeout: int = 10,
        scroll_pause: float = 2.0
    ):
        """
        Initialize Facebook scraper
        
        Args:
            headless: Run browser in headless mode
            wait_timeout: Timeout for page loads (seconds)
            scroll_pause: Pause between scrolls (seconds)
        """
        self.headless = headless
        self.wait_timeout = wait_timeout
        self.scroll_pause = scroll_pause
        self.driver = None
    
    def _setup_driver(self) -> webdriver.Chrome:
        """Setup Chrome WebDriver with options"""
        chrome_options = Options()
        if self.headless:
            chrome_options.add_argument("--headless")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-blink-features=AutomationControlled")
        chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
        chrome_options.add_experimental_option('useAutomationExtension', False)
        
        # User agent to avoid detection
        chrome_options.add_argument(
            "user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/120.0.0.0 Safari/537.36"
        )
        
        self.driver = webdriver.Chrome(options=chrome_options)
        self.driver.execute_script(
            "Object.defineProperty(navigator, 'webdriver', {get: () => undefined})"
        )
        return self.driver
    
    def _normalize_profile_url(self, identifier: str) -> str:
        """
        Normalize Facebook profile identifier to URL
        
        Args:
            identifier: Username, URL, or profile ID
            
        Returns:
            Normalized Facebook profile URL
        """
        identifier = identifier.strip()
        
        # If it's already a URL
        if identifier.startswith("http"):
            return identifier
        
        # If it's a username (no dots/slashes)
        if not re.search(r'[/.]', identifier):
            return f"https://www.facebook.com/{identifier}"
        
        # If it's a profile ID (numeric)
        if identifier.isdigit():
            return f"https://www.facebook.com/profile.php?id={identifier}"
        
        return identifier
    
    def _extract_post_id(self, post_element) -> Optional[str]:
        """Extract post ID from post element"""
        try:
            # Try to find post link
            post_link = post_element.find('a', href=re.compile(r'/posts/|/permalink/'))
            if post_link:
                href = post_link.get('href', '')
                # Extract post ID from URL
                match = re.search(r'/(\d+)(?:/posts/|/permalink/)(\d+)', href)
                if match:
                    return f"{match.group(1)}_{match.group(2)}"
            
            # Try data-ft attribute
            data_ft = post_element.get('data-ft', '{}')
            if 'top_level_post_id' in data_ft:
                return data_ft['top_level_post_id']
        except Exception as e:
            logger.debug(f"Error extracting post ID: {e}")
        
        return None
    
    def _extract_timestamp(self, post_element) -> Optional[datetime]:
        """Extract timestamp from post element"""
        try:
            # Look for time elements
            time_element = post_element.find('a', {'aria-label': re.compile(r'ago|at')})
            if time_element:
                aria_label = time_element.get('aria-label', '')
                # Try to parse relative time (e.g., "2 hours ago")
                # For now, return current time - will need proper parsing
                return datetime.utcnow()
            
            # Try abbr element with title
            abbr = post_element.find('abbr')
            if abbr and abbr.get('data-utime'):
                timestamp = int(abbr['data-utime'])
                return datetime.fromtimestamp(timestamp)
        except Exception as e:
            logger.debug(f"Error extracting timestamp: {e}")
        
        return datetime.utcnow()
    
    def _extract_likes(self, post_element) -> int:
        """Extract number of likes from post element"""
        try:
            # Look for like count in various places
            like_texts = post_element.find_all(string=re.compile(r'\d+\s*(like|react)', re.I))
            for text in like_texts:
                match = re.search(r'(\d+)', text)
                if match:
                    return int(match.group(1))
        except Exception as e:
            logger.debug(f"Error extracting likes: {e}")
        
        return 0
    
    def _extract_comments(self, post_element) -> List[Dict[str, Any]]:
        """Extract comments from post element"""
        comments = []
        try:
            comment_elements = post_element.find_all('div', {'data-testid': re.compile(r'comment')})
            for comment_elem in comment_elements[:10]:  # Limit to 10 comments
                comment_text = comment_elem.get_text(strip=True)
                if comment_text:
                    comments.append({
                        'text': comment_text,
                        'author': None,  # Would need more complex parsing
                        'timestamp': None
                    })
        except Exception as e:
            logger.debug(f"Error extracting comments: {e}")
        
        return comments
    
    def _extract_images(self, post_element) -> List[str]:
        """Extract image URLs from post element"""
        images = []
        try:
            img_tags = post_element.find_all('img')
            for img in img_tags:
                src = img.get('src', '')
                # Filter out profile pictures and icons
                if src and 'profile' not in src.lower() and 'icon' not in src.lower():
                    if src.startswith('http'):
                        images.append(src)
        except Exception as e:
            logger.debug(f"Error extracting images: {e}")
        
        return images
    
    def _extract_content(self, post_element) -> str:
        """Extract text content from post element"""
        try:
            # Look for post text in various structures
            content_selectors = [
                {'data-testid': 'post_message'},
                {'class': re.compile(r'post.*text|userContent')},
            ]
            
            for selector in content_selectors:
                content_elem = post_element.find('div', selector)
                if content_elem:
                    return content_elem.get_text(strip=True)
            
            # Fallback: get all text
            return post_element.get_text(strip=True)
        except Exception as e:
            logger.debug(f"Error extracting content: {e}")
            return ""
    
    def _parse_post_element(self, post_element, source_id: str) -> Optional[Dict[str, Any]]:
        """Parse a single post element into structured data"""
        try:
            post_id = self._extract_post_id(post_element)
            if not post_id:
                return None
            
            content = self._extract_content(post_element)
            if not content:
                return None
            
            timestamp = self._extract_timestamp(post_element)
            likes = self._extract_likes(post_element)
            comments = self._extract_comments(post_element)
            images = self._extract_images(post_element)
            
            return {
                'post_id': post_id,
                'source_id': source_id,
                'content': content,
                'posted_at': timestamp,
                'metadata': {
                    'likes': likes,
                    'comments_count': len(comments),
                    'comments': comments[:5],  # Store first 5 comments
                    'images': images,
                },
                'collected_at': datetime.utcnow()
            }
        except Exception as e:
            logger.error(f"Error parsing post element: {e}")
            return None
    
    def scrape_profile(
        self,
        identifier: str,
        source_id: str,
        max_posts: int = 20,
        scroll_count: int = 3
    ) -> List[Dict[str, Any]]:
        """
        Scrape posts from a Facebook profile
        
        Args:
            identifier: Facebook profile identifier (username, URL, or ID)
            source_id: Source ID for tracking
            max_posts: Maximum number of posts to collect
            scroll_count: Number of times to scroll down
            
        Returns:
            List of post dictionaries
        """
        if not self.driver:
            self._setup_driver()
        
        profile_url = self._normalize_profile_url(identifier)
        logger.info(f"Scraping Facebook profile: {profile_url}")
        
        posts = []
        
        try:
            # Navigate to profile
            self.driver.get(profile_url)
            time.sleep(3)  # Wait for initial page load
            
            # Wait for posts to load
            try:
                WebDriverWait(self.driver, self.wait_timeout).until(
                    EC.presence_of_element_located((By.TAG_NAME, "article"))
                )
            except TimeoutException:
                logger.warning(f"Timeout waiting for posts on {profile_url}")
                return posts
            
            # Scroll to load more posts
            for i in range(scroll_count):
                self.driver.execute_script(
                    "window.scrollTo(0, document.body.scrollHeight);"
                )
                time.sleep(self.scroll_pause)
            
            # Parse HTML
            html = self.driver.page_source
            soup = BeautifulSoup(html, 'html.parser')
            
            # Find post elements (articles)
            post_elements = soup.find_all('article', limit=max_posts)
            logger.info(f"Found {len(post_elements)} post elements")
            
            # Parse each post
            seen_post_ids = set()
            for post_elem in post_elements:
                post_data = self._parse_post_element(post_elem, source_id)
                if post_data and post_data['post_id'] not in seen_post_ids:
                    seen_post_ids.add(post_data['post_id'])
                    posts.append(post_data)
                    
                    if len(posts) >= max_posts:
                        break
            
            logger.info(f"Successfully scraped {len(posts)} posts")
            
        except Exception as e:
            logger.error(f"Error scraping Facebook profile {profile_url}: {e}")
        
        return posts
    
    def close(self):
        """Close the browser driver"""
        if self.driver:
            self.driver.quit()
            self.driver = None
    
    def __enter__(self):
        """Context manager entry"""
        if not self.driver:
            self._setup_driver()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit"""
        self.close()


