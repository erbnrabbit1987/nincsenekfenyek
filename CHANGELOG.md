# Changelog

Minden jelentős változás ebben a fájlban lesz dokumentálva.

A formátum a [Keep a Changelog](https://keepachangelog.com/hu/1.0.0/) alapján követi a [Semantic Versioning](https://semver.org/lang/hu/) verziószámozást.

## [Unreleased]

### Hozzáadva
- Deployment scriptek komplett szettel
  - `deploy.sh` - Fő deployment script (development/production)
  - `deploy-production.sh` - Production deployment backup-pel
  - `stop.sh` - Szolgáltatások leállítása
  - `status.sh` - Szolgáltatások állapot ellenőrzése
  - `logs.sh` - Log megtekintés és követés
  - `update.sh` - Szolgáltatások frissítése
- Deployment scriptek dokumentációja
- Tech stack döntések dokumentálása (Python, MongoDB, PostgreSQL előkészítés, React)
- Docker és Docker Compose konfiguráció
- FastAPI backend alapok
- MongoDB + PostgreSQL adatbázis réteg (Motor, SQLAlchemy)
- Celery background jobs setup
- Forráskezelés API endpoints
- Source és SourceGroup modell
- API dokumentáció (Swagger/OpenAPI)
- Docker használati útmutató

### Módosítva
- README frissítve deployment scriptekkel és gyors deployment útmutatóval
- Architektúra dokumentáció frissítve tech stack választásokkal

## [0.1.0] - 2024-01-XX

### Hozzáadva
- Projekt inicializálása
- Use case dokumentáció
- Fejlesztési dokumentáció
- Architektúra dokumentáció
- Tech stack dokumentáció
- Git repository beállítása
- Projekt struktúra alap fájljai

## [0.1.0] - 2024-01-XX

### Hozzáadva
- Kezdeti projekt struktúra
- Alap dokumentáció

---

## Verziószámozási Formátum

- **MAJOR** (X.0.0): Breaking changes
- **MINOR** (0.X.0): Új funkciók, backward compatible
- **PATCH** (0.0.X): Bugfixek, backward compatible

