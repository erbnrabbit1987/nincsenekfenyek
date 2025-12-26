# Docker Használati Útmutató

## Áttekintés

A projekt teljesen containerizálva van Docker és Docker Compose segítségével. Ez lehetővé teszi a konzisztens fejlesztési környezetet és egyszerű deployment-et.

## Szolgáltatások

A `docker-compose.yml` a következő szolgáltatásokat tartalmazza:

1. **backend** - FastAPI alkalmazás (port 8000)
2. **mongodb** - MongoDB adatbázis (port 27017)
3. **postgres** - PostgreSQL adatbázis (port 5432) - előkészítés
4. **redis** - Redis cache és message queue (port 6379)
5. **celery-worker** - Celery worker processek
6. **celery-beat** - Celery scheduler időzített feladatokhoz

## Alapvető Parancsok

### Konténerek indítása

```bash
# Összes szolgáltatás indítása (detached mode)
docker-compose up -d

# Logokkal együtt
docker-compose up

# Csak bizonyos szolgáltatások indítása
docker-compose up -d mongodb redis
```

### Konténerek leállítása

```bash
# Leállítás (adatbázisok adatai megmaradnak)
docker-compose stop

# Leállítás és konténerek törlése
docker-compose down

# Adatok törlésével együtt (VIGYÁZAT!)
docker-compose down -v
```

### Logok megtekintése

```bash
# Összes szolgáltatás logjai
docker-compose logs -f

# Csak backend logok
docker-compose logs -f backend

# Csak az utolsó 100 sor
docker-compose logs --tail=100 backend
```

### Konténer belépés

```bash
# Backend konténerbe
docker-compose exec backend bash

# MongoDB konténerbe
docker-compose exec mongodb mongosh

# PostgreSQL konténerbe
docker-compose exec postgres psql -U postgres -d nincsenekfenyek
```

### Újraépítés

Ha változtatások vannak a Dockerfile-ban vagy függőségekben:

```bash
# Újraépítés és indítás
docker-compose up -d --build

# Csak újraépítés, indítás nélkül
docker-compose build
```

## Fejlesztés

### Hot Reload

A backend konténer volume mount-tal van beállítva, így a kód változásai automatikusan betöltődnek.

### Környezeti Változók

A környezeti változók a `docker-compose.yml`-ben vannak definiálva. Éles környezetben használj `.env` fájlt:

```bash
# .env fájl létrehozása
cp .env.example .env

# Szerkeszd a .env fájlt
```

És a `docker-compose.yml`-ben:
```yaml
environment:
  - MONGODB_URL=${MONGODB_URL}
```

### Adatbázis Adatok

Az adatbázisok adatai Docker volume-okban tárolódnak:
- `mongodb_data` - MongoDB adatok
- `postgres_data` - PostgreSQL adatok
- `redis_data` - Redis adatok

Ezek a volume-ok megmaradnak, még akkor is, ha a konténereket törlöd.

## Troubleshooting

### Port konfliktusok

Ha egy port már használatban van:

```bash
# Port használat ellenőrzése
lsof -i :8000  # macOS
netstat -tulpn | grep 8000  # Linux

# Vagy változtasd meg a portot a docker-compose.yml-ben
```

### Konténer nem indul

```bash
# Státusz ellenőrzése
docker-compose ps

# Részletes logok
docker-compose logs backend

# Konténer újraindítása
docker-compose restart backend
```

### Adatbázis kapcsolati problémák

```bash
# Ellenőrizd, hogy az adatbázisok futnak-e
docker-compose ps

# Ellenőrizd a kapcsolati stringet
docker-compose exec backend env | grep MONGODB_URL
```

### Tiszta újraindítás

Ha mindent törölni szeretnél és újrakezdeni:

```bash
# Konténerek és volume-ok törlése
docker-compose down -v

# Build cache törlése
docker system prune -a

# Újraindítás
docker-compose up -d --build
```

## Production Deploy

Éles környezethez érdemes létrehozni egy `docker-compose.prod.yml` fájlt:

```yaml
version: '3.8'
services:
  backend:
    restart: always
    environment:
      - APP_ENV=production
      - DEBUG=false
    # További production beállítások
```

És használd:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## További Információk

- [Docker Dokumentáció](https://docs.docker.com/)
- [Docker Compose Dokumentáció](https://docs.docker.com/compose/)
- [Projekt README](./README.md)



