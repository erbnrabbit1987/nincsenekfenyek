# 🧪 API Kulcsok Tesztelése és Ellenőrzése

Ez az útmutató segít ellenőrizni, hogy az API kulcsok helyesen vannak-e beállítva és integrálva.

---

## 🔍 1. Környezeti Változók Ellenőrzése

### Backend konténerben

```bash
# Kapcsolódás a backend konténerhez
docker compose exec backend bash

# Google Search API kulcs ellenőrzése
echo $GOOGLE_SEARCH_API_KEY

# Google Search Engine ID ellenőrzése
echo $GOOGLE_SEARCH_ENGINE_ID

# Bing Search API kulcs ellenőrzése
echo $BING_SEARCH_API_KEY

# Vagy minden Search API változó
env | grep -E "GOOGLE|BING"
```

### .env fájl ellenőrzése

```bash
# .env fájl tartalmának ellenőrzése (a kulcsok nélkül)
grep -E "GOOGLE|BING" .env | sed 's/=.*/=***HIDDEN***/'
```

---

## 🐍 2. Python Kódból Tesztelés

### Backend konténerben Python shell

```bash
# Kapcsolódás a backend konténerhez
docker compose exec backend python

# Import és tesztelés
```

#### Google Search API teszt:

```python
# Importálás
from src.config.settings import get_settings
from src.services.search import GoogleSearchService

# Settings ellenőrzése
settings = get_settings()
print(f"Google API Key: {'SET' if settings.GOOGLE_SEARCH_API_KEY else 'NOT SET'}")
print(f"Google Engine ID: {'SET' if settings.GOOGLE_SEARCH_ENGINE_ID else 'NOT SET'}")

# Service inicializálása
google_service = GoogleSearchService()

# Konfiguráció ellenőrzése
print(f"Google Search configured: {google_service.is_configured()}")

# Teszt keresés (ha konfigurálva van)
if google_service.is_configured():
    try:
        results = google_service.search("Hungary", num_results=3)
        print(f"Search successful! Found {len(results)} results")
        if results:
            print(f"First result: {results[0].get('title', 'N/A')}")
    except Exception as e:
        print(f"Search error: {e}")
else:
    print("Google Search API is not configured. Set GOOGLE_SEARCH_API_KEY and GOOGLE_SEARCH_ENGINE_ID")
```

#### Bing Search API teszt:

```python
# Importálás
from src.services.search import BingSearchService

# Service inicializálása
bing_service = BingSearchService()

# Konfiguráció ellenőrzése
print(f"Bing Search configured: {bing_service.is_configured()}")

# Teszt keresés (ha konfigurálva van)
if bing_service.is_configured():
    try:
        results = bing_service.search("Hungary", num_results=3)
        print(f"Search successful! Found {len(results)} results")
        if results:
            print(f"First result: {results[0].get('title', 'N/A')}")
    except Exception as e:
        print(f"Search error: {e}")
else:
    print("Bing Search API is not configured. Set BING_SEARCH_API_KEY")
```

---

## 🌐 3. API Endpoint-okon keresztül Tesztelés

### Fact-checking endpoint tesztelése

```bash
# Fact-check teszt (használja a Google/Bing API-t ha be van állítva)
curl -X POST "http://localhost:8095/api/factcheck/check" \
  -H "Content-Type: application/json" \
  -d '{
    "claim": "Magyarország népessége 10 millió fő",
    "include_external": true
  }' | jq .
```

**Várt eredmény:**
- Ha az API kulcsok be vannak állítva: `external_sources` mezőben vannak eredmények
- Ha nincsenek beállítva: `external_sources` üres vagy hiányzik

### Search service status endpoint (ha van)

```bash
# Health check
curl http://localhost:8095/health | jq .

# API info (ha van ilyen endpoint)
curl http://localhost:8095/api/info | jq .
```

---

## 📝 4. Kód Integráció Ellenőrzése

### Fact-checking service integráció

```bash
# Nézd meg, hogy a fact-checking service használja-e a search service-eket
docker compose exec backend python -c "
from src.services.factcheck.factcheck_service import FactCheckService
import inspect

# Nézd meg a forrás kódot
source = inspect.getsource(FactCheckService.check_claim)
if 'GoogleSearchService' in source or 'google_search' in source:
    print('✓ Google Search integrálva van')
else:
    print('✗ Google Search NINCS integrálva')

if 'BingSearchService' in source or 'bing_search' in source:
    print('✓ Bing Search integrálva van')
else:
    print('✗ Bing Search NINCS integrálva')
"
```

---

## 🔧 5. Gyors Teszt Script

Hozz létre egy teszt scriptet a könnyebb teszteléshez:

```bash
# Hozd létre a teszt scriptet
cat > test_api_keys.sh << 'EOF'
#!/bin/bash

echo "=== API Kulcsok Tesztelése ==="
echo ""

echo "1. Környezeti változók ellenőrzése..."
docker compose exec -T backend env | grep -E "GOOGLE|BING" | while read line; do
  key=$(echo $line | cut -d= -f1)
  value=$(echo $line | cut -d= -f2-)
  if [ -z "$value" ]; then
    echo "  ✗ $key: NINCS BEÁLLÍTVA"
  else
    # Csak az első 10 karaktert mutassuk
    masked="${value:0:10}***"
    echo "  ✓ $key: $masked"
  fi
done

echo ""
echo "2. Python service-ek tesztelése..."
docker compose exec -T backend python << 'PYEOF'
from src.services.search import GoogleSearchService, BingSearchService

print("\nGoogle Search Service:")
google = GoogleSearchService()
if google.is_configured():
    print("  ✓ Konfigurálva")
    try:
        results = google.search("test", num_results=1)
        print(f"  ✓ Teszt keresés sikeres ({len(results)} eredmény)")
    except Exception as e:
        print(f"  ✗ Teszt keresés hibás: {e}")
else:
    print("  ✗ NINCS konfigurálva")

print("\nBing Search Service:")
bing = BingSearchService()
if bing.is_configured():
    print("  ✓ Konfigurálva")
    try:
        results = bing.search("test", num_results=1)
        print(f"  ✓ Teszt keresés sikeres ({len(results)} eredmény)")
    except Exception as e:
        print(f"  ✗ Teszt keresés hibás: {e}")
else:
    print("  ✗ NINCS konfigurálva")
PYEOF

echo ""
echo "3. Fact-checking integráció tesztelése..."
echo "  (Futtasd: curl -X POST http://localhost:8095/api/factcheck/check ...)"
echo ""
EOF

chmod +x test_api_keys.sh

# Futtatás
./test_api_keys.sh
```

---

## ✅ 6. Várt Eredmények

### Ha minden be van állítva:

```
✓ GOOGLE_SEARCH_API_KEY: AIzaSyC...***
✓ GOOGLE_SEARCH_ENGINE_ID: 01234...***
✓ BING_SEARCH_API_KEY: abc123...***

Google Search Service:
  ✓ Konfigurálva
  ✓ Teszt keresés sikeres (1 eredmény)

Bing Search Service:
  ✓ Konfigurálva
  ✓ Teszt keresés sikeres (1 eredmény)
```

### Ha nincs beállítva:

```
✗ GOOGLE_SEARCH_API_KEY: NINCS BEÁLLÍTVA
✗ GOOGLE_SEARCH_ENGINE_ID: NINCS BEÁLLÍTVA
✗ BING_SEARCH_API_KEY: NINCS BEÁLLÍTVA

Google Search Service:
  ✗ NINCS konfigurálva

Bing Search Service:
  ✗ NINCS konfigurálva
```

---

## 🐛 7. Hibaelhárítás

### API kulcsok nincsenek beállítva

```bash
# .env fájl ellenőrzése
cat .env | grep -E "GOOGLE|BING"

# Ha üres, állítsd be az interaktív scripttel:
./scripts/interactive-env-setup.sh
```

### API kulcsok be vannak állítva, de nem működnek

```bash
# Ellenőrizd, hogy a konténer újraindult-e
docker compose restart backend

# Ellenőrizd a konténer környezeti változóit
docker compose exec backend env | grep GOOGLE

# Ellenőrizd a settings.py-t
docker compose exec backend python -c "from src.config.settings import get_settings; s = get_settings(); print(f'Google Key: {s.GOOGLE_SEARCH_API_KEY[:10] if s.GOOGLE_SEARCH_API_KEY else \"NOT SET\"}')"
```

### API kulcsok hibásak

```bash
# Teszteld manuálisan a kulcsokat
# Google API teszt
curl "https://www.googleapis.com/customsearch/v1?key=YOUR_KEY&cx=YOUR_CX&q=test"

# Bing API teszt
curl -H "Ocp-Apim-Subscription-Key: YOUR_KEY" "https://api.bing.microsoft.com/v7.0/search?q=test"
```

---

## 📊 8. Integráció Ellenőrzése Kódból

### Fact-checking service ellenőrzése

```bash
docker compose exec backend python << 'PYEOF'
from src.services.factcheck.factcheck_service import FactCheckService
import inspect

service = FactCheckService()
source_code = inspect.getsource(service.check_claim)

# Ellenőrizd, hogy használja-e a search service-eket
uses_google = 'GoogleSearchService' in source_code or 'google_search' in source_code.lower()
uses_bing = 'BingSearchService' in source_code or 'bing_search' in source_code.lower()

print(f"Fact-checking service Google Search integráció: {'✓' if uses_google else '✗'}")
print(f"Fact-checking service Bing Search integráció: {'✓' if uses_bing else '✗'}")

# Tesztelj egy fact-checket
if uses_google or uses_bing:
    print("\nFact-check teszt futtatása...")
    try:
        result = service.check_claim("Test claim", include_external=True)
        external_sources = result.get('external_sources', [])
        print(f"External sources found: {len(external_sources)}")
        if external_sources:
            print("✓ External sources integration works!")
        else:
            print("⚠ External sources empty (may be due to API keys or no results)")
    except Exception as e:
        print(f"✗ Fact-check error: {e}")
PYEOF
```

---

## 🎯 Gyors Ellenőrző Lista

- [ ] `.env` fájlban vannak-e a `GOOGLE_SEARCH_API_KEY` és `GOOGLE_SEARCH_ENGINE_ID` változók?
- [ ] A konténer környezeti változói tartalmaznak-e értékeket?
- [ ] `GoogleSearchService.is_configured()` visszaadja-e `True`-t?
- [ ] `BingSearchService.is_configured()` visszaadja-e `True`-t?
- [ ] Teszt keresés működik-e?
- [ ] Fact-checking `external_sources` mező tartalmaz-e eredményeket?

---

**Hasznos linkek:**
- [API_KEYS_SETUP.md](./API_KEYS_SETUP.md) - API kulcsok beállítása
- [LINUX_DEPLOYMENT.md](./LINUX_DEPLOYMENT.md) - Deployment útmutató

