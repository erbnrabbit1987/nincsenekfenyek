# 🚀 Push-olás Gyors Útmutató

## Push-olás 3 módszerrel

### 1️⃣ Commit + Push egy lépésben (Ajánlott)

```bash
cd /Users/bazsika/Git/devel-nincsenekfenyek
./scripts/commit-push.sh "feat: Your commit message"
```

### 2️⃣ Csak Push (ha már van commit)

```bash
cd /Users/bazsika/Git/devel-nincsenekfenyek
./scripts/push-only.sh
```

### 3️⃣ Manuális Push

```bash
cd /Users/bazsika/Git/devel-nincsenekfenyek
./scripts/git-clean.sh push origin main
```

---

## ⚠️ SSH Kulcs Probléma?

Ha a push nem működik, próbáld:

### A. SSH kulcs aktiválása

```bash
# ssh-agent indítása
eval "$(ssh-agent -s)"

# Kulcs hozzáadása
ssh-add ~/.ssh/id_ed25519

# Teszt
ssh -T git@github.com
```

### B. Vagy használj HTTPS-t

```bash
# Remote átállítása HTTPS-re
./scripts/git-clean.sh remote set-url origin https://github.com/erbnrabbit1987/nincsenekfenyek-devel.git

# Push (kérdi a username és password/token-t)
./scripts/git-clean.sh push origin main
```

---

## 📚 Részletes útmutató

Lásd: `docs/PUSH_GUIDE.md`

---

**Most próbáld ki:**

```bash
./scripts/push-only.sh
```


