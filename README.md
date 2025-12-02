# Nincsenek Fények!

> Fact-checking és információs monitoring alkalmazás

## Projekt Leírás

A **Nincsenek Fények!** egy komplex fact-checking és monitoring alkalmazás, amely automatikusan figyeli különböző online forrásokat (Facebook profilok, híroldalak, statisztikák), összeveti az információkat, és tényellenőrzést végez. Az alkalmazás célja, hogy segítsen könnyen navigálni az információáradatban, és gyorsan megtalálni a releváns tényeket hivatkozásokkal.

## Fő Funkciók

- 📱 **Facebook Profil Monitoring**: Real-time figyelés és posztgyűjtés megadott Facebook profilokról
- 📰 **Híroldal Források**: Automatikus cikkgyűjtés különböző híroldalakról
- 📊 **Statisztikai Integráció**: EUROSTAT és más statisztikai portálok integrálása
- ✅ **Automatikus Fact-checking**: Állítások ellenőrzése és hivatkozások keresése
- 🔍 **Tényalapú Keresés**: Gyors keresés a rengeteg információ között
- 📈 **Összefoglalók**: Automatikus jelentések és összefoglalók generálása
- ⚠️ **Eltérés Detektálás**: Azonosítás, ha ugyanaz az információ eltérő forrásokban

## Tech Stack

### Backend
- **Python 3.11+**
- **FastAPI** - Modern, async web framework
- **MongoDB** - Fő adatbázis (kezdetben)
- **PostgreSQL** - Előkészítve (későbbi migráció)
- **Redis** - Cache és message queue
- **Celery** - Background job processing

### Frontend
- **React 18+** (tervezés alatt)
- **TypeScript** (tervezés alatt)

### DevOps
- **Docker** + **Docker Compose** - Containerizáció
- Később: **Kubernetes** - Skálázhatóság

## Gyors Kezdés

### Előfeltételek

- Docker és Docker Compose telepítve
- Git

### Telepítés és Futtatás

#### Gyors Deployment (Ajánlott)

1. **Repository klónozása:**
```bash
git clone git@github.com:erbnrabbit1987/nincsenekfenyek.git
cd nincsenekfenyek
```

2. **Deployment script futtatása:**
```bash
./scripts/deploy.sh -b
```

Ez automatikusan:
- Ellenőrzi az előfeltételeket (Docker, Docker Compose)
- Létrehozza a `.env` fájlt ha hiányzik
- Build-eli a Docker image-eket
- Indítja az összes szolgáltatást

#### Manuális Telepítés

1. **Környezeti változók beállítása:**
```bash
cp .env.example .env
# Szerkeszd a .env fájlt a szükséges értékekkel
```

2. **Docker konténerek indítása:**
```bash
docker-compose up -d
```

#### Deployment

A projekt Docker és Docker Compose segítségével containerizálva van. A deployment scriptek és konfigurációs fájlok lokálisan érhetők el.

A rendszer a következő szolgáltatásokat tartalmazza:
- Backend API (port 8000)
- MongoDB (port 27017)
- PostgreSQL (port 5432)
- Redis (port 6379)
- Celery Worker
- Celery Beat

4. **API elérése:**
- API: http://localhost:8000
- API Dokumentáció: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### Fejlesztés

A fejlesztési dokumentáció és részletek a [DEVELOPMENT.md](./docs/DEVELOPMENT.md) fájlban találhatók.

> **Megjegyzés:** A forráskód és fejlesztési scriptek jelenleg csak lokálisan érhetők el.

## Projekt Struktúra

```
nincsenekfenyek/
├── docs/                  # Dokumentáció
│   ├── USE_CASES.md      # Use case dokumentáció
│   ├── DEVELOPMENT.md    # Fejlesztési dokumentáció
│   ├── ARCHITECTURE.md   # Architektúra dokumentáció
│   ├── TECH_STACK.md     # Tech stack dokumentáció
│   ├── QUICKSTART.md     # Gyors kezdés
│   ├── TESTING.md        # Tesztelési dokumentáció
│   ├── TEST_CASES_ISSUES.md  # Tesztesetek issue formátumban
│   ├── DEPLOYMENT.md     # Linux szerver deployment útmutató
│   └── DEPLOYMENT_SUMMARY.md  # Deployment gyors összefoglaló
├── devel/                 # Development repository (submodule)
│   └── (forráskód és futtatási fájlok)
├── .github/               # GitHub konfiguráció
│   └── ISSUE_TEMPLATE/   # Issue template-ek
├── CHANGELOG.md           # Verziók és változások
├── SECURITY.md            # Biztonsági útmutató
├── GIT_SETUP.md           # Git beállítási útmutató
├── GITHUB_SSH_SETUP.md    # GitHub SSH beállítás
└── README.md              # Ez a fájl
```

> **Megjegyzés:** A forráskód egy külön `devel` repository-ban (vagy submodule-ként) található. A dokumentáció itt, a main repository-ban van.

## Hasznos Linkek

- [Use Cases](./USE_CASES.md) - Részletes use case dokumentáció
- [Development Guide](./docs/DEVELOPMENT.md) - Fejlesztési útmutató
- [Architecture](./docs/ARCHITECTURE.md) - Rendszerarchitektúra
- [Tech Stack](./docs/TECH_STACK.md) - Technológiai részletek
- [Quick Start](./docs/QUICKSTART.md) - Gyors kezdés útmutató
- [Deployment Guide](./docs/DEPLOYMENT.md) - Linux szerver deployment útmutató
- [Deployment Summary](./docs/DEPLOYMENT_SUMMARY.md) - Deployment gyors összefoglaló
- [Docker Guide](./DOCKER.md) - Docker használati útmutató
- [Changelog](./CHANGELOG.md) - Verziók és változások

## API Endpoints

### Források
- `GET /api/sources` - Források listája
- `POST /api/sources` - Új forrás hozzáadása
- `GET /api/sources/:id` - Forrás részletei
- `DELETE /api/sources/:id` - Forrás törlése

### Forráscsoportok
- `GET /api/sources/groups` - Csoportok listája
- `POST /api/sources/groups` - Új csoport
- `GET /api/sources/groups/:id` - Csoport részletei

Teljes API dokumentáció: http://localhost:8000/docs

## Státusz

🚧 **Fejlesztés alatt** - Projekt kezdeti fázisban

### Jelenlegi Funkciók
- ✅ Alap projekt struktúra
- ✅ Docker és Docker Compose setup
- ✅ FastAPI backend alapok
- ✅ MongoDB + PostgreSQL előkészítés
- ✅ Celery background jobs setup
- ✅ Forráskezelés API (alapok)

### Következő Lépések
- ⏳ React frontend setup
- ⏳ Facebook scraping implementáció
- ⏳ Fact-checking service
- ⏳ Keresés és szűrés
- ⏳ Dashboard UI

## Közreműködés

Lásd [DEVELOPMENT.md](./docs/DEVELOPMENT.md) a fejlesztési útmutatóért.

## Licenc

[Majd később meghatározandó]
