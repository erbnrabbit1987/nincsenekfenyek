# TODO List - Nincsenek Fények!

> Fejlesztési feladatok és tervezett funkciók

---

## 🔄 Folyamatban lévő feladatok

Nincsenek jelenleg aktív fejlesztési feladatok.

---

## 📋 Tervezett fejlesztések

### 1. Keresőmotor Integrációk

#### Google Search API
- [ ] Google Custom Search API integráció
- [ ] API kulcs kezelés
- [ ] Keresési eredmények parsing
- [ ] Rate limiting kezelés
- [ ] Keresési eredmények cache-elése

**Fájlok:**
- `src/services/factcheck/search/google_search.py`
- `src/config/settings.py` (API key)

**Használat:**
- Fact-checking referencia kereséshez
- Állítások verifikációjához

---

#### Bing Search API
- [ ] Bing Web Search API integráció
- [ ] API kulcs kezelés
- [ ] Keresési eredmények parsing
- [ ] Rate limiting kezelés
- [ ] Alternatív keresőmotor Google mellett

**Fájlok:**
- `src/services/factcheck/search/bing_search.py`
- `src/config/settings.py` (API key)

---

### 2. Statisztikai API Integrációk

#### EUROSTAT API
- [ ] EUROSTAT SDMX API integráció
- [ ] Adatkészlet keresés
- [ ] Statisztikai adatok letöltése
- [ ] Adatok normalizálása és tárolása
- [ ] Időzített frissítés (Celery task)

**Fájlok:**
- `src/services/collection/statistics/eurostat.py`
- `src/services/collection/tasks.py` (Celery task)

**API dokumentáció:**
- https://ec.europa.eu/eurostat/web/json-and-unicode-web-services

---

#### KSH (Központi Statisztikai Hivatal) API
- [ ] KSH API integráció
- [ ] Adatkészlet keresés
- [ ] Statisztikai adatok letöltése
- [ ] Adatok normalizálása
- [ ] Magyar statisztikák tárolása

**Fájlok:**
- `src/services/collection/statistics/ksh.py`

**API dokumentáció:**
- https://www.ksh.hu/stadat_files/hun/hun/xls/hun/stadat_nyito.html

---

#### MTI (Magyar Távirati Iroda) Integráció
- [ ] MTI RSS feed integráció
- [ ] Hírek automatikus gyűjtése
- [ ] MTI API integráció (ha elérhető)
- [ ] Hírek kategorizálása
- [ ] Fact-checking forrásként való használat

**Fájlok:**
- `src/services/collection/news/mti.py`

**Források:**
- MTI RSS feed URL-ek
- MTI API dokumentáció (ha elérhető)

---

#### Magyar Közlöny Integráció
- [ ] Magyar Közlöny web scraping
- [ ] Hivatalos közlemények gyűjtése
- [ ] Dokumentumok letöltése
- [ ] Szövegek feldolgozása
- [ ] Hivatalos információk forrásként

**Fájlok:**
- `src/services/collection/official/magyar_kozlony.py`

**Forrás:**
- https://magyarkozlony.hu/

---

### 3. Twitter/X Integráció

#### Twitter/X API - Keresés
- [ ] Twitter API v2 integráció
- [ ] Tweet keresés kulcsszavak alapján
- [ ] Keresési eredmények feldolgozása
- [ ] Tweet metadata (timestamp, like-ok, retweetek)
- [ ] Rate limiting kezelés

**Fájlok:**
- `src/services/factcheck/search/twitter_search.py`
- `src/services/collection/twitter/twitter_scraper.py`

**API:**
- Twitter API v2 (Bearer token szükséges)

---

#### Twitter/X Profilfigyelés
- [ ] Twitter profil monitoring
- [ ] Új tweet-ek automatikus gyűjtése
- [ ] Profil információk tárolása
- [ ] Időzített profil ellenőrzés (Celery task)
- [ ] Duplikáció ellenőrzés

**Fájlok:**
- `src/services/collection/twitter/twitter_monitor.py`
- `src/services/collection/tasks.py` (Celery task)
- `src/models/mongodb_models.py` (Twitter source type hozzáadása)

**Módosítások:**
- `Source.SOURCE_TYPES` bővítése: `["facebook", "news", "statistics", "twitter"]`

---

### 4. RSS Feed Collection

#### RSS Feed Reader
- [ ] RSS feed parser implementáció
- [ ] Feed URL validáció
- [ ] Cikkek automatikus gyűjtése
- [ ] Feed frissítés detektálása
- [ ] Duplikáció ellenőrzés

**Fájlok:**
- `src/services/collection/news/rss_reader.py`
- `src/services/collection/tasks.py` (RSS collection task)

**Library:**
- `feedparser` Python library

**Funkciók:**
- RSS 2.0 támogatás
- Atom feed támogatás
- Feed metaadatok (title, description, link)
- Cikk tartalom és dátum
- Időzített frissítés (Celery Beat)

---

### 5. Fact-checking Oldalak Integráció

#### Fact-checking Portálok
- [ ] Fact-checking oldalak listázása
- [ ] Automatikus fact-check keresés
- [ ] Fact-check eredmények parsing
- [ ] Verdict kategóriák mapping
- [ ] Hivatkozások mentése

**Támogatott oldalak:**
- [ ] Lakmusz (lakmusz.hu)
- [ ] 444.hu fact-check
- [ ] Telex fact-check
- [ ] Reuters Fact Check
- [ ] AFP Fact Check
- [ ] PolitiFact

**Fájlok:**
- `src/services/factcheck/external/factcheck_sites.py`
- `src/services/factcheck/factcheck_service.py` (integráció)

**Módszer:**
- Web scraping vagy API (ha elérhető)
- Kulcsszó alapú keresés
- Verdict matching algoritmus

---

## 🛠️ Technikai Fejlesztések

### API Bővítések
- [ ] Twitter source management API endpoints
- [ ] Statistics API endpoints (EUROSTAT, KSH adatok)
- [ ] Search API endpoints (Google, Bing)
- [ ] Fact-check external sources API

### Adatbázis
- [ ] Twitter source type hozzáadása
- [ ] Statistics collection model
- [ ] External fact-check results model
- [ ] Search cache collection

### Infrastruktúra
- [ ] Redis cache bővítése
- [ ] Celery task prioritizálás
- [ ] Rate limiting middleware
- [ ] Monitoring és logging bővítése

---

## 📝 Dokumentáció

- [ ] Twitter integráció dokumentáció
- [ ] Statistics API használati útmutató
- [ ] RSS feed beállítási útmutató
- [ ] Fact-checking oldalak konfiguráció
- [ ] API endpoint dokumentáció bővítése

---

## 🧪 Tesztelés

- [ ] Twitter API mock tesztek
- [ ] Statistics API integration tesztek
- [ ] RSS feed parser tesztek
- [ ] Fact-checking oldalak scraping tesztek
- [ ] End-to-end tesztelés új funkciókkal

---

## 🔐 Biztonság

- [ ] API kulcsok kezelése (environment variables)
- [ ] Rate limiting minden külső API híváshoz
- [ ] Error handling és retry logic
- [ ] Sensitive data masking logokban

---

**Utolsó frissítés:** 2024. december 2.  
**Karbantartó:** Development Team


