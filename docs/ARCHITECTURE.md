# Architektúra Dokumentáció

> A rendszer architektúrájának részletes leírása. **Folyamatosan frissül és maintainelendő.**

## Tartalomjegyzék

1. [Áttekintés](#áttekintés)
2. [Rendszerarchitektúra](#rendszerarchitektúra)
3. [Komponensek](#komponensek)
4. [Adatmodell](#adatmodell)
5. [API Design](#api-design)
6. [Integrációk](#integrációk)
7. [Adatbázis](#adatbázis)
8. [Infrastruktúra](#infrastruktúra)

---

## Áttekintés

A **Nincsenek Fények!** egy moduláris, skálázható fact-checking és monitoring alkalmazás. A rendszer több komponensből áll, amelyek együttműködnek a források figyelésében, adatgyűjtésben és tényellenőrzésben.

### Főbb Architektúrai Elvek
- **Modularitás**: Külön modulok különböző funkcionalitásokhoz
- **Skálázhatóság**: Horizontális skálázhatóság tervezés
- **Aszinkronitás**: Background job-ok adatgyűjtéshez
- **API-first**: RESTful API vagy GraphQL
- **Microservices-ready**: Jövőben microservices architektúrára bővíthető

---

## Rendszerarchitektúra

```
┌─────────────────────────────────────────────────────────────┐
│                      Frontend Layer                          │
│  (Web Dashboard / Mobile App - később)                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                      API Gateway                             │
│  (Authentication, Rate Limiting, Routing)                   │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
┌───────▼────┐  ┌──────▼─────┐  ┌─────▼──────┐
│   Core     │  │  Data      │  │ Fact-check │
│  Services  │  │ Collection │  │  Service   │
└───────┬────┘  └──────┬─────┘  └─────┬──────┘
        │              │              │
        └──────────────┼──────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
┌───────▼────┐  ┌──────▼─────┐  ┌─────▼──────┐
│ External   │  │  Database  │  │  Message   │
│ Integrations│  │  (PostgreSQL│ │  Queue     │
│ (FB, APIs) │  │   /MongoDB) │ │  (Redis)   │
└────────────┘  └─────────────┘  └────────────┘
```

### Rétegek

1. **Frontend Layer**: Felhasználói felület
2. **API Gateway**: Request routing, auth, rate limiting
3. **Application Layer**: Business logika
   - Core Services (forráskezelés, felhasználók)
   - Data Collection Service (adatgyűjtés)
   - Fact-check Service (tényellenőrzés)
4. **Data Layer**: Adatbázis, message queue, cache
5. **External Integrations**: Facebook API, statisztikák, stb.

---

## Komponensek

### 1. Core Services

**Forráskód helye**: `src/services/core/`

**Funkciók**:
- Forráscsoportok kezelése
- Felhasználói kezelés és autentikáció
- Beállítások és konfiguráció
- Dashboard adatok összeállítása

**Technológia**: [Még meghatározandó - Python/Node.js]

---

### 2. Data Collection Service

**Forráskód helye**: `src/services/collection/`

**Funkciók**:
- Facebook profil monitoring
- Híroldal RSS/scraping
- Statisztikai API hívások (EUROSTAT)
- Időzített feladatok (cron jobs)

**Komponensek**:
- **Facebook Collector**: Facebook Graph API vagy scraping
- **RSS Collector**: RSS feed olvasó
- **Web Scraper**: Híroldal scraping (ha RSS nincs)
- **Statistics Collector**: Statisztikai API integrációk

**Technológia**: 
- Background job processor (Celery, Bull Queue, stb.)
- Scheduler (APScheduler, node-cron)

---

### 3. Fact-check Service

**Forráskód helye**: `src/services/factcheck/`

**Funkciók**:
- Állítások azonosítása (NLP)
- Források összevetése
- Hivatkozások keresése
- Eltérések detektálása
- Fact-check jelentés generálása

**Komponensek**:
- **Claim Extractor**: Állítások kinyerése szövegből
- **Source Matcher**: Kapcsolódó források keresése
- **Reference Finder**: Hivatkozások keresése
- **Discrepancy Detector**: Eltérések azonosítása
- **Report Generator**: Jelentések generálása

**Technológia**:
- NLP library (spaCy, NLTK - Python vagy hasonló)
- Search engine (Elasticsearch opcionális)

---

### 4. Search Service

**Forráskód helye**: `src/services/search/`

**Funkciók**:
- Teljes szöveges keresés
- Szűrés (forrás, dátum, kategória)
- Relevancia rangsorolás

**Technológia**:
- Full-text search (PostgreSQL full-text vagy Elasticsearch)

---

## Adatmodell

### Főbb Entitások

```
User
├── id
├── email
├── password_hash
├── created_at
└── settings

SourceGroup
├── id
├── user_id
├── name
├── description
└── created_at

Source
├── id
├── source_group_id
├── type (facebook, news, statistics)
├── url/identifier
├── config
├── is_active
└── created_at

Post (Facebook/Híroldal)
├── id
├── source_id
├── content
├── posted_at
├── metadata (likes, comments, etc.)
└── collected_at

FactCheck
├── id
├── post_id
├── claims (JSON array)
├── references (JSON array)
├── discrepancies (JSON array)
├── status (verified, disputed, etc.)
└── created_at

Statistics
├── id
├── source (eurostat, etc.)
├── dataset_name
├── data (JSON)
└── updated_at
```

*Pontos séma később, adatbázis kiválasztás után*

---

## API Design

### REST API Endpoints (Tervezési fázis)

#### Források
- `GET /api/sources` - Források listája
- `POST /api/sources` - Új forrás hozzáadása
- `GET /api/sources/:id` - Forrás részletei
- `PUT /api/sources/:id` - Forrás módosítása
- `DELETE /api/sources/:id` - Forrás törlése

#### Forráscsoportok
- `GET /api/source-groups` - Csoportok listája
- `POST /api/source-groups` - Új csoport
- `GET /api/source-groups/:id` - Csoport részletei
- `PUT /api/source-groups/:id` - Csoport módosítása

#### Posztok/Tartalom
- `GET /api/posts` - Posztok listája (szűrhető)
- `GET /api/posts/:id` - Poszt részletei
- `GET /api/posts/:id/fact-check` - Fact-check jelentés

#### Keresés
- `GET /api/search?q=...` - Keresés

#### Összefoglalók
- `GET /api/summaries` - Összefoglalók listája
- `GET /api/summaries/:id` - Összefoglaló részletei

*Pontos API specifikáció később OpenAPI/Swagger formátumban*

---

## Integrációk

### Facebook Integration
- **API**: Meta Graph API (ha elérhető)
- **Alternatíva**: Web scraping (jogi megfontolásokkal)
- **Auth**: OAuth flow (ha API)

### Statisztikai Portálok
- **EUROSTAT**: REST API
- **KSH** (Magyar Statisztikai Hivatal): API vagy CSV export
- **Más források**: Általános REST API integráció

### Híroldalak
- **RSS Feed**: RSS/Atom parser
- **Web Scraping**: Scrapy vagy hasonló (jogi megfontolásokkal)

---

## Adatbázis

### Opciók (eldöntendő)
1. **PostgreSQL**: Relációs, komplex query-khez, full-text search
2. **MongoDB**: Dokumentum-orientált, flexibilis séma
3. **Hybrid**: PostgreSQL + Redis (cache, queue)

### Szempontok
- Adatok természete (strukturált vs. flexibilis)
- Query komplexitás
- Skálázhatóság
- Számlálási költség

---

## Infrastruktúra

### Development
- Local development environment
- Docker Compose (adatrepozitóriumok, Redis, stb.)

### Production (Tervezési fázis)
- Cloud provider (AWS, GCP, Azure - eldöntendő)
- Containerization (Docker)
- Orchestration (Kubernetes opcionális)
- CI/CD Pipeline
- Monitoring és Logging

---

## Message Queue & Background Jobs

### Cél
- Aszinkron adatgyűjtés
- Fact-checking folyamatok
- Email/értesítési küldés

### Technológia Opciók
- **Redis + Celery** (Python)
- **Redis + Bull Queue** (Node.js)
- **RabbitMQ**
- **AWS SQS** (cloud)

---

## Security

### Authentication & Authorization
- JWT token-based authentication
- Role-based access control (RBAC) - ha kell

### Data Protection
- HTTPS mindenhol
- Adatok titkosítása (at rest)
- Secrets management (environment variables, vault)

### Rate Limiting
- API endpointokon
- External API hívásoknál

---

## Monitoring & Logging

### Logging
- Strukturált logging (JSON formátum)
- Log levels (DEBUG, INFO, WARNING, ERROR)
- Centralized logging (ELK stack opcionális)

### Monitoring
- Application metrics
- Error tracking (Sentry vagy hasonló)
- Performance monitoring
- Uptime monitoring

---

## Skálázhatóság

### Horizontal Scaling
- Stateless application komponensek
- Load balancing
- Database sharding (ha szükséges)

### Caching Strategy
- Redis cache gyakran lekérdezett adatokhoz
- Cache invalidation stratégia

---

## Későbbi Bővíthetőség

- **Microservices**: Később microservices architektúrára bontás
- **Machine Learning**: ML modellek fact-checking javításához
- **Real-time**: WebSocket kapcsolatok real-time értesítésekhez
- **Mobile App**: Native vagy React Native app

---

**Megjegyzés**: Ez a dokumentum folyamatosan frissül a projekt haladtával és a döntésekkel!

