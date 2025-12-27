#!/bin/bash

# API Kulcsok Tesztelése
# Ez a script ellenőrzi, hogy az API kulcsok be vannak-e állítva és működnek-e

echo "=================================================="
echo "API KULCSOK ELLENŐRZÉSE"
echo "=================================================="
echo ""

# 1. Környezeti változók ellenőrzése
echo "1. Környezeti változók ellenőrzése..."
docker compose exec -T backend env | grep -E "GOOGLE|BING" | while read line; do
  key=$(echo "$line" | cut -d= -f1)
  value=$(echo "$line" | cut -d= -f2-)
  if [ -z "$value" ]; then
    echo "  ✗ $key: NINCS BEÁLLÍTVA"
  else
    # Csak az első 10 karaktert mutassuk
    masked="${value:0:10}***"
    echo "  ✓ $key: $masked"
  fi
done

echo ""
echo "2. Service konfiguráció ellenőrzése..."
docker compose exec -T backend python << 'PYEOF'
from src.config.settings import get_settings
from src.services.search import GoogleSearchService, BingSearchService

# Settings ellenőrzése
settings = get_settings()
print("\n" + "=" * 50)
print("SETTINGS ELLENŐRZÉSE")
print("=" * 50)
print(f"Google Search API Key: {'✓ BEÁLLÍTVA' if settings.GOOGLE_SEARCH_API_KEY else '✗ NINCS BEÁLLÍTVA'}")
print(f"Google Search Engine ID: {'✓ BEÁLLÍTVA' if settings.GOOGLE_SEARCH_ENGINE_ID else '✗ NINCS BEÁLLÍTVA'}")
print(f"Bing Search API Key: {'✓ BEÁLLÍTVA' if settings.BING_SEARCH_API_KEY else '✗ NINCS BEÁLLÍTVA'}")

# Service-ek ellenőrzése
print("\n" + "=" * 50)
print("SERVICE KONFIGURÁCIÓ")
print("=" * 50)
google_service = GoogleSearchService()
bing_service = BingSearchService()

print(f"\nGoogle Search Service: {'✓ KONFIGURÁLVA' if google_service.is_configured() else '✗ NINCS KONFIGURÁLVA'}")
print(f"Bing Search Service: {'✓ KONFIGURÁLVA' if bing_service.is_configured() else '✗ NINCS KONFIGURÁLVA'}")

# Teszt keresés (ha konfigurálva van)
if google_service.is_configured():
    print("\n" + "=" * 50)
    print("GOOGLE SEARCH TESZT")
    print("=" * 50)
    try:
        results = google_service.search("Magyarország", num_results=3)
        print(f"✓ Teszt keresés sikeres! {len(results)} eredmény található.")
        if results:
            print(f"  Első eredmény: {results[0].get('title', 'N/A')[:50]}...")
    except Exception as e:
        print(f"✗ Teszt keresés hibás: {e}")

if bing_service.is_configured():
    print("\n" + "=" * 50)
    print("BING SEARCH TESZT")
    print("=" * 50)
    try:
        results = bing_service.search("Hungary", num_results=3)
        print(f"✓ Teszt keresés sikeres! {len(results)} eredmény található.")
        if results:
            print(f"  Első eredmény: {results[0].get('title', 'N/A')[:50]}...")
    except Exception as e:
        print(f"✗ Teszt keresés hibás: {e}")

print("\n" + "=" * 50)
PYEOF

echo ""
echo "3. Fact-checking integráció ellenőrzése..."
docker compose exec -T backend python << 'PYEOF'
from src.services.factcheck.factcheck_service import FactCheckService
import inspect

service = FactCheckService()

# Check integration in _search_external_sources method
try:
    source_code = inspect.getsource(service._search_external_sources)
    uses_google = 'google_search' in source_code.lower() or 'GoogleSearchService' in source_code
    uses_bing = 'bing_search' in source_code.lower() or 'BingSearchService' in source_code
except Exception as e:
    print(f"Could not check integration: {e}")
    uses_google = False
    uses_bing = False

print("\n" + "=" * 50)
print("FACT-CHECKING INTEGRÁCIÓ")
print("=" * 50)
print(f"\nGoogle Search integráció: {'✓ HASZNÁLVA' if uses_google else '✗ NEM HASZNÁLVA'}")
print(f"Bing Search integráció: {'✓ HASZNÁLVA' if uses_bing else '✗ NEM HASZNÁLVA'}")

# Check if services are initialized
print(f"\nGoogle Search Service inicializálva: {'✓' if hasattr(service, 'google_search') else '✗'}")
print(f"Bing Search Service inicializálva: {'✓' if hasattr(service, 'bing_search') else '✗'}")

# Test external sources search directly
if service.google_search.is_configured() or service.bing_search.is_configured():
    print("\n" + "=" * 50)
    print("EXTERNAL SOURCES SEARCH TESZT")
    print("=" * 50)
    try:
        keywords = ["Magyarország", "főváros", "Budapest"]
        external_sources = service._search_external_sources(
            claim="Magyarország fővárosa Budapest",
            keywords=keywords
        )
        print(f"\nExternal sources található: {len(external_sources)}")
        if external_sources:
            print("✓ External sources integráció működik!")
            for i, source in enumerate(external_sources[:3], 1):
                title = source.get('title', source.get('url', 'N/A'))
                print(f"  {i}. {title[:60]}...")
        else:
            print("⚠ External sources üres (API kulcsok hiányozhatnak vagy nincs találat)")
    except Exception as e:
        print(f"✗ External sources search hiba: {e}")
        import traceback
        traceback.print_exc()
else:
    print("\n⚠ API kulcsok nincsenek beállítva - external sources nem lesznek használva")

print("\n" + "=" * 50)
PYEOF

echo ""
echo "Tesztelés befejezve!"
echo ""

