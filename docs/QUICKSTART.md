# Gyors Kezdés

Ez a dokumentum segít a projekt gyors elindításában.

## Előfeltételek

1. **Git**: Telepítve és konfigurálva
2. **Python 3.10+** vagy **Node.js** (a technológiai választástól függ)
3. **Adatbázis**: PostgreSQL, MySQL vagy MongoDB
4. **Redis**: Cache és message queue-hoz

## Első Lépések

### 1. Repository Klónozása

```bash
cd /Users/bazsika/Git/nincsenekfenyek
```

### 2. Környezeti Változók Beállítása

Hozz létre egy `.env` fájlt a projekt gyökerében. A szükséges változók:
- `SECRET_KEY`: Alkalmazás titkos kulcs
- `DATABASE_URL`: Adatbázis kapcsolati string
- `REDIS_URL`: Redis kapcsolati string
- További változók a dokumentációban

### 3. Dokumentáció Áttekintése

- [README.md](../README.md) - Projekt áttekintés
- [USE_CASES.md](../USE_CASES.md) - Részletes use case-ek
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Rendszerarchitektúra
- [DEVELOPMENT.md](./DEVELOPMENT.md) - Fejlesztési útmutató

## Következő Lépések

1. **Technológiai Stack Választása**: Eldönteni Python vagy Node.js backend
2. **Adatbázis Kiválasztása**: PostgreSQL, MySQL vagy MongoDB
3. **Facebook API Integráció**: Meta Graph API vagy scraping
4. **Első Service Implementálása**: Forráskezelés vagy adatgyűjtés

## Kérdések?

Ha bármilyen kérdésed van a projekttel kapcsolatban, nézd meg a dokumentációt vagy hozz létre egy issue-t.

---

**Megjegyzés**: Ez a dokumentum frissül a projekt haladtával!

