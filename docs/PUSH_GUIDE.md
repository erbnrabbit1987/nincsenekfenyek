# Git Push Útmutató

## Push-olás a GitHub-ra

### 1. Előfeltételek ellenőrzése

#### A. Remote repository beállítása

```bash
cd /Users/bazsika/Git/devel-nincsenekfenyek

# Ellenőrizd a remote beállításokat
./scripts/git-clean.sh remote -v
```

**Elvárt kimenet:**
```
origin  git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git (fetch)
origin  git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git (push)
```

Ha nincs remote beállítva:
```bash
./scripts/git-clean.sh remote add origin git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git
```

#### B. SSH kulcs ellenőrzése

```bash
# SSH kulcs tesztelése
ssh -T git@github.com
```

**Elvárt kimenet:**
```
Hi erbnrabbit1987! You've successfully authenticated, but GitHub does not provide shell access.
```

Ha hibát kapsz, lásd: [SSH kulcs beállítása](#ssh-kulcs-beállítása)

---

## 2. Push-olás Lépések

### Módszer 1: commit-push.sh script (Ajánlott)

```bash
cd /Users/bazsika/Git/devel-nincsenekfenyek

# Commit és push egy lépésben
./scripts/commit-push.sh "feat: Your commit message"
```

### Módszer 2: Manuális push

```bash
cd /Users/bazsika/Git/devel-nincsenekfenyek

# 1. Status ellenőrzés
./scripts/git-status-clean.sh

# 2. Változások hozzáadása (ha vannak)
./scripts/git-clean.sh add .

# 3. Commit (ha vannak változások)
./scripts/git-clean.sh commit -m "feat: Your commit message"

# 4. Push
./scripts/git-clean.sh push origin main
```

### Módszer 3: Ha nincs commitolva

```bash
cd /Users/bazsika/Git/devel-nincsenekfenyek

# Teljes workflow
./scripts/git-clean.sh add -A
./scripts/git-clean.sh commit -m "feat: Your changes"
./scripts/git-clean.sh push origin main
```

---

## 3. SSH Kulcs Beállítása

Ha a push nem működik SSH kulcs probléma miatt:

### A. Ellenőrizd, hogy van-e SSH kulcsod

```bash
ls -la ~/.ssh/id_*
```

### B. Ha nincs SSH kulcs, generálj egyet

```bash
# Ed25519 kulcs generálása (ajánlott)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Vagy RSA kulcs (ha ed25519 nem támogatott)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

### C. SSH kulcs hozzáadása az ssh-agenthez

```bash
# ssh-agent indítása
eval "$(ssh-agent -s)"

# Kulcs hozzáadása
ssh-add ~/.ssh/id_ed25519
# vagy
ssh-add ~/.ssh/id_rsa
```

### D. Nyilvános kulcs másolása

```bash
# Nyilvános kulcs megjelenítése
cat ~/.ssh/id_ed25519.pub
# vagy
cat ~/.ssh/id_rsa.pub
```

### E. Kulcs hozzáadása GitHub-hoz

1. Másold ki a nyilvános kulcsot (a `cat` parancs kimenete)
2. Menj a GitHub-ra: https://github.com/settings/keys
3. Kattints "New SSH key"
4. Illeszd be a kulcsot
5. Kattints "Add SSH key"

### F. Teszteld a kapcsolatot

```bash
ssh -T git@github.com
```

**Elvárt kimenet:**
```
Hi erbnrabbit1987! You've successfully authenticated...
```

---

## 4. Gyakori Hibák és Megoldások

### Hiba: "Permission denied (publickey)"

**Megoldás:**
1. Ellenőrizd az SSH kulcsot: `ssh -T git@github.com`
2. Ha nem működik, add hozzá a kulcsot az ssh-agenthez:
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```
3. Vagy használj HTTPS-t (Personal Access Token szükséges)

### Hiba: "fatal: Could not read from remote repository"

**Lehetséges okok:**
- SSH kulcs nincs beállítva
- Remote URL rossz
- Nincs jogosultság a repository-hoz

**Megoldás:**
```bash
# Remote URL ellenőrzése
./scripts/git-clean.sh remote -v

# Ha rossz, javítsd:
./scripts/git-clean.sh remote set-url origin git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git
```

### Hiba: "non-fast-forward"

**Ok:** A remote repository-ban vannak változások, amiket még nem húztál le.

**Megoldás:**
```bash
# Először pull (merge)
./scripts/git-clean.sh pull origin main

# Vagy pull rebase-szel
./scripts/git-clean.sh pull --rebase origin main

# Aztán push
./scripts/git-clean.sh push origin main
```

---

## 5. HTTPS Használata (Alternatíva)

Ha SSH nem működik, használhatsz HTTPS-t is:

### Remote átállítása HTTPS-re

```bash
./scripts/git-clean.sh remote set-url origin https://github.com/erbnrabbit1987/nincsenekfenyek-devel.git
```

### Personal Access Token

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. "Generate new token"
3. Adj jogosultságokat (repo scope)
4. Másold ki a tokent
5. Push-oláskor használd a tokent jelszónak (username: GitHub username)

---

## 6. Gyors Push Script

Egyelőre csak commit esetén:

```bash
# scripts/push-only.sh
#!/bin/bash
cd /Users/bazsika/Git/devel-nincsenekfenyek
./scripts/git-clean.sh push origin main
```

Használat:
```bash
chmod +x scripts/push-only.sh
./scripts/push-only.sh
```

---

## 7. Ellenőrzés

Push után ellenőrizd a GitHub-on:
- Repository: https://github.com/erbnrabbit1987/nincsenekfenyek-devel
- Commits: Ellenőrizd, hogy megjelentek-e az új commitok

---

**Hasznos linkek:**
- [GitHub SSH kulcs dokumentáció](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [Personal Access Token](https://github.com/settings/tokens)


