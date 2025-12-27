# 🚀 Push-olás a Sandbox Konzolból

## ✅ Sikeresen beállítva!

A sandbox konzolból most már lehet pusholni a GitHub repository-ba.

---

## 🛠️ Használható Scriptek

### 1. `setup-and-push.sh` - Első Push

**Használat:** Új repository vagy első push esetén

```bash
cd /Users/bazsika/Git/devel-nincsenekfenyek
./scripts/setup-and-push.sh
```

**Mit csinál:**
- ✅ SSH kapcsolat ellenőrzése
- ✅ Repository létezés ellenőrzése
- ✅ Branch beállítása (main)
- ✅ Push végrehajtása

**Ha a repository nem létezik:**
- Megmutatja, hogy hogyan hozd létre a GitHub-on
- Várakozik, amíg létrehoztad
- Ezután automatikusan pushol

---

### 2. `commit-push.sh` - Commit és Push

**Használat:** Normál commit és push

```bash
cd /Users/bazsika/Git/devel-nincsenekfenyek
./scripts/commit-push.sh "Commit üzenet"
```

**Mit csinál:**
- ✅ Status ellenőrzése
- ✅ Változások hozzáadása (`git add -A`)
- ✅ Commit (`git commit -m "üzenet"`)
- ✅ Push (`git push origin main`)

**Példa:**
```bash
./scripts/commit-push.sh "feat: Add new feature"
```

---

### 3. `push-only.sh` - Csak Push

**Használat:** Ha már van commit, csak push kell

```bash
cd /Users/bazsika/Git/devel-nincsenekfenyek
./scripts/push-only.sh
```

**Mit csinál:**
- ✅ Push végrehajtása (feltételezi, hogy már van commit)

---

### 4. `git-clean.sh` - Clean Git Parancsok

**Használat:** Bármilyen git parancs shell hibák nélkül

```bash
cd /Users/bazsika/Git/devel-nincsenekfenyek
./scripts/git-clean.sh status
./scripts/git-clean.sh log --oneline -5
./scripts/git-clean.sh diff
```

**Mit csinál:**
- ✅ Elnyomja a shell hibákat (`base64`, `dump_zsh_state`)
- ✅ Futtatja a git parancsot
- ✅ Tiszta output-ot ad

---

## 📋 Gyors Referencia

### Első alkalommal

```bash
cd /Users/bazsika/Git/devel-nincsenekfenyek
./scripts/setup-and-push.sh
```

### Normál workflow

```bash
cd /Users/bazsika/Git/devel-nincsenekfenyek

# 1. Módosítások megtekintése
./scripts/git-clean.sh status

# 2. Commit és push
./scripts/commit-push.sh "feat: Description"

# VAGY csak push (ha már van commit)
./scripts/push-only.sh
```

---

## ✅ Sikeres Push Példa

```bash
$ ./scripts/setup-and-push.sh

╔════════════════════════════════════════════════════════════╗
║  Repository Setup és Push                                  ║
╚════════════════════════════════════════════════════════════╝

Remote: git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git

[1/4] SSH kapcsolat ellenőrzése...
✓ SSH kapcsolat OK

[2/4] Repository létezés ellenőrzése...
✓ Repository létezik: erbnrabbit1987/nincsenekfenyek-devel

[3/4] Branch ellenőrzése...
✓ Branch: main

[4/4] Push-olás...
✓ Push sikeres!

╔════════════════════════════════════════════════════════════╗
║  ✓ Repository sikeresen feltöltve a GitHub-ra!            ║
╚════════════════════════════════════════════════════════════╝

Repository URL: https://github.com/erbnrabbit1987/nincsenekfenyek-devel
```

---

## 🔧 Hibaelhárítás

### "Repository not found"

**Probléma:** A GitHub repository még nincs létrehozva.

**Megoldás:**
1. Menj a https://github.com/new oldalra
2. Repository neve: `nincsenekfenyek-devel`
3. Privát: Igen (ajánlott)
4. **NE** inicializáld README-mel, .gitignore-gel vagy licenccel
5. Kattints "Create repository"
6. Futtasd újra: `./scripts/setup-and-push.sh`

---

### "Permission denied (publickey)"

**Probléma:** SSH kulcs probléma.

**Megoldás:**
```bash
# SSH kapcsolat tesztelése
ssh -T git@github.com

# SSH agent indítása és kulcs hozzáadása
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Vagy HTTPS használata (ha SSH nem működik)
git remote set-url origin https://github.com/erbnrabbit1987/nincsenekfenyek-devel.git
```

**Részletes útmutató:** `docs/PUSH_GUIDE.md`

---

### "Operation not permitted"

**Probléma:** Sandbox korlátozások.

**Megoldás:** A scriptek automatikusan elnyomják ezeket a hibákat. Ha mégis problémád van, használd a scripteket (`git-clean.sh`, `commit-push.sh`), nem közvetlenül a `git` parancsot.

---

## 📚 További Dokumentáció

- **PUSH_GUIDE.md** - Részletes push útmutató
- **CURSOR_GIT_SETUP.md** - Cursor IDE Git beállítás
- **CHECKPOINT.md** - Projekt checkpoint dokumentáció

---

## 🎯 Gyors Példák

### Új feature commit és push

```bash
./scripts/commit-push.sh "feat: Add Google Search API integration"
```

### Bugfix commit és push

```bash
./scripts/commit-push.sh "fix: Fix Facebook scraper rate limiting"
```

### Dokumentáció frissítés commit és push

```bash
./scripts/commit-push.sh "docs: Update checkpoint documentation"
```

### Csak push (ha már van commit)

```bash
./scripts/push-only.sh
```

---

**Utolsó frissítés:** 2024. december 26.  
**Status:** ✅ Sandbox konzolból push működik!

