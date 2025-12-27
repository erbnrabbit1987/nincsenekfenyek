# 📦 Docker Volumes -> Bind Mounts Migráció

## Áttekintés

A Docker volume-okat bind mount-okra változtattuk, hogy:
- ✅ **Persistent storage** legyen a szerver fájlrendszerén
- ✅ **Könnyebb backup** - közvetlenül a fájlrendszerből
- ✅ **Könnyebb migráció** - egyszerűen másolható
- ✅ **Jobb kontroll** - direkt hozzáférés az adatokhoz

---

## Változások

### Előtte (Docker Volumes)
```yaml
volumes:
  mongodb_data:
  postgres_data:
  redis_data:
  
# Adatok: /var/lib/docker/volumes/... (belső Docker hely)
```

### Utána (Bind Mounts)
```yaml
volumes:
  - ./data/mongodb:/data/db
  - ./data/postgres:/var/lib/postgresql/data
  - ./data/redis:/data

# Adatok: ./data/ (a projekt könyvtárában, a szerver fájlrendszerén)
```

---

## Migráció Lépései

### Ha Már Vannak Docker Volume-ok

**1. Konténerek Leállítása**
```bash
cd /opt/nincsenekfenyek/nincsenekfenyek
docker compose down
```

**2. Régi Adatok Exportálása**

```bash
# Backup könyvtár
mkdir -p backups/migration

# MongoDB adatok exportálása
docker run --rm \
  -v nincsenekfenyek_mongodb_data:/data \
  -v $(pwd)/backups/migration:/backup \
  mongo:6.0 \
  mongodump --archive=/backup/mongodb_backup.archive --db=nincsenekfenyek

# PostgreSQL adatok exportálása
docker run --rm \
  -v nincsenekfenyek_postgres_data:/var/lib/postgresql/data \
  -e PGPASSWORD=postgres \
  postgres:15 \
  pg_dump -U postgres -d nincsenekfenyek > backups/migration/postgres_backup.sql

# Redis adatok exportálása (ha van)
docker run --rm \
  -v nincsenekfenyek_redis_data:/data \
  -v $(pwd)/backups/migration:/backup \
  redis:7-alpine \
  cp /data/dump.rdb /backup/redis_dump.rdb 2>/dev/null || echo "No Redis dump"
```

**3. Új Adatkönyvtárak Létrehozása**

```bash
# Adatkönyvtárak létrehozása
mkdir -p data/mongodb data/mongodb-config data/postgres data/redis

# Jogosultságok beállítása
# PostgreSQL (UID/GID 999)
sudo chown -R 999:999 data/postgres

# MongoDB (UID/GID 999)
sudo chown -R 999:999 data/mongodb
sudo chown -R 999:999 data/mongodb-config

# Redis (UID/GID 999)
sudo chown -R 999:999 data/redis
```

**4. Git Pull (Friss Docker Compose)**

```bash
git pull origin main
```

**5. Adatok Importálása (Ha Szükséges)**

```bash
# MongoDB adatok visszaállítása
docker compose up -d mongodb
sleep 10  # Várj, amíg elindul

docker compose exec mongodb mongorestore --archive=</opt/nincsenekfenyek/nincsenekfenyek/backups/migration/mongodb_backup.archive

# PostgreSQL adatok visszaállítása
docker compose up -d postgres
sleep 10

cat backups/migration/postgres_backup.sql | docker compose exec -T postgres psql -U postgres -d nincsenekfenyek
```

**6. Régi Volume-ok Törlése (Opcionális)**

```bash
# ⚠️ VIGYÁZAT: Csak akkor, ha biztos vagy, hogy az adatok migrálva lettek!

# Régi volume-ok listázása
docker volume ls | grep nincsenekfenyek

# Régi volume-ok törlése (ha biztos vagy)
docker volume rm nincsenekfenyek_mongodb_data
docker volume rm nincsenekfenyek_mongodb_config
docker volume rm nincsenekfenyek_postgres_data
docker volume rm nincsenekfenyek_redis_data
```

**7. Konténerek Újraindítása**

```bash
docker compose up -d
```

---

## Új Telepítés (Nincs Régi Adat)

**1. Repository Klónozása**

```bash
cd /opt/nincsenekfenyek
git clone git@github.com:erbnrabbit1987/nincsenekfenyek.git nincsenekfenyek
cd nincsenekfenyek
```

**2. Adatkönyvtárak Létrehozása**

```bash
# Adatkönyvtárak létrehozása
mkdir -p data/mongodb data/mongodb-config data/postgres data/redis

# Jogosultságok beállítása
sudo chown -R 999:999 data/postgres
sudo chown -R 999:999 data/mongodb
sudo chown -R 999:999 data/mongodb-config
sudo chown -R 999:999 data/redis

# Vagy ha root vagy, akkor:
chmod -R 755 data
```

**3. Deploy**

```bash
./scripts/deploy.sh
```

---

## Adatok Elérési Útvonalai

### Host Fájlrendszer (Szerver)
```
/opt/nincsenekfenyek/nincsenekfenyek/
├── data/
│   ├── mongodb/          # MongoDB adatbázis fájlok
│   ├── mongodb-config/   # MongoDB konfiguráció
│   ├── postgres/         # PostgreSQL adatbázis fájlok
│   └── redis/            # Redis adatfájlok
```

### Konténer Belül
```
MongoDB:    /data/db
MongoDB:    /data/configdb
PostgreSQL: /var/lib/postgresql/data
Redis:      /data
```

---

## Backup

### Manuális Backup

```bash
cd /opt/nincsenekfenyek/nincsenekfenyek

# Backup könyvtár
mkdir -p backups/$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"

# Teljes data könyvtár backup
tar -czf ${BACKUP_DIR}/full_data_backup.tar.gz data/

# Vagy csak egyes adatbázisok
tar -czf ${BACKUP_DIR}/mongodb_backup.tar.gz data/mongodb/
tar -czf ${BACKUP_DIR}/postgres_backup.tar.gz data/postgres/
tar -czf ${BACKUP_DIR}/redis_backup.tar.gz data/redis/
```

### Restore

```bash
# Teljes restore
cd /opt/nincsenekfenyek/nincsenekfenyek
docker compose down
tar -xzf backups/YYYYMMDD_HHMMSS/full_data_backup.tar.gz
docker compose up -d
```

---

## Előnyök

### Bind Mounts vs Volumes

**Bind Mounts Előnyei:**
- ✅ Közvetlen hozzáférés a szerver fájlrendszerén
- ✅ Könnyebb backup (standard tar/rsync)
- ✅ Könnyebb migráció másik szerverre
- ✅ Látható a fájlrendszerben
- ✅ Könnyebb monitoring (df, du parancsok)

**Docker Volumes Előnyei:**
- ✅ Docker kezeli a teljesítményt
- ✅ Platform független
- ✅ Automatikus kezelés

**Választásunk:** Bind mounts - jobb kontroll és könnyebb backup production környezetben.

---

## Jogosultságok

A database konténerek speciális UID/GID-vel futnak:

- **PostgreSQL:** UID 999, GID 999
- **MongoDB:** UID 999, GID 999  
- **Redis:** UID 999, GID 999

Ezért a `data/` könyvtárakat ezekre kell beállítani:

```bash
sudo chown -R 999:999 data/mongodb data/mongodb-config data/postgres data/redis
```

---

## Troubleshooting

### Permission Denied Hibák

```bash
# Jogosultságok ellenőrzése
ls -la data/

# Jogosultságok javítása
sudo chown -R 999:999 data/
chmod -R 755 data/
```

### Konténer Nem Indul

```bash
# Logok ellenőrzése
docker compose logs mongodb
docker compose logs postgres

# Ha permission probléma, javítsd a jogosultságokat
sudo chown -R 999:999 data/
```

### Adatok Nem Tűnnek El Konténer Újraindítás után

Ez normális! Az adatok mostantól a `data/` könyvtárban vannak a szerver fájlrendszerén, így megmaradnak, még akkor is, ha a konténereket törlöd.

---

**Utolsó frissítés:** 2024. december 27.  
**Status:** ✅ Bind mounts konfigurálva

