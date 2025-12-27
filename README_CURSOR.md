# Cursor Git Használat - Gyors útmutató

## Probléma

Cursor-ban git parancsok futtatásakor ezek a hibák jelennek meg:
```
/usr/bin/base64: line 136: /dev/stdout: Operation not permitted
zsh:1: command not found: dump_zsh_state
```

**Ezek a hibák nem akadályozzák a git működését**, csak zavaróak.

## 🚀 Gyors Megoldás (Ajánlott)

### 1. Használd a commit-push scriptet:

```bash
# Változások hozzáadása, commit és push egy lépésben
./scripts/commit-push.sh "feat: Your commit message"
```

### 2. Vagy használd a clean git scriptet:

```bash
# Git status hibák nélkül
./scripts/git-status-clean.sh

# Bármely git parancs hibák nélkül
./scripts/git-clean.sh status
./scripts/git-clean.sh add .
./scripts/git-clean.sh commit -m "Your message"
./scripts/git-clean.sh push origin main
```

## 📝 Alapvető Git Parancsok Cursor-ban

### Status ellenőrzés (hibák nélkül):
```bash
./scripts/git-status-clean.sh
```

### Változások hozzáadása:
```bash
./scripts/git-clean.sh add .
# vagy konkrét fájlok:
./scripts/git-clean.sh add src/ scripts/
```

### Commit:
```bash
./scripts/git-clean.sh commit -m "feat: Description of changes"
```

### Push:
```bash
./scripts/git-clean.sh push origin main
```

### Teljes workflow (egy lépésben):
```bash
./scripts/commit-push.sh "feat: Add new feature"
```

## 🔧 Alternatív Megoldások

### Megoldás 1: Source a suppress scriptet

A terminálban (egy session-ön keresztül működik):

```bash
source .giterrors-suppress.sh
# Ez után a git parancsok automatikusan elnyomják a hibákat
git status
git add .
git commit -m "Your message"
```

### Megoldás 2: Bash használata

Ha bash-t használsz, a hibák nem jelennek meg:

```bash
bash
git status
```

### Megoldás 3: Git Alias (ha működik)

Ha sikerül beállítani a git configot:

```bash
git config --local include.path .gitconfig.local
git status-clean  # alias használata
```

## 📚 További Információ

- **Részletes útmutató:** `docs/CURSOR_GIT_SETUP.md`
- A hibák a shell konfigurációból (oh-my-zsh, prompt) jönnek
- Nem akadályozzák a git működését
- A legjobb megoldás: használd a `commit-push.sh` scriptet

## 💡 Tippek

1. **Gyors commit:** Használd a `commit-push.sh` scriptet mindig
2. **Status ellenőrzés:** `./scripts/git-status-clean.sh` 
3. **Egyedi git parancsok:** `./scripts/git-clean.sh <git-command>`

---

**Fontos:** Minden script elérhető a `scripts/` mappában, és készen áll a használatra!


