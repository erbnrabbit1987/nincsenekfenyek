# Deployment Scripts

Ez a könyvtár tartalmazza a projekt deployment és kezelési scriptjeit.

## Scriptek

### deploy.sh
Fő deployment script development és production környezethez.

**Használat:**
```bash
# Development deployment
./scripts/deploy.sh

# Production deployment
./scripts/deploy.sh -e production -b

# Clean deployment (volumes törlése)
./scripts/deploy.sh -c

# Build és deployment
./scripts/deploy.sh -b
```

**Opciók:**
- `-e, --environment`: Környezet (development|production)
- `-b, --build`: Docker image-ek újraépítése
- `-c, --clean`: Konténerek és volume-ok törlése
- `-h, --help`: Súgó megjelenítése

### deploy-production.sh
Production deployment script biztonságos backup-pel.

**Használat:**
```bash
sudo ./scripts/deploy-production.sh
```

**Funkciók:**
- Production környezeti ellenőrzések
- Automatikus backup készítése
- Biztonságos deployment folyamat

### stop.sh
Szolgáltatások leállítása.

**Használat:**
```bash
# Csak leállítás
./scripts/stop.sh

# Leállítás és volume-ok törlése
./scripts/stop.sh -c
```

### status.sh
Szolgáltatások állapotának ellenőrzése.

**Használat:**
```bash
./scripts/status.sh
```

**Információk:**
- Konténer státusz
- Health check eredmények
- Service URL-ek
- Legfrissebb log sorok

### update.sh
Szolgáltatások frissítése.

**Használat:**
```bash
./scripts/update.sh
```

**Funkciók:**
- Git pull (ha git repo)
- Docker image-ek frissítése
- Szolgáltatások újraindítása

### logs.sh
Log megtekintés.

**Használat:**
```bash
# Összes szolgáltatás logja
./scripts/logs.sh

# Konkrét szolgáltatás logja
./scripts/logs.sh backend
./scripts/logs.sh -s backend

# Követés (follow mode)
./scripts/logs.sh -f
./scripts/logs.sh -f backend

# Sorok száma
./scripts/logs.sh -n 50
```

**Opciók:**
- `-s, --service`: Szolgáltatás neve
- `-f, --follow`: Követés mód
- `-n, --lines`: Sorok száma (alapértelmezett: 100)

## Gyors Referencia

```bash
# Teljes deployment
./scripts/deploy.sh -b

# Állapot ellenőrzés
./scripts/status.sh

# Logok követése
./scripts/logs.sh -f backend

# Leállítás
./scripts/stop.sh

# Frissítés
./scripts/update.sh
```

## Javaslatok

1. **Első deployment:** Használd a `deploy.sh -b` parancsot
2. **Rendszeres frissítések:** Használd az `update.sh` scriptet
3. **Problémamegoldás:** Nézd meg a logokat a `logs.sh` scripttel
4. **Production:** Mindig használd a `deploy-production.sh` scriptet backup-pel

## Hibaelhárítás

Ha a scriptek nem futnak:
```bash
chmod +x scripts/*.sh
```

Ha Docker problémák vannak:
```bash
# Docker állapot ellenőrzése
docker info
docker-compose version

# Konténerek állapota
docker-compose ps
```



