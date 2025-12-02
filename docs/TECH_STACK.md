# Tech Stack Dokumentáció

> A projekt technológiai stackjének részletes leírása. **Folyamatosan frissül és maintainelendő.**

## Áttekintés

Ez a dokumentum tartalmazza a projektben használt technológiák teljes listáját, verziókat, és a választás indoklását.

---

## Backend

### Fő Framework
- **Python 3.10+**
- **FastAPI** vagy **Flask** - Modern, gyors, async támogatás

**Választás indoklása:**
- Fact-checking és NLP feladatokhoz Python optimális
- Erős library támogatás (spaCy, NLTK, transformers)
- Biztonságos működés
- Skálázható, aszinkron támogatás

### Web Framework Választás
- **FastAPI** (ajánlott) - Modern, async, automatikus API dokumentáció
- Alternatíva: **Flask** - Egyszerűbb, de szükség esetén átváltás

---

## Adatbázis

### Elsődleges: MongoDB
- **MongoDB 6.0+**
- **PyMongo** vagy **Motor** (async)
- **MongoEngine** (ODM) vagy **Beanie** (async ODM)

**Használat:**
- Posztok tárolása
- Források és forráscsoportok
- Fact-check eredmények
- Flexibilis séma a gyors fejlesztéshez

### Másodlagos: PostgreSQL (előkészítés)
- **PostgreSQL 14+**
- **SQLAlchemy** (ORM)
- **Alembic** (migrációk)

**Használat (később):**
- Strukturált adatok
- Komplex query-k
- Full-text search
- Relációs adatok

### Cache & Queue: Redis
- **Redis 7.0+**
- **redis-py** (Python client)
- **Celery** (background jobs)

---

## Frontend

### Framework
- **React 18+**
- **TypeScript** (ajánlott)
- **Vite** (build tool - gyors, modern)

### UI Library
- **Material-UI (MUI)** vagy **Ant Design** - Gyors fejlesztéshez
- Alternatíva: **Tailwind CSS** - Custom design-hoz

### State Management
- **React Query** / **TanStack Query** - Server state
- **Zustand** vagy **Redux Toolkit** - Client state (ha szükséges)

### HTTP Client
- **Axios** vagy **Fetch API**

**Választás indoklása:**
- Gyors fejlesztés
- Biztonságos
- Később fejleszthető (mobil app is)

---

## Background Jobs & Task Queue

### Celery
- **Celery 5.3+**
- **Redis** broker
- **Celery Beat** - Időzített feladatokhoz

**Felhasználás:**
- Facebook posztok gyűjtése
- Fact-checking folyamatok
- RSS feed olvasás
- Statisztikai adatok frissítése
- Email küldés

---

## Web Scraping

### Fő Könyvtárak
- **Scrapy** - Hatékony web scraping framework
- **BeautifulSoup4** - HTML parsing
- **Selenium** - JavaScript rendering (ha szükséges)
- **Playwright** - Modern alternative Selenium-hez

**Használat:**
- Facebook profil scraping (kezdetben)
- Híroldal cikkek scraping

---

## NLP & Text Processing

### Fő Könyvtárak
- **spaCy** - NLP, named entity recognition
- **NLTK** - Text processing
- **transformers** (Hugging Face) - Pre-trained modellek
- **langdetect** - Nyelvfelismerés

**Használat:**
- Állítások kinyerése szövegből
- Kulcsszavak azonosítása
- Szövegek összehasonlítása

---

## API & Integrációk

### REST API
- **FastAPI** - Automatikus OpenAPI dokumentáció
- **Pydantic** - Data validation
- **Swagger UI** - API dokumentáció

### External APIs
- **requests** - HTTP client
- **httpx** - Async HTTP client
- **aiohttp** - Async HTTP (ha szükséges)

### Facebook API (később)
- **facebook-sdk** - Meta Graph API wrapper

---

## Authentication & Security

- **JWT** (Python JWT) - Token-based auth
- **passlib** - Password hashing (bcrypt)
- **python-jose** - JWT encoding/decoding
- **CORS** middleware

---

## Testing

### Backend
- **pytest** - Testing framework
- **pytest-asyncio** - Async testing
- **pytest-cov** - Coverage
- **faker** - Test data generation
- **httpx** - API testing

### Frontend
- **Vitest** - Unit testing
- **React Testing Library** - Component testing
- **Playwright** - E2E testing

---

## DevOps & Containerization

### Docker
- **Docker** - Containerizáció
- **Docker Compose** - Multi-container orchestration

### Services in Docker
- Backend API
- Frontend (Nginx)
- MongoDB
- PostgreSQL (opcionális)
- Redis
- Celery workers

---

## Monitoring & Logging

- **Structured logging** (Python logging)
- **Sentry** - Error tracking (opcionális)
- **Prometheus** + **Grafana** (később)

---

## Code Quality

### Linting & Formatting
- **black** - Code formatter
- **flake8** - Linter
- **mypy** - Type checking
- **isort** - Import sorting

### Pre-commit Hooks
- **pre-commit** - Git hooks

---

## Package Management

### Backend
- **pip** + **requirements.txt** (kezdetben)
- **Poetry** (ajánlott később) - Dependency management

### Frontend
- **npm** vagy **yarn**
- **package.json**

---

## Version Control

- **Git** - Version control
- **GitHub** / **GitLab** - Repository hosting

---

## Dokumentáció

- **Sphinx** vagy **MkDocs** - Backend dokumentáció
- **TypeDoc** - Frontend dokumentáció (TypeScript)
- **Swagger/OpenAPI** - API dokumentáció

---

## Későbbi Bővíthetőség

### Microservices
- **gRPC** - Service-to-service communication
- **Kubernetes** - Orchestration

### Machine Learning
- **TensorFlow** / **PyTorch** - ML modellek
- **scikit-learn** - Traditional ML

### Mobile
- **React Native** - Cross-platform mobile app

---

## Verziók

### Backend Dependencies
```
Python: 3.10+
FastAPI: 0.104+
MongoDB: 6.0+
Redis: 7.0+
Celery: 5.3+
```

### Frontend Dependencies
```
React: 18+
TypeScript: 5.0+
Node.js: 18+
```

---

**Megjegyzés**: Ez a dokumentum folyamatosan frissül a projekt haladtával!

