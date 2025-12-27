# 🧪 Tesztesetek Git Issue Formátumban

Ez a dokumentum tartalmazza az összes tesztesetet Git issue formátumban. Minden issue létrehozható a GitHub issue tracker-ben.

---

## Issue Template

Minden issue az alábbi formátumban van:

```markdown
**Teszteset ID:** TC-XXX-YYY-ZZZ
**Prioritás:** P1/P2/P3/P4
**Típus:** Funkcionális/Integration/Biztonsági/Teljesítmény
**Szint:** Unit/Integration/System/UAT
**Címke:** `testing`, `test-case`, `[modul]`
```

---

## Issue-k Listája

### TC-SOURCE-001: Forráscsoport Létrehozása

**Prioritás:** P1  
**Típus:** Funkcionális  
**Szint:** System  
**Címkék:** `testing`, `test-case`, `source`

**Leírás:**
Teszteljük a forráscsoport létrehozását az API-n keresztül.

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

### TC-SOURCE-002: Facebook Profil Forrás Hozzáadása

**Prioritás:** P1  
**Típus:** Funkcionális  
**Szint:** System  
**Címkék:** `testing`, `test-case`, `source`, `facebook`

**Leírás:**
Teszteljük a Facebook profil forrás hozzáadását.

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

### TC-SOURCE-003: Híroldal Forrás Hozzáadása

**Prioritás:** P2  
**Típus:** Funkcionális  
**Szint:** System  
**Címkék:** `testing`, `test-case`, `source`, `news`

**Leírás:**
Teszteljük a híroldal forrás hozzáadását RSS feed-del.

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

### TC-COLLECT-001: Facebook Post Gyűjtés (Scraping)

**Prioritás:** P1  
**Típus:** Integration  
**Szint:** System  
**Címkék:** `testing`, `test-case`, `collection`, `facebook`

**Leírás:**
Teszteljük a Facebook posztok automatikus gyűjtését scraping-gel.

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

### TC-FACTCHECK-001: Automatikus Fact-checking Indítása

**Prioritás:** P1  
**Típus:** Integration  
**Szint:** System  
**Címkék:** `testing`, `test-case`, `factcheck`

**Leírás:**
Teszteljük az automatikus fact-checking elindítását új post érkezésekor.

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

### TC-SEARCH-001: Tényalapú Keresés

**Prioritás:** P1  
**Típus:** Funkcionális  
**Szint:** System  
**Címkék:** `testing`, `test-case`, `search`

**Leírás:**
Teszteljük a tényalapú keresés funkcionalitását.

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

*Ez a dokumentum folyamatosan bővül további tesztesetekkel...*




