"""
Search Services
Provides search functionality for fact-checking using various search engines
"""

from .google_search import GoogleSearchService
from .bing_search import BingSearchService

__all__ = ["GoogleSearchService", "BingSearchService"]

