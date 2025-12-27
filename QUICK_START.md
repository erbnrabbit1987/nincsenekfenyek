# 🚀 Gyors Kezdés - Git Commits Cursor-ban

## ✅ Probléma megoldva!

A shell hibák (`base64`, `dump_zsh_state`) elnyomva scriptekkel.

## 📋 Használat

### 1. **Status ellenőrzés (hibák nélkül):**
```bash
./scripts/git-status-clean.sh
```

### 2. **Commit és Push (egy lépésben):**
```bash
./scripts/commit-push.sh "feat: Your commit message"
```

### 3. **Egyedi git parancsok:**
```bash
./scripts/git-clean.sh status
./scripts/git-clean.sh add .
./scripts/git-clean.sh commit -m "Message"
./scripts/git-clean.sh push origin main
```

## 📝 Példa Workflow

```bash
# 1. Status ellenőrzés
./scripts/git-status-clean.sh

# 2. Változások hozzáadása
./scripts/git-clean.sh add .

# 3. Commit és push
./scripts/commit-push.sh "feat: Add new feature"
```

Vagy minden egy lépésben:
```bash
./scripts/commit-push.sh "fix: Update documentation"
```

## 📚 További információk

- **Részletes útmutató:** `README_CURSOR.md`
- **Részletes setup:** `docs/CURSOR_GIT_SETUP.md`

---

**Készen állsz!** 🎉


