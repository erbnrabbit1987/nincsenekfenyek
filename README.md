# Nincsenek Fények! - Development Repository

Ez a repository tartalmazza a **Nincsenek Fények!** alkalmazás teljes forráskódját és futtatásához szükséges fájlokat.

> **Fontos:** Ez a repository csak a forráskódot tartalmazza. A dokumentáció a fő repository-ban található.

## Build és Futtatás

### Interaktív Build Script

A projekt tartalmaz egy interaktív build scriptet, amely segít a telepítésben és tesztelésben:

```bash
./scripts/build.sh
```

A script interaktívan vezet végig az alábbi lépéseken:
1. Előfeltételek ellenőrzése
2. Virtual environment beállítása
3. Dependencies telepítése
4. Docker build (opcionális)
5. Code lint és formázás (opcionális)
6. Tesztek futtatása (opcionális)

**Build módok:**
- Teljes build (Docker + dependencies)
- Csak Python dependencies
- Csak Docker build
- Tesztelés futtatása
- Lint és formázás
- Minden (teljes build + tesztek + lint)

### Manuális Telepítés

## Gyors Kezdés

### Előfeltételek

- Docker és Docker Compose telepítve
- Git

### Telepítés

1. **Repository klónozása:**
```bash
git clone git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git
cd nincsenekfenyek-devel
```

2. **Környezeti változók beállítása:**
```bash
cp .env.example .env
# Szerkeszd a .env fájlt a szükséges értékekkel
```

3. **Docker konténerek indítása:**
```bash
docker-compose up -d
```

## Projekt Struktúra

```
devel/
├── src/              # Backend forráskód
├── tests/            # Tesztek
├── scripts/          # Utility scriptek
├── migrations/       # DB migrációk
├── frontend/         # Frontend (ha lesz)
├── docker-compose.yml
├── Dockerfile
└── requirements.txt
```

## Dokumentáció

A teljes dokumentáció a fő repository-ban található:
- https://github.com/erbnrabbit1987/nincsenekfenyek

## Licenc

[Majd később meghatározandó]
