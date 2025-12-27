# 🐳 Docker Build Segfault Troubleshooting

## Segfault (Exit Code 139) Problémák

### Probléma Leírás

Docker build során segfault (segmentation fault, exit code 139) hibák történnek, különösen:
- `torch` telepítése során
- `langdetect` telepítése során  
- `beautifulsoup4` telepítése során
- Más nagy csomagok telepítése során

### Okok

1. **Memória limit túllépés** - A Docker build során nincs elegendő memória
2. **Python 3.11 kompatibilitás** - Néhány csomag még nem teljesen kompatibilis
3. **setuptools verzió probléma** - Modern setuptools verziók problémákat okozhatnak

---

## Megoldások

### 1. Docker Build Memória Limit Növelése

```bash
# Docker build memória limit beállítása
docker build --memory=4g --memory-swap=4g .

# Vagy Docker daemon config módosítása
# /etc/docker/daemon.json:
{
  "default-ulimits": {
    "memlock": {
      "hard": -1,
      "soft": -1
    }
  }
}
```

### 2. Python Verzió Váltás

Ha a segfault továbbra is fennáll, próbáld meg Python 3.10-et:

```dockerfile
FROM python:3.10-slim
```

### 3. Csomagok Opcionálissá Tétele

A Dockerfile már tartalmazza, hogy néhány csomag opcionális:

- `langdetect` - Teljes mértékben kihagyva (spaCy fallback)
- `torch` - Kihagyva (transformers CPU fallback használ)
- Testing és Code Quality csomagok - Opcionális

### 4. Telepítés Lépésről Lépésre

A jelenlegi Dockerfile már telepíti a csomagokat kisebb csoportokban:

1. Core dependencies
2. Database dependencies  
3. Cache & Queue
4. HTTP clients
5. Auth & Security
6. Web scraping (opcionális fallback)
7. NLP (langdetect nélkül, opcionális fallback)
8. Utilities
9. Testing (opcionális)
10. Code quality (opcionális)

### 5. Egyenkénti Telepítés (Legkonzervatívabb)

Ha még mindig probléma van, telepítsd egyenként:

```dockerfile
RUN pip install --no-cache-dir fastapi==0.104.1
RUN pip install --no-cache-dir uvicorn[standard]==0.24.0
# ... stb.
```

---

## Aktuális Dockerfile Stratégia

A jelenlegi Dockerfile használja:

1. **Csomagcsoportokban telepítés** - Csökkenti a memória igényt
2. **Opcionális csomagok** - Testing és code quality esetleg kihagyható
3. **Fallback logika** - Ha egy csomagcsoport hibázik, a többi folytatódik
4. **setuptools <70** - Kompatibilitási javítás

---

## Debug Lépések

### 1. Docker Build Logok Részletes Megtekintése

```bash
docker build --progress=plain --no-cache -t nincsenekfenyek .
```

### 2. Build Folyamat Megfigyelése

```bash
# Docker build futtatása verbose módban
docker build --progress=plain . 2>&1 | tee build.log

# Hiba pontos helyének megtalálása
grep -B 10 "Segmentation fault" build.log
```

### 3. Memória Használat Ellenőrzése

```bash
# Memória használat build során
docker stats --no-stream

# Vagy build során monitor
watch -n 1 'docker stats --no-stream'
```

### 4. Alternatív Base Image Kipróbálása

```dockerfile
# Python 3.10 próbálása
FROM python:3.10-slim

# Vagy debian-slim
FROM python:3.11-slim-bullseye
```

---

## Jelenlegi Munkaaround

A Dockerfile-ban a következő megoldások vannak implementálva:

1. ✅ **torch eltávolítva** - Nem települ, transformers CPU fallback-tel működik
2. ✅ **langdetect kihagyva** - spaCy fallback használata
3. ✅ **Csomagcsoportokban telepítés** - Csökkenti memória igényt
4. ✅ **Opcionális csomagok** - Testing és code quality kihagyható
5. ✅ **setuptools <70** - Kompatibilitási javítás

---

## Ha Még Mindig Nem Működik

### Opció 1: Build Futtatása Több Memóriával

```bash
# Docker Desktop beállítások
# Settings > Resources > Memory: 4GB+

# Vagy Linux-on
docker build --memory=4g .
```

### Opció 2: Python 3.10 Használata

Módosítsd a Dockerfile első sorát:
```dockerfile
FROM python:3.10-slim
```

### Opció 3: Multi-stage Build

```dockerfile
# Stage 1: Builder
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY src/ ./src/
ENV PATH=/root/.local/bin:$PATH
```

### Opció 4: Minimal Requirements

Hozz létre egy `requirements-minimal.txt` fájlt csak a legfontosabb csomagokkal:

```txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
python-dotenv==1.0.0
pymongo==4.6.0
motor==3.3.2
redis==5.0.1
celery==5.3.4
spacy==3.7.2
```

És használd ezt a production build-hez.

---

## Ellenőrzés

Build után ellenőrizd:

```bash
# Image ellenőrzése
docker images | grep nincsenekfenyek

# Konténer indítása és tesztelés
docker run --rm -it nincsenekfenyek python -c "import fastapi; print('OK')"
```

---

**Utolsó frissítés:** 2024. december 26.  
**Status:** ✅ Segfault megoldások implementálva


