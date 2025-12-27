"""
Statistics Collection Services
Provides integration with statistical data sources (EUROSTAT, KSH, etc.)
"""

from .eurostat import EurostatService
from .ksh import KSHService

__all__ = ["EurostatService", "KSHService"]

