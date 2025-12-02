# 🧪 Nincsenek Fények! - Tesztelési Dokumentáció

**Verzió:** 1.0  
**Dátum:** 2024-12-02  
**Szerző:** Fejlesztői csapat  
**Szabvány:** ISTQB Foundation Level

---

## 1. Dokumentum Információk

### 1.1. Dokumentum Célja

Ez a dokumentum a **Nincsenek Fények!** alkalmazás tesztelési tervét és teszteseteit tartalmazza ISTQB Foundation Level irányelvek szerint. A dokumentum célja, hogy:

- Rendszerezett tesztelési folyamatot biztosítson
- Minden funkcióhoz teszteseteket definiáljon
- Elvárható eredményeket és visszajelzéseket dokumentáljon
- Tesztelési lefedettséget biztosítson

### 1.2. Alkalmazás Áttekintése

**Nincsenek Fények!** egy fact-checking és információs monitoring alkalmazás, amely:

- Real-time figyeli Facebook profilokat és gyűjti a posztokat
- Összeveti információkat különböző forrásokból (híroldalak, statisztikák)
- Automatikusan fact-checkel és keres eltéréseket
- Generál összefoglalókat és jelentéseket
- Segít gyorsan megtalálni a releváns tényeket hivatkozásokkal

### 1.3. Tesztelési Szabványok

- **ISTQB Foundation Level**: Tesztelési alapelvek és terminológia
- **Black Box Testing**: Funkcionális tesztelés specifikáció alapján
- **Integration Testing**: Komponensek közötti integráció tesztelése
- **System Testing**: Teljes rendszer tesztelése
- **User Acceptance Testing (UAT)**: Felhasználói elfogadási tesztelés

---

## 2. Tesztelési Stratégia

### 2.1. Tesztelési Szintek

1. **Unit Tesztek** (Fejlesztői szint)
   - Backend Python függvények és osztályok
   - API endpoint validációk
   - Model validációk
   - Service réteg logika

2. **Integration Tesztek**
   - API endpoint-ok
   - Adatbázis műveletek (MongoDB, PostgreSQL)
   - Redis cache és queue
   - External API integrációk (Facebook, EUROSTAT)
   - Celery background job-ok

3. **System Tesztek**
   - Teljes felhasználói folyamatok
   - Forráskezelés és monitoring
   - Fact-checking folyamatok
   - Keresés és szűrés

4. **User Acceptance Tesztek**
   - Valós felhasználói forgatókönyvek
   - Teljesítmény tesztelés
   - Biztonsági tesztelés

### 2.2. Tesztelési Típusok

- **Funkcionális Tesztelés**: Minden funkció helyes működése
- **Nem-funkcionális Tesztelés**: Teljesítmény, biztonság, használhatóság
- **Regressziós Tesztelés**: Új funkciók után régi funkciók működése
- **Smoke Tesztelés**: Kritikus funkciók gyors ellenőrzése

### 2.3. Tesztelési Környezet

- **Fejlesztői környezet**: Lokális Docker Compose
- **Tesztelési környezet**: Szerveren futó tesztelési példány
- **Éles környezet**: Production deployment előtti végső tesztelés

---

## 3. Tesztesetek Katalógus

### 3.1. Teszteset Azonosítás

Minden teszteset az alábbi formátumban van azonosítva:

**TC-XXX-YYY-ZZZ**
- **XXX**: Modul azonosító (SOURCE, COLLECT, FACTCHECK, SEARCH, stb.)
- **YYY**: Funkció azonosító
- **ZZZ**: Teszteset sorszáma

### 3.2. Teszteset Prioritás

- **P1 - Kritikus**: Alkalmazás alapvető működése, biztonság
- **P2 - Magas**: Főbb funkciók, felhasználói folyamatok
- **P3 - Közepes**: Kiegészítő funkciók, edge case-ek
- **P4 - Alacsony**: UI/UX finomhangolások, optimalizációk

### 3.3. Teszteset Státusz

- **Draft**: Vázlat, még nem tesztelve
- **Ready**: Készen áll a tesztelésre
- **In Progress**: Jelenleg tesztelés alatt
- **Passed**: Sikeresen lefutott
- **Failed**: Sikertelen, hiba van
- **Blocked**: Blokkolva, nem tesztelhető
- **Skipped**: Kihagyva (nem releváns)

---

## 4. Modulok Szerinti Tesztesetek

### 4.1. Forráskezelés (SOURCE)

#### TC-SOURCE-001: Forráscsoport Létrehozása

**Prioritás:** P1  
**Típus:** Funkcionális  
**Szint:** System

**Előfeltételek:**
- Felhasználó be van jelentkezve
- API elérhető

**Tesztlépések:**
1. API hívás: `POST /api/sources/groups`
2. Request body:
   ```json
   {
     "name": "Politikusok",
     "description": "Politikusok Facebook profiljai",
     "user_id": "user123"
   }
   ```
3. Ellenőrizd a választ

**Elvárt Eredmény:**
- HTTP 201 Created válasz
- Response tartalmazza a létrehozott forráscsoport adatait
- Forráscsoport ID generálva
- Created_at timestamp be van állítva

**Visszajelzés Formátum:**
```
Teszteset ID: TC-SOURCE-001
Tesztelő: [Név]
Dátum: [YYYY-MM-DD]
Eredmény: PASSED / FAILED
Megjegyzés: [Ha FAILED, részletes leírás a hibáról]
```

---

#### TC-SOURCE-002: Facebook Profil Forrás Hozzáadása

**Prioritás:** P1  
**Típus:** Funkcionális  
**Szint:** System

**Előfeltételek:**
- Felhasználó be van jelentkezve
- Van legalább egy forráscsoport

**Tesztlépések:**
1. API hívás: `POST /api/sources`
2. Request body:
   ```json
   {
     "source_type": "facebook",
     "identifier": "username_or_url",
     "source_group_id": "group_id",
     "config": {}
   }
   ```
3. Ellenőrizd a választ

**Elvárt Eredmény:**
- HTTP 201 Created válasz
- Source létrehozva típus: "facebook"
- Source aktív (is_active: true)
- Config beállítások mentve

---

#### TC-SOURCE-003: Híroldal Forrás Hozzáadása

**Prioritás:** P2  
**Típus:** Funkcionális  
**Szint:** System

**Előfeltételek:**
- Felhasználó be van jelentkezve
- Van forráscsoport

**Tesztlépések:**
1. API hívás: `POST /api/sources`
2. Request body:
   ```json
   {
     "source_type": "news",
     "identifier": "https://example.com/rss",
     "source_group_id": "group_id",
     "config": {
       "feed_type": "rss",
       "update_interval": 3600
     }
   }
   ```
3. Ellenőrizd a választ

**Elvárt Eredmény:**
- HTTP 201 Created válasz
- Source létrehozva típus: "news"
- Config beállítások mentve
- Source aktív

---

#### TC-SOURCE-004: Statisztikai Forrás Hozzáadása (EUROSTAT)

**Prioritás:** P2  
**Típus:** Funkcionális  
**Szint:** System

**Előfeltételek:**
- Felhasználó be van jelentkezve
- Van forráscsoport
- EUROSTAT API elérhető

**Tesztlépések:**
1. API hívás: `POST /api/sources`
2. Request body:
   ```json
   {
     "source_type": "statistics",
     "identifier": "eurostat",
     "source_group_id": "group_id",
     "config": {
       "provider": "eurostat",
       "datasets": ["dataset1", "dataset2"]
     }
   }
   ```
3. Ellenőrizd a választ

**Elvárt Eredmény:**
- HTTP 201 Created válasz
- Source létrehozva típus: "statistics"
- Config tartalmazza a provider-t és dataset-eket
- Source aktív

---

#### TC-SOURCE-005: Forrás Törlése

**Prioritás:** P2  
**Típus:** Funkcionális  
**Szint:** System

**Előfeltételek:**
- Van létrehozott forrás

**Tesztlépések:**
1. API hívás: `DELETE /api/sources/{source_id}`
2. Ellenőrizd a választ
3. Ellenőrizd, hogy törölve lett-e (GET request)

**Elvárt Eredmény:**
- HTTP 204 No Content válasz
- GET request 404-et ad vissza
- Forrás törölve az adatbázisból

---

### 4.2. Adatgyűjtés (COLLECT)

#### TC-COLLECT-001: Facebook Post Gyűjtés (Scraping)

**Prioritás:** P1  
**Típus:** Integration  
**Szint:** System

**Előfeltételek:**
- Facebook forrás hozzáadva
- Source aktív
- Celery worker fut

**Tesztlépések:**
1. Várj a scheduled task futására
2. Ellenőrizd az adatbázist
3. Nézd meg a Celery logokat

**Elvárt Eredmény:**
- Új posztok mentve az adatbázisba
- Post objektumok tartalmaznak: content, posted_at, metadata
- Timestamp-ek helyesek
- Celery logokban sikeres gyűjtés

---

#### TC-COLLECT-002: RSS Feed Olvasás

**Prioritás:** P1  
**Típus:** Integration  
**Szint:** System

**Előfeltételek:**
- Híroldal forrás hozzáadva (RSS feed)
- Source aktív
- Celery worker fut

**Tesztlépések:**
1. Várj a scheduled task futására
2. Ellenőrizd az adatbázist
3. Nézd meg a Celery logokat

**Elvárt Eredmény:**
- Új cikkek mentve az adatbázisba
- Cikkek tartalmaznak: cím, tartalom, link, published_at
- RSS feed helyesen parse-olva
- Duplikációk elkerülve

---

#### TC-COLLECT-003: EUROSTAT Adat Frissítés

**Prioritás:** P2  
**Típus:** Integration  
**Szint:** System

**Előfeltételek:**
- EUROSTAT forrás hozzáadva
- API kapcsolat működik
- Celery worker fut

**Tesztlépések:**
1. Várj a scheduled task futására
2. Ellenőrizd az adatbázist
3. Nézd meg a Celery logokat

**Elvárt Eredmény:**
- Statisztikai adatok frissítve
- Adatok normalizálva és tárolva
- Timestamp-ek helyesek
- API hívások sikeresek

---

### 4.3. Fact-checking (FACTCHECK)

#### TC-FACTCHECK-001: Automatikus Fact-checking Indítása

**Prioritás:** P1  
**Típus:** Integration  
**Szint:** System

**Előfeltételek:**
- Új Facebook post érkezett
- Fact-check service elérhető

**Tesztlépések:**
1. Új post érkezik
2. Figyeld a Celery task folyamatot
3. Ellenőrizd a fact-check eredményeket

**Elvárt Eredmény:**
- Fact-check task automatikusan elindul
- Állítások azonosítva (NLP)
- Kapcsolódó források keresve
- Fact-check jelentés generálva
- Eredmény mentve az adatbázisba

---

#### TC-FACTCHECK-002: Hivatkozások Keresése

**Prioritás:** P1  
**Típus:** Integration  
**Szint:** System

**Előfeltételek:**
- Post tartalmaz állítást
- Van kapcsolódó forrás az adatbázisban

**Tesztlépések:**
1. Fact-check folyamat elindítása
2. Várj a hivatkozás keresésre
3. Ellenőrizd az eredményeket

**Elvárt Eredmény:**
- Kapcsolódó cikkek/hírek találva
- Statisztikai adatok találva
- Hivatkozások relevancia szerint rangsorolva
- Hivatkozások mentve a fact-check objektumhoz

---

#### TC-FACTCHECK-003: Eltérések Azonosítása

**Prioritás:** P1  
**Típus:** Integration  
**Szint:** System

**Előfeltételek:**
- Ugyanaz az információ több forrásban
- Van eltérés a források között

**Tesztlépések:**
1. Fact-check folyamat elindítása
2. Források összehasonlítása
3. Eltérések detektálása

**Elvárt Eredmény:**
- Eltérések azonosítva
- Eltérések kategorizálva (súlyos, kisebb)
- Eltérés részletek mentve
- Discrepancy objektum létrehozva

---

### 4.4. Keresés és Szűrés (SEARCH)

#### TC-SEARCH-001: Tényalapú Keresés

**Prioritás:** P1  
**Típus:** Funkcionális  
**Szint:** System

**Előfeltételek:**
- Van legalább egy fact-checked post
- API elérhető

**Tesztlépések:**
1. API hívás: `GET /api/search?q=keresőkifejezés`
2. Ellenőrizd a választ

**Elvárt Eredmény:**
- HTTP 200 OK válasz
- Releváns eredmények visszaadva
- Eredmények relevancia szerint rangsorolva
- Eredmények tartalmaznak: post, fact-check, references

---

#### TC-SEARCH-002: Forrás szerinti Szűrés

**Prioritás:** P2  
**Típus:** Funkcionális  
**Szint:** System

**Előfeltételek:**
- Van több forrás
- Van post több forrástól

**Tesztlépések:**
1. API hívás: `GET /api/search?q=...&source_id=source123`
2. Ellenőrizd a választ

**Elvárt Eredmény:**
- HTTP 200 OK válasz
- Csak a kiválasztott forrásból származó eredmények
- Más források kiszűrve

---

#### TC-SEARCH-003: Időszak szerinti Szűrés

**Prioritás:** P2  
**Típus:** Funkcionális  
**Szint:** System

**Előfeltételek:**
- Van post különböző dátumokkal

**Tesztlépések:**
1. API hívás: `GET /api/search?q=...&start_date=2024-01-01&end_date=2024-12-31`
2. Ellenőrizd a választ

**Elvárt Eredmény:**
- HTTP 200 OK válasz
- Csak a dátumtartományba eső eredmények
- Dátum szűrés helyesen működik

---

### 4.5. Összefoglaló és Jelentés (SUMMARY)

#### TC-SUMMARY-001: Automatikus Összefoglaló Generálás

**Prioritás:** P2  
**Típus:** Integration  
**Szint:** System

**Előfeltételek:**
- Van post egy témakörben
- Fact-check eredmények léteznek

**Tesztlépések:**
1. API hívás: `POST /api/summaries`
2. Request body: téma vagy időszak
3. Várj a generálásra
4. Ellenőrizd az eredményt

**Elvárt Eredmény:**
- Összefoglaló generálva
- Kapcsolódó állítások csoportosítva
- Fact-check eredmények összefoglalva
- Eltérések kiemelve
- Strukturált dokumentum készült

---

### 4.6. API és Backend (API)

#### TC-API-001: Health Check Endpoint

**Prioritás:** P1  
**Típus:** Funkcionális  
**Szint:** Integration

**Előfeltételek:**
- Backend fut

**Tesztlépések:**
1. API hívás: `GET /health`
2. Ellenőrizd a választ

**Elvárt Eredmény:**
- HTTP 200 OK válasz
- Response: `{"status": "healthy"}`

---

#### TC-API-002: API Dokumentáció Elérhetősége

**Prioritás:** P2  
**Típus:** Funkcionális  
**Szint:** System

**Előfeltételek:**
- Backend fut

**Tesztlépések:**
1. Nyisd meg: `http://localhost:8000/docs`
2. Ellenőrizd a Swagger UI-t

**Elvárt Eredmény:**
- Swagger UI betöltődik
- Minden endpoint dokumentálva
- Try it out funkció működik

---

### 4.7. Biztonsági Tesztek (SEC)

#### TC-SEC-001: API Authentication

**Prioritás:** P1  
**Típus:** Biztonsági  
**Szint:** System

**Előfeltételek:**
- Authentication be van állítva

**Tesztlépések:**
1. API hívás authentication nélkül
2. Ellenőrizd a választ

**Elvárt Eredmény:**
- HTTP 401 Unauthorized válasz
- Hibaüzenet: "Authentication required"

---

#### TC-SEC-002: Input Validation

**Prioritás:** P1  
**Típus:** Biztonsági  
**Szint:** System

**Előfeltételek:**
- API endpoint elérhető

**Tesztlépések:**
1. API hívás rossz formátumú adatokkal
2. Ellenőrizd a választ

**Elvárt Eredmény:**
- HTTP 422 Unprocessable Entity válasz
- Validation error részletek
- Biztonságos hibaüzenet (nem ad ki szenzitív információt)

---

### 4.8. Teljesítmény Tesztek (PERF)

#### TC-PERF-001: API Response Time

**Prioritás:** P2  
**Típus:** Teljesítmény  
**Szint:** System

**Előfeltételek:**
- API elérhető

**Tesztlépések:**
1. Mérj response time-t több endpointon
2. Ellenőrizd a teljesítményt

**Elvárt Eredmény:**
- Response time < 500ms (egyszerű query-k)
- Response time < 2s (komplex query-k)
- Nincs timeout

---

## 5. Tesztelési Folyamat

### 5.1. Tesztelési Fázisok

1. **Tesztelési Terv Készítése**
   - Tesztesetek definiálása
   - Tesztelési környezet előkészítése
   - Tesztelési adatok előkészítése

2. **Tesztelési Végrehajtás**
   - Tesztesetek futtatása
   - Eredmények dokumentálása
   - Hibák jelentése

3. **Hibakezelés**
   - Bug report készítése
   - Fejlesztői visszajelzés
   - Újra tesztelés

4. **Tesztelési Összefoglaló**
   - Tesztelési jelentés készítése
   - Lefedettség elemzése
   - Javaslatok

### 5.2. Bug Report Formátum

```markdown
**Bug ID:** BUG-XXX
**Teszteset:** TC-XXX-YYY-ZZZ
**Prioritás:** P1/P2/P3/P4
**Súlyosság:** Critical/High/Medium/Low
**Leírás:** [Részletes leírás]
**Lépések a reprodukcióhoz:**
1. ...
2. ...
**Elvárt Eredmény:** ...
**Tényleges Eredmény:** ...
**Környezet:** [Backend verzió, Docker, stb.]
**Logok:** [Ha szükséges]
```

### 5.3. Tesztelési Jelentés

Minden tesztelési ciklus után készül egy tesztelési jelentés, amely tartalmazza:

- Tesztelt funkciók listája
- Tesztesetek eredményei (Passed/Failed/Blocked/Skipped)
- Lefedettség százalék
- Talált hibák listája
- Javaslatok

---

## 6. Tesztelési Eszközök

### 6.1. Manuális Tesztelés

- **Böngészők**: Chrome, Firefox, Safari, Edge (frontend esetén)
- **API Testing**: Postman, Insomnia, curl
- **DevTools**: Console, Network, Application

### 6.2. Automatizált Tesztelés

- **Pytest**: Backend unit és integration tesztek
- **pytest-asyncio**: Async API tesztek
- **pytest-cov**: Code coverage
- **httpx**: HTTP client teszteléshez
- **Selenium/Playwright**: E2E teszteléshez (jövőbeli)

---

## 7. Függelékek

### 7.1. Tesztesetek Táblázat

| Teszteset ID | Név | Prioritás | Státusz | Tesztelő | Dátum |
|--------------|-----|-----------|---------|----------|-------|
| TC-SOURCE-001 | Forráscsoport Létrehozása | P1 | Ready | - | - |
| TC-SOURCE-002 | Facebook Profil Forrás Hozzáadása | P1 | Ready | - | - |
| ... | ... | ... | ... | ... | ... |

### 7.2. Hibák Táblázat

| Bug ID | Teszteset | Prioritás | Súlyosság | Státusz | Felelős |
|--------|-----------|-----------|-----------|---------|---------|
| BUG-001 | TC-XXX-YYY-ZZZ | P1 | Critical | Open | - |
| ... | ... | ... | ... | ... | ... |

---

## 8. Verzió Történet

| Verzió | Dátum | Szerző | Változások |
|--------|-------|--------|------------|
| 1.0 | 2024-12-02 | Fejlesztői csapat | Kezdeti verzió |

---

**Dokumentum Vég**

