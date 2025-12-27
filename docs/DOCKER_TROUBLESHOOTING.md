# 🐳 Docker Build Troubleshooting

## Problémák és Megoldások

### 1. dpkg State Corruption Error

**Hibaüzenet:**
```
dpkg: error: parsing file '/var/lib/dpkg/status' near line 713
E: Sub-process /usr/bin/dpkg returned an error code (2)
```

**Ok:** A Docker image cache-ben vagy a base image-ben sérült dpkg állapot fájl.

**Megoldás:**

1. **Dockerfile javítása** (már javítva):
```dockerfile
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*
```

2. **Docker cache törlése:**
```bash
docker system prune -a
docker build --no-cache .
```

3. **Ha még mindig nem működik, base image frissítés:**
```bash
docker pull python:3.11-slim
docker build --no-cache .
```

---

### 2. Build Cache Problémák

**Probléma:** Régi cache miatt nem frissülnek a csomagok.

**Megoldás:**
```bash
# Build cache nélkül
docker compose build --no-cache

# Vagy csak egy service rebuild
docker compose build --no-cache backend
```

---

### 3. Network/Proxy Problémák

**Probléma:** Csomagok letöltése nem működik.

**Megoldás - Dockerfile-ban proxy beállítás:**
```dockerfile
# Proxy beállítás (ha szükséges)
ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}

RUN apt-get update && ...
```

**Build proxy-val:**
```bash
docker build --build-arg HTTP_PROXY=http://proxy:port .
```

---

### 4. Out of Space

**Hibaüzenet:**
```
no space left on device
```

**Megoldás:**
```bash
# Docker rendszer tisztítása
docker system prune -a

# Unused images törlése
docker image prune -a

# Volumes törlése (VIGYÁZAT: adatvesztés!)
docker volume prune
```

---

### 5. Permission Denied

**Hibaüzenet:**
```
permission denied while trying to connect to Docker daemon
```

**Megoldás:**
```bash
# Docker csoport ellenőrzése
groups

# Felhasználó hozzáadása docker csoporthoz
sudo usermod -aG docker $USER

# Újra bejelentkezés szükséges
newgrp docker
```

---

### 6. Python Dependencies Install Error

**Hibaüzenet:**
```
ERROR: Could not find a version that satisfies the requirement ...
```

**Megoldás:**

1. **requirements.txt ellenőrzése:**
```bash
# Frissítsd a pip-et
pip install --upgrade pip setuptools wheel

# Próbáld meg manuálisan telepíteni
pip install -r requirements.txt
```

2. **Dockerfile-ban pip frissítés:**
```dockerfile
RUN pip install --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt
```

---

### 7. Port Already in Use

**Hibaüzenet:**
```
Error response from daemon: failed to set up container networking: 
driver failed programming external connectivity on endpoint nincsenekfenyek-backend: 
Bind for :::8095 failed: port is already allocated
```

**Automatikus megoldás:**
A deploy script most automatikusan ellenőrzi és felszabadítja a foglalt portokat:
```bash
./scripts/deploy.sh
```

A script automatikusan:
1. Ellenőrzi a szükséges portokat (8095, 27017, 5432, 6379)
2. Megkeresi a portokat használó konténereket
3. Leállítja és eltávolítja őket
4. Folytatja a deployment-et

**Manuális megoldás:**
Ha az automatikus megoldás nem működik:

1. **Port használat ellenőrzése:**
```bash
# Port használat ellenőrzése
sudo lsof -i :8095
# vagy
sudo netstat -tulpn | grep :8095
# vagy
sudo ss -tulpn | grep :8095

# Docker konténerek port használattal
docker ps --filter "publish=8095"
```

2. **Konténer leállítása és törlése:**
```bash
# Megtalálni a konténert
docker ps -a | grep nincsenekfenyek

# Leállítani és törölni
docker stop <container-name>
docker rm -f <container-name>

# Vagy minden projekt konténer egyszerre
docker ps -a --filter "name=nincsenekfenyek" -q | xargs -r docker rm -f
```

3. **Alternatíva: Port módosítása docker-compose.yml-ban:**
```yaml
ports:
  - "8096:8095"  # Másik port használata host oldalon
```

4. **Folyamat kilövése (utolsó esetben):**
```bash
# Folyamat PID megtalálása
sudo lsof -ti :8095

# Kilövése
sudo kill -9 <PID>
```

---

## Hasznos Parancsok

### Build és Deploy
```bash
# Clean build
docker compose build --no-cache

# Rebuild egy service
docker compose build --no-cache backend

# Build és start
docker compose up --build -d

# Logs
docker compose logs -f backend
```

### Debugging
```bash
# Konténer belépés
docker compose exec backend bash

# Python shell
docker compose exec backend python

# Futtatás build nélkül (ha van local Python)
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Cleanup
```bash
# Összes leállítás és törlés
docker compose down -v

# Docker system cleanup
docker system prune -a

# Unused images
docker image prune -a
```

---

## Best Practices

1. **Mindig töröld az apt lists-t a build után:**
```dockerfile
RUN apt-get update && apt-get install -y ... && rm -rf /var/lib/apt/lists/*
```

2. **Használj --no-install-recommends flaget:**
```dockerfile
RUN apt-get install -y --no-install-recommends ...
```

3. **Docker layer caching optimalizálás:**
```dockerfile
# Először requirements (ritkán változik)
COPY requirements.txt .
RUN pip install -r requirements.txt

# Utána code (gyakran változik)
COPY src/ ./src/
```

4. **Multi-stage build használata nagyobb projektekhez:**
```dockerfile
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY src/ ./src/
ENV PATH=/root/.local/bin:$PATH
```

---

**Utolsó frissítés:** 2024. december 26.


