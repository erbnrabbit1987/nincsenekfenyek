# 🐧 Linux Szerver Deployment Útmutató

> **Nincsenek Fények!** - Teljes deployment útmutató Linux szerveren  
> **Verzió:** 1.0  
> **Dátum:** 2024. december 26.

---

## 📋 Tartalomjegyzék

1. [Előfeltételek](#előfeltételek)
2. [SSH Kulcs Beállítása](#ssh-kulcs-beállítása)
3. [Repository Klónozása](#repository-klónozása)
4. [Környezeti Változók Beállítása](#környezeti-változók-beállítása)
5. [Docker Telepítése](#docker-telepítése)
6. [Build és Deploy](#build-és-deploy)
7. [Szolgáltatások Indítása](#szolgáltatások-indítása)
8. [Ellenőrzés és Tesztelés](#ellenőrzés-és-tesztelés)
9. [Troubleshooting](#troubleshooting)

---

## 🔧 1. Előfeltételek

### Rendszer Követelmények
- **OS:** Ubuntu 20.04+ / Debian 11+ / CentOS 8+ / RHEL 8+
- **RAM:** Minimum 2GB (ajánlott: 4GB+)
- **Disk:** Minimum 10GB szabad hely
- **CPU:** Minimum 2 core
- **Network:** Internet kapcsolat

### Szoftver Követelmények
- **Git:** 2.25+
- **Docker:** 20.10+
- **Docker Compose:** 2.0+
- **Python:** 3.11+ (opcionális, ha nem Docker-t használsz)

---

## 🔐 2. SSH Kulcs Beállítása

### 2.1 SSH Kulcs Ellenőrzése

```bash
# Ellenőrizd, hogy van-e SSH kulcsod
ls -la ~/.ssh/

# Ha nincs id_rsa vagy id_ed25519, generálj újat
ssh-keygen -t ed25519 -C "server@nincsenekfenyek"
# VAGY
ssh-keygen -t rsa -b 4096 -C "server@nincsenekfenyek"
```

### 2.2 Publikus Kulcs Hozzáadása GitHub-hoz

```bash
# Publikus kulcs megjelenítése
cat ~/.ssh/id_ed25519.pub
# VAGY
cat ~/.ssh/id_rsa.pub
```

**GitHub-on:**
1. Menj: https://github.com/settings/keys
2. Kattints: **"New SSH key"**
3. **Title:** `nincsenekfenyek-server` (vagy bármilyen név)
4. **Key:** Másold be a fenti parancs output-ját
5. Kattints: **"Add SSH key"**

### 2.3 SSH Kapcsolat Tesztelése

```bash
ssh -T git@github.com
```

**Várt válasz:**
```
Hi erbnrabbit1987! You've successfully authenticated, but GitHub does not provide shell access.
```

---

## 📥 3. Repository Klónozása

### 3.1 Munkakönyvtár Létrehozása

```bash
# Munkakönyvtár létrehozása
sudo mkdir -p /opt/nincsenekfenyek
sudo chown $USER:$USER /opt/nincsenekfenyek
cd /opt/nincsenekfenyek
```

### 3.2 Repository Klónozása

```bash
# Repository klónozása
git clone git@github.com:erbnrabbit1987/nincsenekfenyek.git nincsenekfenyek

# Vagy ha SSH nem működik, használj HTTPS-t:
# git clone https://github.com/erbnrabbit1987/nincsenekfenyek.git nincsenekfenyek

cd nincsenekfenyek
```

### 3.3 Repository Ellenőrzése

```bash
# Git állapot ellenőrzése
git status

# Branch ellenőrzése
git branch

# Utolsó commitok
git log --oneline -5
```

**Várt output:**
```
On branch main
Your branch is up to date with 'origin/main'.
```

---

## ⚙️ 4. Környezeti Változók Beállítása

### 4.1 .env Fájl Létrehozása

```bash
# .env.example fájl ellenőrzése
if [ -f ".env.example" ]; then
    # .env.example másolása .env-re
    cp .env.example .env
    echo "✓ .env fájl létrehozva .env.example alapján"
else
    # Ha nincs .env.example, hozd létre manuálisan
    echo "⚠️ .env.example nem található, létrehozom..."
    cat > .env << 'EOF'
# Alkalmazás beállítások
SECRET_KEY=change-me-generate-strong-key-here
DEBUG=False
ENVIRONMENT=production

# API beállítások
API_HOST=0.0.0.0
API_PORT=8000

# MongoDB beállítások
MONGODB_URL=mongodb://mongodb:27017/nincsenekfenyek

# PostgreSQL beállítások
POSTGRES_DB=nincsenekfenyek
POSTGRES_USER=postgres
POSTGRES_PASSWORD=erős-jelszó-itt
POSTGRESQL_URL=postgresql://postgres:erős-jelszó-itt@postgres:5432/nincsenekfenyek

# Redis beállítások
REDIS_URL=redis://redis:6379/0

# Celery beállítások
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0
EOF
    echo "✓ .env fájl létrehozva"
fi

# .env fájl szerkesztése
nano .env
# VAGY
vim .env
```

### 4.2 .env Konfiguráció

```env
# ⚠️ FONTOS: Módosítsd ezeket az értékeket!

# Alkalmazás beállítások
SECRET_KEY=generald-egy-eros-kulcsot-itt-64-karakter-osszesen
DEBUG=False
ENVIRONMENT=production

# API beállítások
API_HOST=0.0.0.0
API_PORT=8000

# MongoDB beállítások
MONGODB_URL=mongodb://mongodb:27017/nincsenekfenyek

# PostgreSQL beállítások
POSTGRES_DB=nincsenekfenyek
POSTGRES_USER=postgres
POSTGRES_PASSWORD=erős-jelszó-itt
POSTGRESQL_URL=postgresql://postgres:erős-jelszó-itt@postgres:5432/nincsenekfenyek

# Redis beállítások
REDIS_URL=redis://redis:6379/0

# Celery beállítások
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0
```

### 4.3 SECRET_KEY Generálása

```bash
# Generálj egy erős SECRET_KEY-t
openssl rand -hex 32

# Másold be a .env fájlba SECRET_KEY= után
```

### 4.4 Fájl Jogosultságok

```bash
# .env fájl biztonsági beállítása (csak olvasható a tulajdonosnak)
chmod 600 .env
```

---

## 🐳 5. Docker Telepítése

### 5.1 Docker Telepítése (Ubuntu/Debian)

```bash
# Régi verziók eltávolítása
sudo apt-get remove docker docker-engine docker.io containerd runc

# Frissítés
sudo apt-get update

# Előfeltételek telepítése
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Docker GPG kulcs hozzáadása
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Docker repository hozzáadása
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker telepítése
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Docker szolgáltatás indítása
sudo systemctl start docker
sudo systemctl enable docker

# Felhasználó hozzáadása docker csoporthoz (root nélküli használathoz)
sudo usermod -aG docker $USER

# Újra bejelentkezés szükséges, hogy a változás életbe lépjen
# VAGY
newgrp docker
```

### 5.2 Docker Telepítése (CentOS/RHEL)

```bash
# Docker repository hozzáadása
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Docker Engine telepítése
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Docker szolgáltatás indítása
sudo systemctl start docker
sudo systemctl enable docker

# Felhasználó hozzáadása docker csoporthoz
sudo usermod -aG docker $USER
newgrp docker
```

### 5.3 Docker Ellenőrzése

```bash
# Docker verzió ellenőrzése
docker --version

# Docker Compose verzió ellenőrzése
docker compose version

# Docker tesztelése
docker run hello-world
```

**Várt output:**
```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

---

## 🏗️ 6. Build és Deploy

### 6.1 Docker Image-ek Build-elése

```bash
# A projekt könyvtárban
cd /opt/nincsenekfenyek/nincsenekfenyek

# Docker image-ek build-elése
docker compose build

# Vagy cache nélkül (ha friss build kell)
docker compose build --no-cache
```

**Időtartam:** 5-15 perc (függ az internetsebességtől)

### 6.2 Deploy Script Használata

```bash
# Deploy script futtathatóvá tétele
chmod +x scripts/deploy.sh

# Development deployment
./scripts/deploy.sh

# Production deployment (build-tel)
./scripts/deploy.sh -e production -b

# Clean deployment (régi konténerek eltávolítása)
./scripts/deploy.sh -c
```

### 6.3 Manuális Deploy (ha a script nem működik)

```bash
# Konténerek elindítása
docker compose up -d

# Status ellenőrzése
docker compose ps

# Logok megtekintése
docker compose logs -f
```

---

## 🚀 7. Szolgáltatások Indítása

### 7.1 Alapértelmezett Indítás

```bash
# Összes szolgáltatás indítása
docker compose up -d

# Status ellenőrzése
docker compose ps
```

**Várt output:**
```
NAME                         STATUS              PORTS
nincsenekfenyek-backend      Up                  0.0.0.0:8000->8000/tcp
nincsenekfenyek-mongodb      Up                  0.0.0.0:27017->27017/tcp
nincsenekfenyek-postgres     Up                  0.0.0.0:5432->5432/tcp
nincsenekfenyek-redis        Up                  0.0.0.0:6379->6379/tcp
nincsenekfenyek-celery-worker    Up
nincsenekfenyek-celery-beat      Up
```

### 7.2 Szolgáltatások Indítása Külön-Külön

```bash
# Csak adatbázisok és Redis
docker compose up -d mongodb postgres redis

# Backend
docker compose up -d backend

# Celery Worker
docker compose up -d celery-worker

# Celery Beat
docker compose up -d celery-beat
```

### 7.3 Auto-restart Beállítása

A `docker-compose.yml` már tartalmazza a `restart: unless-stopped` beállítást minden szolgáltatáshoz, így automatikusan újraindulnak, ha a szerver újraindul.

---

## ✅ 8. Ellenőrzés és Tesztelés

### 8.1 Szolgáltatások Status Ellenőrzése

```bash
# Konténerek státusza
docker compose ps

# Logok ellenőrzése
docker compose logs backend
docker compose logs celery-worker
docker compose logs celery-beat

# Összes log real-time
docker compose logs -f
```

### 8.2 API Ellenőrzése

```bash
# Health check
curl http://localhost:8000/health

# API dokumentáció
curl http://localhost:8000/docs

# Browser-ben:
# http://your-server-ip:8000/docs
```

### 8.3 Adatbázis Kapcsolatok Ellenőrzése

```bash
# MongoDB ellenőrzése
docker compose exec mongodb mongosh --eval "db.adminCommand('ping')"

# PostgreSQL ellenőrzése
docker compose exec postgres psql -U postgres -d nincsenekfenyek -c "SELECT version();"

# Redis ellenőrzése
docker compose exec redis redis-cli ping
```

**Várt válasz:** `PONG`

### 8.4 Celery Worker Ellenőrzése

```bash
# Celery worker logok
docker compose logs celery-worker | tail -20

# Celery beat logok
docker compose logs celery-beat | tail -20
```

### 8.5 API Endpoints Tesztelése

```bash
# Sources listázása
curl http://localhost:8000/api/sources

# Collection trigger (ha van source_id)
curl -X POST http://localhost:8000/api/collection/trigger/{source_id}
```

---

## 🔧 9. Troubleshooting

### 9.1 Konténerek Nem Indulnak El

```bash
# Logok ellenőrzése
docker compose logs

# Konténerek státusza
docker compose ps -a

# Konténer újraindítása
docker compose restart backend
```

### 9.2 Port Foglalt Hiba

```bash
# Port használat ellenőrzése
sudo netstat -tulpn | grep :8000
# VAGY
sudo ss -tulpn | grep :8000

# Ha foglalt, módosítsd a docker-compose.yml port beállítását:
# ports:
#   - "8001:8000"  # Másik port használata
```

### 9.3 MongoDB Kapcsolat Hiba

```bash
# MongoDB konténer logok
docker compose logs mongodb

# MongoDB újraindítása
docker compose restart mongodb

# MongoDB belépés
docker compose exec mongodb mongosh
```

### 9.4 .env Fájl Hiányzik

```bash
# .env.example másolása
cp .env.example .env

# .env szerkesztése
nano .env

# Konténerek újraindítása
docker compose down
docker compose up -d
```

### 9.5 Disk Tér Fogyás

```bash
# Docker rendszer tisztítása
docker system prune -a

# Unused volumes törlése (⚠️ VIGYÁZAT: adatvesztés!)
docker volume prune
```

### 9.6 SSH Kulcs Probléma

```bash
# SSH agent indítása
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# SSH tesztelés
ssh -T git@github.com
```

---

## 📊 10. Monitoring és Karbantartás

### 10.1 Logok Megtekintése

```bash
# Összes log
docker compose logs -f

# Egy szolgáltatás logja
docker compose logs -f backend

# Utolsó 100 sor
docker compose logs --tail=100 backend
```

### 10.2 Backup

```bash
# Backup könyvtár létrehozása
mkdir -p /opt/nincsenekfenyek/nincsenekfenyek/backups

# MongoDB backup (adatkönyvtárból vagy konténerből)
cd /opt/nincsenekfenyek/nincsenekfenyek
docker compose exec mongodb mongodump --archive > backups/mongodb_$(date +%Y%m%d_%H%M%S).archive
# Vagy közvetlenül az adatkönyvtárról:
# tar -czf backups/mongodb_$(date +%Y%m%d_%H%M%S).tar.gz data/mongodb/

# PostgreSQL backup
docker compose exec postgres pg_dump -U postgres nincsenekfenyek > backups/postgres_$(date +%Y%m%d_%H%M%S).sql
# Vagy közvetlenül az adatkönyvtárról:
# tar -czf backups/postgres_$(date +%Y%m%d_%H%M%S).tar.gz data/postgres/

# Redis backup (adatkönyvtárról)
tar -czf backups/redis_$(date +%Y%m%d_%H%M%S).tar.gz data/redis/

# Teljes data könyvtár backup
tar -czf backups/full_data_backup_$(date +%Y%m%d_%H%M%S).tar.gz data/
```

### 10.3 Update (Frissítés)

```bash
cd /opt/nincsenekfenyek/nincsenekfenyek

# Változások letöltése
git pull origin main

# Újra build
docker compose build

# Konténerek újraindítása
docker compose down
docker compose up -d
```

### 10.4 Restart Szolgáltatások

```bash
# Összes szolgáltatás újraindítása
docker compose restart

# Egy szolgáltatás újraindítása
docker compose restart backend
```

---

## 🎯 Gyors Referencia

### Először Telepítés

```bash
# 1. SSH kulcs beállítása
ssh-keygen -t ed25519 -C "server@nincsenekfenyek"
cat ~/.ssh/id_ed25519.pub  # Add hozzá GitHub-hoz

# 2. Repository klónozása
sudo mkdir -p /opt/nincsenekfenyek && sudo chown $USER:$USER /opt/nincsenekfenyek
cd /opt/nincsenekfenyek
git clone git@github.com:erbnrabbit1987/nincsenekfenyek.git nincsenekfenyek
cd nincsenekfenyek

# 3. .env fájl beállítása
cp .env.example .env
nano .env  # SECRET_KEY generálása!

# 4. Docker telepítése
# (lásd fent: 5. Docker Telepítése)

# 5. Build és Deploy
docker compose build
docker compose up -d

# 6. Ellenőrzés
curl http://localhost:8000/health
```

### Frissítés

```bash
cd /opt/nincsenekfenyek/nincsenekfenyek
git pull origin main
docker compose build
docker compose down
docker compose up -d
```

### Logok

```bash
docker compose logs -f
```

### Stop/Start

```bash
# Stop
docker compose stop

# Start
docker compose start

# Down (teljes leállítás és törlés)
docker compose down
```

---

## 📚 További Dokumentáció

- **Pre-Deployment Check:** `docs/PRE_DEPLOYMENT_CHECK.md`
- **Architecture:** `docs/ARCHITECTURE.md`
- **Development Guide:** `docs/DEVELOPMENT.md`
- **API Documentation:** http://your-server:8000/docs

---

## ✅ Deployment Checklist

- [ ] SSH kulcs beállítva GitHub-hoz
- [ ] Repository klónozva
- [ ] .env fájl létrehozva és konfigurálva
- [ ] SECRET_KEY generálva
- [ ] Docker telepítve
- [ ] Docker Compose telepítve
- [ ] Docker image-ek build-elve
- [ ] Konténerek elindítva
- [ ] Health check sikeres
- [ ] API elérhető
- [ ] MongoDB működik
- [ ] PostgreSQL működik
- [ ] Redis működik
- [ ] Celery Worker fut
- [ ] Celery Beat fut
- [ ] Logok ellenőrizve

---

**Utolsó frissítés:** 2024. december 26.  
**Készítette:** Auto (AI Assistant)

