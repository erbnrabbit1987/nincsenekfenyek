"""
News Collection Services
Provides integration with news sources (MTI, Magyar Közlöny, RSS feeds, etc.)
"""

from .mti import MTIService
from .magyar_kozlony import MagyarKozlonyService
from .rss_reader import RSSReaderService

__all__ = ["MTIService", "MagyarKozlonyService", "RSSReaderService"]

