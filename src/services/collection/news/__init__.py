"""
News Collection Services
Provides integration with news sources (MTI, Magyar Közlöny, etc.)
"""

from .mti import MTIService
from .magyar_kozlony import MagyarKozlonyService

__all__ = ["MTIService", "MagyarKozlonyService"]

