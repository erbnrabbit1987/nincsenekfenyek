# 🔑 API Kulcsok Beállítása - Deployment Útmutató

Ez az útmutató segít az API kulcsok beszerzésében és beállításában a deployment előtt.

---

## 📋 Szükséges API Kulcsok

### 1. Google Custom Search API (Opcionális, de ajánlott)

**Miért kell:**
- Fact-checking referencia kereséshez
- Állítások verifikációjához
- Külső források automatikus keresése

**Szükséges kulcsok:**
- `GOOGLE_SEARCH_API_KEY` - Google API Key
- `GOOGLE_SEARCH_ENGINE_ID` - Custom Search Engine ID (CX)

**Beszerzés lépései:**

1. **Google Cloud Console beállítása:**
   - Menj a [Google Cloud Console](https://console.cloud.google.com/)
   - Hozz létre egy új projektet vagy válassz egy meglévőt
   - Engedélyezd a "Custom Search API"-t

2. **API Key létrehozása:**
   - Navigálj: **APIs & Services** → **Credentials**
   - Kattints: **Create Credentials** → **API Key**
   - Másold ki a generált API Key-t → Ez lesz a `GOOGLE_SEARCH_API_KEY`

3. **Custom Search Engine létrehozása:**
   - Menj a [Google Custom Search](https://programmablesearchengine.google.com/) oldalra
   - Kattints: **Add** vagy **Create a custom search engine**
   - Állítsd be:
     - **Sites to search:** `*` (minden weboldal) vagy specifikus oldalak
     - **Name:** Nincsenek Fények! Search
   - Kattints: **Create**
   - Másold ki a **Search engine ID**-t → Ez lesz a `GOOGLE_SEARCH_ENGINE_ID`

4. **API Key korlátozások (ajánlott):**
   - **Application restrictions:** IP address (ha fix IP-d van) vagy None
   - **API restrictions:** Csak "Custom Search API" engedélyezése

**Költség:**
- Ingyenes: 100 keresés/nap
- Fizetős: $5 per 1000 keresés (az első 100 után)

**Környezeti változók:**
```bash
GOOGLE_SEARCH_API_KEY=your_api_key_here
GOOGLE_SEARCH_ENGINE_ID=your_search_engine_id_here
```

---

### 2. Bing Web Search API (Opcionális, alternatíva)

**Miért kell:**
- Alternatív keresőmotor Google mellett
- További referencia források kereséséhez
- Jobb lefedettség fact-checkinghez

**Szükséges kulcs:**
- `BING_SEARCH_API_KEY` - Bing API Subscription Key

**Beszerzés lépései:**

1. **Azure Portal beállítása:**
   - Menj az [Azure Portal](https://portal.azure.com/)
   - Regisztrálj vagy jelentkezz be

2. **Bing Search v7 erőforrás létrehozása:**
   - Kattints: **Create a resource**
   - Keress rá: "Bing Search v7"
   - Válaszd ki: **Bing Search v7**
   - Kattints: **Create**
   - Töltsd ki:
     - **Subscription:** Válassz egy subscription-t
     - **Resource group:** Hozz létre vagy válassz egyet
     - **Name:** pl. `nincsenekfenyek-bing-search`
     - **Pricing tier:** F1 (Free tier) vagy S1 (Standard)
   - Kattints: **Review + create** → **Create**

3. **API Key lekérése:**
   - Navigálj az erőforráshoz
   - Menj: **Keys and Endpoint**
   - Másold ki az **Key 1** értékét → Ez lesz a `BING_SEARCH_API_KEY`

**Költség:**
- Ingyenes: 1000 keresés/hó
- Fizetős: $4 per 1000 keresés (az első 1000 után)

**Környezeti változó:**
```bash
BING_SEARCH_API_KEY=your_bing_api_key_here
```

---

## 🔧 Beállítás Deployment Előtt

### 1. Interaktív Setup Script Használata

A legegyszerűbb módszer az interaktív setup script használata:

```bash
cd /opt/nincsenekfenyek/nincsenekfenyek
./scripts/interactive-env-setup.sh
```

A script kérni fogja az API kulcsokat (opcionálisan).

### 2. Manuális .env Fájl Létrehozása

Ha manuálisan szeretnéd beállítani:

```bash
cd /opt/nincsenekfenyek/nincsenekfenyek

# Másold a .env.example fájlt
cp .env.example .env

# Szerkeszd a .env fájlt
nano .env
# vagy
vim .env
```

**Hozzáadandó sorok a .env fájlhoz:**
```bash
# Search API Keys (Opcionális)
GOOGLE_SEARCH_API_KEY=your_google_api_key_here
GOOGLE_SEARCH_ENGINE_ID=your_google_search_engine_id_here
BING_SEARCH_API_KEY=your_bing_api_key_here
```

### 3. Környezeti Változók Ellenőrzése

Ellenőrizd, hogy a kulcsok be vannak-e állítva:

```bash
# Docker konténerben
docker compose exec backend env | grep -E "GOOGLE|BING"

# Vagy lokálisan
grep -E "GOOGLE|BING" .env
```

---

## ✅ Deployment Lépések

### 1. Előfeltételek Ellenőrzése

```bash
# Docker telepítve?
docker --version
docker compose version

# Git repository klónozva?
cd /opt/nincsenekfenyek/nincsenekfenyek
git status
```

### 2. .env Fájl Beállítása

```bash
# Interaktív setup
./scripts/interactive-env-setup.sh

# VAGY manuálisan szerkeszd a .env fájlt
nano .env
```

### 3. Deployment Futtatása

```bash
# Teljes deployment
./scripts/deploy.sh

# Vagy csak build és start
docker compose build
docker compose up -d
```

### 4. Ellenőrzés

```bash
# Szolgáltatások státusza
docker compose ps

# Backend logok
docker compose logs backend

# Health check
curl http://localhost:8095/health

# API dokumentáció
curl http://localhost:8095/docs
```

---

## 🧪 API Kulcsok Tesztelése

### Google Search API Teszt

```bash
# Python shell-ben (backend konténerben)
docker compose exec backend python

>>> import os
>>> from src.services.search import GoogleSearchService
>>> service = GoogleSearchService()
>>> print(service.is_configured())  # True kell legyen
>>> results = service.search("Magyarország", num_results=3)
>>> print(len(results))  # 3 kell legyen
```

### Bing Search API Teszt

```bash
# Python shell-ben (backend konténerben)
docker compose exec backend python

>>> import os
>>> from src.services.search import BingSearchService
>>> service = BingSearchService()
>>> print(service.is_configured())  # True kell legyen
>>> results = service.search("Hungary", num_results=3)
>>> print(len(results))  # 3 kell legyen
```

---

## ⚠️ Fontos Megjegyzések

### API Kulcsok Biztonsága

1. **Soha ne commitold az API kulcsokat Git-be!**
   - A `.env` fájl már benne van a `.gitignore`-ban
   - Ellenőrizd: `git check-ignore .env`

2. **Production környezetben:**
   - Használj környezeti változókat
   - Vagy secrets management rendszert (pl. Docker secrets, Kubernetes secrets)
   - Ne hardcode-old kulcsokat a kódban

3. **API Key korlátozások:**
   - Állíts be IP korlátozásokat, ha lehet
   - Korlátozd csak a szükséges API-kra
   - Figyelj a használati limitre

### Opcionális Kulcsok

**Fontos:** Az API kulcsok opcionálisak! A rendszer működik nélkülük is:
- ✅ Fact-checking működik (korlátozottan, csak belső forrásokkal)
- ✅ Collection működik (Facebook, MTI, Magyar Közlöny, RSS)
- ✅ Statistics működik (EUROSTAT, KSH)
- ❌ Külső források automatikus keresése nem működik (Google/Bing nélkül)

**Ajánlás:**
- Minimum: Google Search API (ingyenes 100 keresés/nap)
- Opcionális: Bing Search API (ingyenes 1000 keresés/hó)

---

## 📊 API Kulcsok Prioritása

### Magas prioritás (ajánlott):
1. **Google Search API** - Fact-checkinghez legfontosabb
   - Ingyenes: 100 keresés/nap
   - Könnyen beállítható
   - Jó dokumentáció

### Közepes prioritás (opcionális):
2. **Bing Search API** - Alternatív forrás
   - Ingyenes: 1000 keresés/hó
   - Jobb lefedettség
   - Fallback Google mellett

### Alacsony prioritás (nem szükséges most):
- Twitter API (még nincs implementálva)
- Egyéb külső API-k

---

## 🚀 Gyors Deployment (API kulcsok nélkül)

Ha most azonnal deployolni szeretnél API kulcsok nélkül:

```bash
cd /opt/nincsenekfenyek/nincsenekfenyek

# .env fájl létrehozása (API kulcsok nélkül)
./scripts/interactive-env-setup.sh
# Válaszd a "3) Kihagyás" opciót a Search API beállításnál

# Deployment
./scripts/deploy.sh
```

A rendszer működni fog, csak a külső források automatikus keresése nem lesz elérhető.

---

## 📝 Ellenőrző Lista Deployment Előtt

- [ ] Docker telepítve és fut
- [ ] Git repository klónozva
- [ ] `.env` fájl létrehozva
- [ ] Alapvető beállítások (adatbázis, Redis) beállítva
- [ ] Google Search API kulcs (opcionális, de ajánlott)
- [ ] Bing Search API kulcs (opcionális)
- [ ] API kulcsok tesztelve
- [ ] Deployment script futtatva
- [ ] Szolgáltatások futnak (`docker compose ps`)
- [ ] Health check sikeres (`curl http://localhost:8095/health`)

---

## 🔗 Hasznos Linkek

- [Google Custom Search API Dokumentáció](https://developers.google.com/custom-search/v1/overview)
- [Google Cloud Console](https://console.cloud.google.com/)
- [Google Custom Search Engine](https://programmablesearchengine.google.com/)
- [Bing Search API Dokumentáció](https://learn.microsoft.com/en-us/bing/search-apis/bing-web-search/overview)
- [Azure Portal](https://portal.azure.com/)

---

**Kérdésed van?** Nézd meg a `docs/LINUX_DEPLOYMENT.md` fájlt a részletes deployment útmutatóért.

