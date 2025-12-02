# 🔑 GitHub SSH Kulcs Hozzáadása - Útmutató

## ✅ SSH Kulcs Sikeresen Generálva!

Az SSH kulcs létrehozva és beállítva az ssh-agent-ben.

---

## 📋 Lépésről Lépésre: Hozzáadás a GitHub-hoz

### 1️⃣ Menj a GitHub SSH beállításokhoz

**Kattints ide:** 👉 https://github.com/settings/ssh/new

Vagy manuálisan:
- GitHub.com → Jobb felső sarok → **Settings** (Profil ikon)
- Bal oldali menü → **SSH and GPG keys**
- **New SSH key** gombra kattintás

---

### 2️⃣ Add meg az információkat

#### **Title:**
Írj be egy nevet, pl:
```
MacBook - Nincsenek Fények
```
(vagy bármilyen nevet, amit szeretnél - ez csak a neked szóló azonosító)

#### **Key Type:**
Válaszd ki: **Authentication Key**

#### **Key:**
**Másold be az alábbi teljes sort** (kezdve `ssh-ed25519`-el és végződve az email címmel):

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3UvSNw8jUi/0x/84d/dX+JVXFjEGNlmKs1OKWkXhU6 bazsonyi.work@gmail.com
```

> 💡 **Tipp:** A kulcs már másolva van a vágólapra, csak Ctrl+V (Cmd+V Mac-en)!

---

### 3️⃣ Mentés

Kattints az **"Add SSH key"** gombra

---

## ✅ Ellenőrzés

Miután hozzáadtad, próbáld ki:

```bash
ssh -T git@github.com
```

Ha működik, ezt fogod látni:
```
Hi erbnrabbit1987! You've successfully authenticated, but GitHub does not provide shell access.
```

---

## 📊 Kulcs Információk

- **Típus:** Ed25519
- **Fingerprint:** `SHA256:KubEvhIBEITm3PR/zYkVTeG7rNbPeDOi9vZI8y4VGiY`
- **Email:** bazsonyi.work@gmail.com
- **Hely:** ~/.ssh/id_ed25519 (privát kulcs)
- **Publikus kulcs:** ~/.ssh/id_ed25519.pub

---

## 🚀 Utána: Push a Kódhoz

Miután hozzáadtad a kulcsot, pushold fel a kódot:

```bash
git push -u origin main
```

---

**Készen vagy!** 🎉
