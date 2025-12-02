# Development Repository (devel) Beállítás

## Áttekintés

A projekt két repository-ból áll:
- **Main repository** (`nincsenekfenyek`): Csak dokumentációk
- **Development repository** (`nincsenekfenyek-devel`): Teljes forráskód és futtatási fájlok

---

## Lokális Beállítás (Fejlesztői Gép)

### 1. Development Repository Létrehozása

A development repository lokálisan már létre van hozva:
- Hely: `/Users/bazsika/Git/devel-nincsenekfenyek`
- Tartalom: Teljes forráskód, Docker fájlok, scriptek

### 2. GitHub Repository Létrehozása

1. Menj a GitHub-ra: https://github.com/new
2. Repository neve: `nincsenekfenyek-devel`
3. **Privát** repository ajánlott
4. **Ne** inicializáld README-mel, .gitignore-gel vagy licenccel
5. Kattints "Create repository"

### 3. Remote Beállítása és Push

```bash
cd /Users/bazsika/Git/devel-nincsenekfenyek

# Remote hozzáadása
git remote add origin git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git

# Push
git branch -M main
git push -u origin main
```

### 4. Submodule Hozzáadása a Main Repository-hoz (Opcionális)

```bash
cd /Users/bazsika/Git/nincsenekfenyek

# Submodule hozzáadása
git submodule add -b main git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git devel

# Commitolás
git add .gitmodules devel
git commit -m "feat: Add devel submodule for source code"
```

---

## Linux Szerveren - Repository Klónozása

### Opció A: Külön Repository-ként (Ajánlott)

```bash
# Munkakönyvtár
mkdir -p /opt/nincsenekfenyek
cd /opt/nincsenekfenyek

# Main repository (dokumentáció)
git clone git@github.com:erbnrabbit1987/nincsenekfenyek.git main

# Development repository (kód)
git clone git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git devel

# Development könyvtárba lépés
cd devel
```

### Opció B: Submodule-ként

```bash
# Munkakönyvtár
mkdir -p /opt/nincsenekfenyek
cd /opt/nincsenekfenyek

# Main repository klónozása
git clone git@github.com:erbnrabbit1987/nincsenekfenyek.git main
cd main

# Submodule-ök inicializálása és klónozása
git submodule update --init --recursive

# Development könyvtárba lépés
cd devel
```

---

## Használat

### Fejlesztés

A fejlesztés a `devel` repository-ban történik:

```bash
cd /opt/nincsenekfenyek/devel
# VAGY
cd /Users/bazsika/Git/devel-nincsenekfenyek

# Kód módosítása
# ...

# Commit és push
git add .
git commit -m "feat: New feature"
git push origin main
```

### Szerveren Frissítés

```bash
cd /opt/nincsenekfenyek/devel

# Kód frissítése
git pull origin main

# Ha változások vannak Docker fájlokban
docker-compose build

# Újraindítás
docker-compose down
docker-compose up -d
```

---

## Repository Struktúra

```
devel/
├── src/                    # Backend forráskód
│   ├── api/               # API routes
│   ├── config/            # Konfiguráció
│   ├── models/            # Adatmodell
│   ├── services/          # Business logika
│   └── ...
├── tests/                  # Tesztek
├── scripts/                # Utility scriptek
├── migrations/             # DB migrációk
├── frontend/               # Frontend (ha lesz)
├── docker-compose.yml      # Docker Compose config
├── Dockerfile              # Backend Docker image
├── requirements.txt        # Python dependencies
└── README.md               # Repository leírás
```

---

## További Információ

- [Linux Szerver Deployment](./DEPLOYMENT.md)
- [Deployment Összefoglaló](./DEPLOYMENT_SUMMARY.md)
- [Server Setup Lépések](./SERVER_SETUP_STEPS.md)

