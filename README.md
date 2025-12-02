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

1. **Repository klónozása:**
```bash
cd /Users/bazsika/Git/nincsenekfenyek
```

2. **Környezeti változók beállítása:**
```bash
cp .env.example .env
# Szerkeszd a .env fájlt a szükséges értékekkel
```

3. **Docker konténerek indítása:**
```bash
docker-compose up -d
```

Ez elindítja:
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

#### Backend fejlesztés

1. **Virtual environment létrehozása:**
```bash
python3.11 -m venv venv
source venv/bin/activate  # macOS/Linux
```

2. **Dependencies telepítése:**
```bash
pip install -r requirements.txt
pip install -r requirements-dev.txt  # Fejlesztési toolok
```

3. **Alkalmazás indítása:**
```bash
uvicorn src.main:app --reload
```

#### Docker nélkül (helyi adatbázisokkal)

Ha helyben futtatod a MongoDB, PostgreSQL és Redis-t:

```bash
export MONGODB_URL="mongodb://localhost:27017/nincsenekfenyek"
export POSTGRESQL_URL="postgresql://postgres:postgres@localhost:5432/nincsenekfenyek"
export REDIS_URL="redis://localhost:6379/0"
uvicorn src.main:app --reload
```

## Projekt Struktúra

```
nincsenekfenyek/
├── docs/                  # Dokumentáció
│   ├── USE_CASES.md      # Use case dokumentáció
│   ├── DEVELOPMENT.md    # Fejlesztési dokumentáció
│   ├── ARCHITECTURE.md   # Architektúra dokumentáció
│   ├── TECH_STACK.md     # Tech stack dokumentáció
│   └── QUICKSTART.md     # Gyors kezdés
├── src/                   # Backend forráskód
│   ├── api/              # API routes
│   ├── config/           # Konfiguráció
│   ├── models/           # Adatmodell
│   ├── services/         # Business logika
│   ├── utils/            # Segédfüggvények
│   ├── main.py           # Entry point
│   └── celery_app.py     # Celery konfiguráció
├── tests/                 # Tesztek
├── scripts/               # Utility scriptek
├── migrations/            # DB migrációk
├── docker-compose.yml     # Docker Compose config
├── Dockerfile             # Backend Docker image
├── requirements.txt       # Python dependencies
└── README.md              # Ez a fájl
```

## Hasznos Linkek

- [Use Cases](./USE_CASES.md) - Részletes use case dokumentáció
- [Development Guide](./docs/DEVELOPMENT.md) - Fejlesztési útmutató
- [Architecture](./docs/ARCHITECTURE.md) - Rendszerarchitektúra
- [Tech Stack](./docs/TECH_STACK.md) - Technológiai részletek
- [Quick Start](./docs/QUICKSTART.md) - Gyors kezdés útmutató
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
