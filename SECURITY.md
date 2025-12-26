# 🔒 Biztonsági Irányelvek

## ⚠️ FONTOS: Ne Commitolj Bizalmas Adatokat!

Ez a repository **SOHA** ne tartalmazza:

### ❌ Amit SOHA nem szabad commitolni:

1. **SSH Kulcsok**
   - `~/.ssh/id_rsa` (privát kulcs)
   - `~/.ssh/id_ed25519` (privát kulcs)
   - Bármilyen privát SSH kulcs
   - ⚠️ Publikus kulcsok (`*.pub`) sem kerüljenek be, ha nem szükségesek

2. **Környezeti Változók**
   - `.env` fájlok
   - `.env.local`, `.env.production`, stb.
   - ✅ Csak `.env.example` lehet benne (minta fájl)

3. **API Kulcsok és Tokenek**
   - GitHub Personal Access Tokens
   - Facebook API kulcsok
   - Database jelszavak
   - Redis jelszavak
   - Bármilyen secret/token fájl

4. **Tanúsítványok**
   - `*.pem` fájlok
   - `*.key` fájlok
   - `*.crt` fájlok
   - SSL/TLS tanúsítványok

5. **Adatbázis Dumpok**
   - `*.sql` fájlok (ha tartalmaznak éles adatokat)
   - Backup fájlok

## ✅ Amit lehet commitolni:

- `.env.example` - Minta fájl placeholder értékekkel
- `README.md` - Dokumentáció (ne tartalmazzon kulcsokat!)
- Nyilvános konfigurációs fájlok (minta értékekkel)

## 🔍 Ellenőrzés Commit Előtt

**MINDIG futtasd a check scriptet commit előtt:**

```bash
./scripts/check-secrets.sh
```

Ez ellenőrzi, hogy nincs-e bizalmas információ a repository-ban.

## 🛡️ .gitignore

A `.gitignore` fájl már tartalmazza a bizalmas fájltípusokat:
- SSH kulcsok
- .env fájlok
- Secret fájlok
- Credential fájlok

**Ne módosítsd a .gitignore-t úgy, hogy bizalmas fájlokat engedélyezzen!**

## 🚨 Ha Véletlenül Commitoltál Bizalmas Adatot

1. **AZONNAL töröld a fájlt a repository-ból:**
   ```bash
   git rm --cached <file>
   git commit -m "Remove sensitive data"
   ```

2. **Változtasd meg az érintett kulcsokat/tokeneket:**
   - GitHub token újragenerálása
   - API kulcsok újragenerálása
   - Jelszavak változtatása

3. **Git history törlés (ha szükséges):**
   ```bash
   # VIGYÁZAT: Ez változtatja a git history-t!
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch <file>" \
     --prune-empty --tag-name-filter cat -- --all
   ```

## 📝 Best Practices

1. **Használj `.env` fájlokat** - Ezek soha ne kerüljenek verziókezelésbe
2. **Használj `.env.example`** - Minta fájl placeholder értékekkel
3. **Ellenőrizz commit előtt** - `./scripts/check-secrets.sh`
4. **Ne hardcode-olt értékeket** - Mindig környezeti változókat használj
5. **Code review** - Mások is ellenőrizzék a változásokat

## 🔐 Jelenlegi Biztonsági Beállítások

✅ `.gitignore` tartalmazza a bizalmas fájltípusokat
✅ `check-secrets.sh` script ellenőrzéshez
✅ `.env.example` mintaként (nem tartalmaz valós értékeket)

---

**Fontos:** Ha bármilyen bizalmas információ kerülne a repository-ba, azonnal értesítsd a projekt maintainerét!



