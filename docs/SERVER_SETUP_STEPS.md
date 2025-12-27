# Linux Szerver Setup - Részletes Lépések

## 📝 Áttekintés

Ez a dokumentum a **Nincsenek Fények!** alkalmazás Linux szerveren való telepítésének lépésről-lépésre útmutatója.

---

## 🔧 1. Előfeltételek Telepítése

### 1.1 Docker Telepítése (Ubuntu/Debian)

```bash
# Régi Docker verziók eltávolítása
sudo apt-get remove docker docker-engine docker.io containerd runc

# Rendszer frissítése
sudo apt-get update

# Szükséges csomagok telepítése
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Docker hivatalos GPG kulcs
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Docker repository hozzáadása
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker telepítése
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Docker szolgáltatás indítása és automatikus indítás
sudo systemctl start docker
sudo systemctl enable docker

# Docker verzió ellenőrzése
docker --version
docker compose version
```

### 1.2 Git Telepítése

```bash
# Git telepítése
sudo apt-get install git

# Verzió ellenőrzése
git --version
```

### 1.3 SSH Kulcs Beállítása GitHub-hoz

```bash
# SSH kulcs generálása (ha még nincs)
ssh-keygen -t ed25519 -C "server@nincsenekfenyek"

# Publikus kulcs megjelenítése
cat ~/.ssh/id_ed25519.pub
```

**Fontos:** Másold ki ezt a kulcsot és add hozzá a GitHub-hoz:
- GitHub → Settings → SSH and GPG keys → New SSH key

---

## 📥 2. Repository Klónozása

### 2.1 Munkakönyvtár Létrehozása

```bash
# Munkakönyvtár létrehozása
sudo mkdir -p /opt/nincsenekfenyek
sudo chown $USER:$USER /opt/nincsenekfenyek
cd /opt/nincsenekfenyek
```

### 2.2 Main Repository (Dokumentáció)

```bash
# Main repository klónozása
git clone git@github.com:erbnrabbit1987/nincsenekfenyek.git main
cd main
```

### 2.3 Development Repository (Kód)

**Opció A: Külön Repository-ként**

```bash
# Visszalépés a főkönyvtárba
cd /opt/nincsenekfenyek

# Development repository klónozása
git clone git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git devel
cd devel
```

**Opció B: Submodule-ként (ha be van állítva)**

```bash
# Main repository-ban
cd /opt/nincsenekfenyek/main

# Submodule inicializálása és klónozása
git submodule update --init --recursive

# Devel könyvtárba lépés
cd devel
```

---

## ⚙️ 3. Környezeti Változók Beállítása

### 3.1 .env Fájl Létrehozása

```bash
# A devel könyvtárban
cd /opt/nincsenekfenyek/devel

# .env.example másolása
cp .env.example .env
```

### 3.2 .env Fájl Szerkesztése

```bash
# Szerkesztés (válassz egyet)
nano .env
# VAGY
vim .env
```

### 3.3 Fontos Változók Beállítása

```env
# Alkalmazás beállítások
SECRET_KEY=generált-érős-kulcs-itt  # ⚠️ GENERÁLD ÚJAT!
DEBUG=False
ENVIRONMENT=production

# Adatbázis
MONGODB_URL=mongodb://mongodb:27017/nincsenekfenyek
POSTGRESQL_URL=postgresql://postgres:EROS_JELSZO_ITT@postgres:5432/nincsenekfenyek

# Redis
REDIS_URL=redis://redis:6379/0

# API
API_HOST=0.0.0.0
API_PORT=8000
```

**⚠️ FONTOS:**
- Generálj egy erős `SECRET_KEY`-t (pl: `openssl rand -hex 32`)
- Változtasd meg az alapértelmezett adatbázis jelszavakat

---

## 🏗️ 4. Docker Image-ek Build-elése

```bash
# A devel könyvtárban
cd /opt/nincsenekfenyek/devel

# Build-elés
docker-compose build

# Ez eltarthat néhány percig...
```

### 4.1 Build Ellenőrzése

```bash
# Build sikeres volt?
docker images | grep nincsenekfenyek
```

---

## 🚀 5. Szolgáltatások Indítása

### 5.1 Konténerek Indítása

```bash
# A devel könyvtárban
cd /opt/nincsenekfenyek/devel

# Szolgáltatások indítása (háttérben)
docker-compose up -d

# Vagy ha van deploy script:
./scripts/deploy.sh -b
```

### 5.2 Állapot Ellenőrzése

```bash
# Szolgáltatások listázása
docker-compose ps

# Várható eredmény:
# ✅ backend         Up
# ✅ mongodb         Up
# ✅ redis           Up
# ✅ celery-worker   Up
# ✅ celery-beat     Up
```

---

## ✅ 6. Ellenőrzés és Tesztelés

### 6.1 Szolgáltatások Logok

```bash
# Összes log
docker-compose logs

# Backend log
docker-compose logs backend

# Követés (real-time)
docker-compose logs -f backend
```

### 6.2 API Tesztelése

```bash
# Health check
curl http://localhost:8000/health

# API dokumentáció
curl http://localhost:8000/docs
```

### 6.3 Böngészőből

Nyisd meg a böngészőben:
- API: `http://szerver-ip:8000`
- Dokumentáció: `http://szerver-ip:8000/docs`

---

## 🔥 7. Firewall Beállítása

### 7.1 UFW (Ubuntu/Debian)

```bash
# Port engedélyezése
sudo ufw allow 8000/tcp

# Vagy specifikus IP-ről
sudo ufw allow from YOUR_IP to any port 8000

# Firewall állapot
sudo ufw status
```

### 7.2 Firewalld (CentOS/RHEL)

```bash
# Port engedélyezése
sudo firewall-cmd --permanent --add-port=8000/tcp
sudo firewall-cmd --reload

# Állapot
sudo firewall-cmd --list-ports
```

---

## 🔄 8. Frissítési Folyamat

### 8.1 Kód Frissítése

```bash
# A devel könyvtárban
cd /opt/nincsenekfenyek/devel

# Legfrissebb változások letöltése
git pull origin main

# Változások vannak a Dockerfile-ban vagy függőségekben?
# Ha igen, újraépítés szükséges:
docker-compose build
```

### 8.2 Szolgáltatások Újraindítása

```bash
# Leállítás
docker-compose down

# Újraindítás
docker-compose up -d

# Vagy egy lépésben:
docker-compose restart
```

### 8.3 Deploy Scripttel (Ha van)

```bash
cd /opt/nincsenekfenyek/devel
./scripts/update.sh
```

---

## 🔒 9. Biztonsági Beállítások

### 9.1 Docker Group

```bash
# Docker használata sudo nélkül
sudo usermod -aG docker $USER

# Újra be kell jelentkezni a változások érvényesüléséhez!
```

### 9.2 SSL/TLS Beállítás (Ajánlott)

```bash
# Certbot telepítése (Let's Encrypt)
sudo apt-get install certbot python3-certbot-nginx

# SSL tanúsítvány kérése (ha van domain)
sudo certbot --nginx -d your-domain.com
```

---

## 📊 10. Monitoring és Logok

### 10.1 Logok Követése

```bash
# Összes log
docker-compose logs -f

# Csak backend
docker-compose logs -f backend

# Utolsó 100 sor
docker-compose logs --tail=100 backend
```

### 10.2 Szolgáltatások Állapota

```bash
# Részletes állapot
docker-compose ps

# Docker statisztikák
docker stats
```

---

## 🛠️ Hibaelhárítás

### Docker Nem Indul

```bash
# Docker állapot
sudo systemctl status docker

# Újraindítás
sudo systemctl restart docker
```

### Port Foglalt

```bash
# Melyik process használja?
sudo netstat -tlnp | grep :8000
sudo lsof -i :8000

# Process leállítása
sudo kill -9 <PID>
```

### Konténer Nem Indul

```bash
# Logok ellenőrzése
docker-compose logs <service_name>

# Konténer belépés
docker-compose exec <service_name> bash
```

### Tárhely Probléma

```bash
# Docker tárhely
docker system df

# Tisztítás
docker system prune -a
```

---

## 📋 Gyors Referencia

```bash
# Klónozás
cd /opt/nincsenekfenyek
git clone git@github.com:erbnrabbit1987/nincsenekfenyek.git main
git clone git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git devel

# Beállítás
cd devel
cp .env.example .env
nano .env  # Generálj SECRET_KEY-t!

# Build és indítás
docker-compose build
docker-compose up -d

# Ellenőrzés
docker-compose ps
curl http://localhost:8000/health

# Frissítés
git pull
docker-compose build && docker-compose up -d
```

---

## 📚 További Dokumentáció

- [Teljes Deployment Útmutató](./DEPLOYMENT.md)
- [Gyors Összefoglaló](./DEPLOYMENT_SUMMARY.md)
- [Docker Guide](../DOCKER.md)




