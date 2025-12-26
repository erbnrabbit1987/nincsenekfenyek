# Linux Szerver Deployment Útmutató

Ez a dokumentum részletesen leírja, hogyan lehet a **Nincsenek Fények!** alkalmazást telepíteni és futtatni egy Linux szerveren.

## Előfeltételek

### Rendszer Követelmények

- **OS**: Ubuntu 20.04+ / Debian 11+ / CentOS 8+ vagy más modern Linux disztribúció
- **RAM**: Minimum 2GB (ajánlott 4GB+)
- **Tárhely**: Minimum 10GB szabad terület
- **CPU**: 2+ core (ajánlott 4+ core)

### Szükséges Szoftverek

1. **Docker** (20.10+)
2. **Docker Compose** (1.29+)
3. **Git**
4. **SSH** (a repository klónozásához)

---

## 1. Lépés: Előfeltételek Telepítése

### Docker Telepítése

#### Ubuntu/Debian

```bash
# Régi verziók eltávolítása
sudo apt-get remove docker docker-engine docker.io containerd runc

# Frissítés
sudo apt-get update

# Függőségek telepítése
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Docker hivatalos GPG kulcs hozzáadása
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Repository hozzáadása
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker Engine telepítése
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Docker szolgáltatás indítása
sudo systemctl start docker
sudo systemctl enable docker

# Docker Compose telepítése (ha nincs benne a plugin-ben)
sudo apt-get install docker-compose-plugin
```

#### CentOS/RHEL

```bash
# Régi verziók eltávolítása
sudo yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

# Függőségek telepítése
sudo yum install -y yum-utils

# Docker repository hozzáadása
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Docker Engine telepítése
sudo yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Docker szolgáltatás indítása
sudo systemctl start docker
sudo systemctl enable docker
```

### Git Telepítése

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install git

# CentOS/RHEL
sudo yum install git
```

### SSH Kulcs Beállítása (Ha még nincs)

```bash
# SSH kulcs generálása
ssh-keygen -t ed25519 -C "server@nincsenekfenyek"

# Publikus kulcs megjelenítése
cat ~/.ssh/id_ed25519.pub
```

**Fontos:** Add hozzá ezt a publikus kulcsot a GitHub-hoz SSH key-ként.

---

## 2. Lépés: Repository Klónozása

### Main Repository (Dokumentáció)

```bash
# Munkakönyvtár létrehozása
mkdir -p /opt/nincsenekfenyek
cd /opt/nincsenekfenyek

# Main repository klónozása
git clone git@github.com:erbnrabbit1987/nincsenekfenyek.git main
cd main
```

### Development Repository (Kód) - Opció A: Külön Repository

```bash
# A főkönyvtárban
cd /opt/nincsenekfenyek

# Development repository klónozása
git clone git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git devel
cd devel
```

### Development Repository (Kód) - Opció B: Submodule

```bash
# Ha a main repo-ban submodule-ként van
cd /opt/nincsenekfenyek/main

# Submodule-ök inicializálása és klónozása
git submodule init
git submodule update

# Vagy egy lépésben
git submodule update --init --recursive
```

---

## 3. Lépés: Környezeti Változók Beállítása

```bash
# A devel könyvtárban
cd /opt/nincsenekfenyek/devel

# .env.example másolása .env-re
cp .env.example .env

# .env fájl szerkesztése
nano .env
# VAGY
vim .env
```

### Fontos Környezeti Változók

```env
# Alkalmazás beállítások
SECRET_KEY=your-secret-key-here
DEBUG=False
ENVIRONMENT=production

# Adatbázis beállítások
MONGODB_URL=mongodb://mongodb:27017/nincsenekfenyek
POSTGRESQL_URL=postgresql://postgres:password@postgres:5432/nincsenekfenyek

# Redis beállítások
REDIS_URL=redis://redis:6379/0

# API beállítások
API_HOST=0.0.0.0
API_PORT=8000

# További változók a .env.example fájlban
```

> **Fontos:** Generálj egy erős `SECRET_KEY`-t és változtasd meg az alapértelmezett jelszavakat!

---

## 4. Lépés: Docker Image-ek Build-elése

```bash
# A devel könyvtárban
cd /opt/nincsenekfenyek/devel

# Docker image-ek build-elése
docker-compose build

# Vagy ha van deploy script:
./scripts/deploy.sh -b
```

---

## 5. Lépés: Szolgáltatások Indítása

```bash
# A devel könyvtárban
cd /opt/nincsenekfenyek/devel

# Szolgáltatások indítása (background)
docker-compose up -d

# Állapot ellenőrzése
docker-compose ps
```

### Várható Szolgáltatások

- ✅ `backend` - FastAPI alkalmazás
- ✅ `mongodb` - MongoDB adatbázis
- ✅ `postgres` - PostgreSQL adatbázis (ha használod)
- ✅ `redis` - Redis cache
- ✅ `celery-worker` - Celery worker
- ✅ `celery-beat` - Celery scheduler

---

## 6. Lépés: Ellenőrzés

### Szolgáltatások Állapota

```bash
# Szolgáltatások listázása
docker-compose ps

# Health check
docker-compose exec backend curl http://localhost:8000/health
```

### Logok Ellenőrzése

```bash
# Összes szolgáltatás logja
docker-compose logs -f

# Konkrét szolgáltatás logja
docker-compose logs -f backend

# Utolsó 100 sor
docker-compose logs --tail=100 backend
```

### API Elérése

```bash
# API tesztelése
curl http://localhost:8000/health

# API dokumentáció
curl http://localhost:8000/docs
```

---

## 7. Lépés: Firewall Beállítása

### Portok Engedélyezése

```bash
# Ubuntu/Debian (UFW)
sudo ufw allow 8000/tcp  # API
sudo ufw allow 80/tcp    # HTTP (ha van reverse proxy)
sudo ufw allow 443/tcp   # HTTPS (ha van reverse proxy)

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

---

## 8. Lépés: Reverse Proxy Beállítása (Opcionális, Ajánlott)

### Nginx Példa Konfiguráció

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Nginx Telepítés és Beállítás

```bash
# Ubuntu/Debian
sudo apt-get install nginx

# Konfiguráció másolása
sudo cp nginx.conf /etc/nginx/sites-available/nincsenekfenyek
sudo ln -s /etc/nginx/sites-available/nincsenekfenyek /etc/nginx/sites-enabled/

# Nginx újraindítása
sudo systemctl restart nginx
sudo systemctl enable nginx
```

---

## 9. Lépés: Automatikus Indítás Beállítása

### Systemd Service Létrehozása

```bash
# Service fájl létrehozása
sudo nano /etc/systemd/system/nincsenekfenyek.service
```

```ini
[Unit]
Description=Nincsenek Fenek! Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/nincsenekfenyek/devel
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
```

### Service Engedélyezése

```bash
# Service újratöltése
sudo systemctl daemon-reload

# Service engedélyezése
sudo systemctl enable nincsenekfenyek

# Service indítása
sudo systemctl start nincsenekfenyek

# Állapot ellenőrzése
sudo systemctl status nincsenekfenyek
```

---

## Frissítés Folyamata

### Kód Frissítése

```bash
# A devel könyvtárban
cd /opt/nincsenekfenyek/devel

# Legfrissebb kód letöltése
git pull origin main

# Docker image-ek újraépítése (ha változtatások vannak)
docker-compose build

# Szolgáltatások újraindítása
docker-compose down
docker-compose up -d
```

### Vagy Deploy Scripttel

```bash
cd /opt/nincsenekfenyek/devel
./scripts/update.sh
```

---

## Hibaelhárítás

### Docker Problémák

```bash
# Docker állapot ellenőrzése
sudo systemctl status docker
docker info

# Konténerek listája
docker ps -a

# Konténer logok
docker logs <container_name>
```

### Port Konfliktusok

```bash
# Melyik process használja a portot?
sudo netstat -tlnp | grep :8000
sudo lsof -i :8000
```

### Tárhely Problémák

```bash
# Docker tárhely ellenőrzése
docker system df

# Nem használt image-ek és konténerek törlése
docker system prune -a
```

### Permission Problémák

```bash
# Docker group hozzáadása a felhasználóhoz (hogy ne kelljen sudo)
sudo usermod -aG docker $USER
# Újra be kell jelentkezni
```

---

## Backup és Visszaállítás

### Adatbázis Backup

```bash
# MongoDB backup
docker-compose exec mongodb mongodump --out /backup/mongodb-$(date +%Y%m%d)

# PostgreSQL backup
docker-compose exec postgres pg_dump -U postgres nincsenekfenyek > backup-$(date +%Y%m%d).sql
```

### Visszaállítás

```bash
# MongoDB restore
docker-compose exec -T mongodb mongorestore /backup/mongodb-YYYYMMDD

# PostgreSQL restore
docker-compose exec -T postgres psql -U postgres nincsenekfenyek < backup-YYYYMMDD.sql
```

---

## Biztonsági Javaslatok

1. **Firewall**: Csak a szükséges portokat engedélyezd
2. **SSL/TLS**: Használj HTTPS-t (Let's Encrypt)
3. **Jelszavak**: Erős, egyedi jelszavak minden szolgáltatáshoz
4. **Frissítések**: Rendszeres rendszer és Docker frissítések
5. **Backup**: Rendszeres adatbázis backup-ok
6. **Monitoring**: Logok és metrikák figyelése

---

## Gyors Referencia

```bash
# Klónozás
cd /opt/nincsenekfenyek
git clone git@github.com:erbnrabbit1987/nincsenekfenyek.git main
git clone git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git devel

# Beállítás
cd devel
cp .env.example .env
nano .env

# Build és indítás
docker-compose build
docker-compose up -d

# Állapot
docker-compose ps
docker-compose logs -f backend

# Frissítés
git pull
docker-compose build
docker-compose up -d
```

---

## További Dokumentáció

- [Docker Guide](../DOCKER.md)
- [Development Guide](./DEVELOPMENT.md)
- [Architecture](./ARCHITECTURE.md)



