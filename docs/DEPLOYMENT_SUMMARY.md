# Linux Szerver Deployment - Gyors Összefoglaló

## 📋 Lépésről Lépésre

### 1️⃣ Előfeltételek Telepítése

```bash
# Docker telepítése (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install docker.io docker-compose git

# Docker szolgáltatás indítása
sudo systemctl start docker
sudo systemctl enable docker

# Docker group hozzáadása (hogy ne kelljen sudo)
sudo usermod -aG docker $USER
# Újra be kell jelentkezni!
```

### 2️⃣ Repository Klónozása

```bash
# Munkakönyvtár
mkdir -p /opt/nincsenekfenyek
cd /opt/nincsenekfenyek

# Main repository (dokumentáció)
git clone git@github.com:erbnrabbit1987/nincsenekfenyek.git main

# Development repository (kód)
git clone git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git devel
cd devel
```

**VAGY submodule-ként:**

```bash
cd /opt/nincsenekfenyek/main
git submodule update --init --recursive
cd devel
```

### 3️⃣ Környezeti Változók

```bash
# .env fájl létrehozása
cp .env.example .env

# Szerkesztés
nano .env
# Vagy: vim .env

# Fontos változók:
# - SECRET_KEY (generálj erős kulcsot!)
# - Adatbázis jelszavak
# - API beállítások
```

### 4️⃣ Build és Indítás

```bash
# Docker image-ek build-elése
docker-compose build

# Szolgáltatások indítása
docker-compose up -d

# Állapot ellenőrzése
docker-compose ps

# Logok
docker-compose logs -f backend
```

### 5️⃣ Ellenőrzés

```bash
# API teszt
curl http://localhost:8000/health

# Szolgáltatások listája
docker-compose ps

# Minden szolgáltatás fut? ✅
```

### 6️⃣ Firewall (Ha szükséges)

```bash
# Port engedélyezése
sudo ufw allow 8000/tcp

# VAGY firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --reload
```

---

## 🔄 Frissítés

```bash
cd /opt/nincsenekfenyek/devel

# Kód frissítése
git pull origin main

# Újraépítés és indítás
docker-compose build
docker-compose down
docker-compose up -d
```

---

## 🛠️ Hasznos Parancsok

```bash
# Szolgáltatások leállítása
docker-compose stop

# Szolgáltatások indítása
docker-compose start

# Teljes újraindítás
docker-compose restart

# Logok követése
docker-compose logs -f

# Konténer belépés
docker-compose exec backend bash

# Állapot
docker-compose ps
```

---

## ⚠️ Hibaelhárítás

```bash
# Docker állapot
sudo systemctl status docker

# Konténer logok
docker logs <container_name>

# Port ellenőrzés
sudo netstat -tlnp | grep :8000

# Tárhely
docker system df
```

---

## 📚 Teljes Dokumentáció

Részletes útmutató: [DEPLOYMENT.md](./DEPLOYMENT.md)



