# Tesztelési Scriptek Dokumentáció

## Áttekintés

Ez a dokumentum leírja a tesztelési folyamathoz kapcsolódó scripteket és azok használatát.

## Scriptek

### 1. create_test_issues.sh

Ez a script a `docs/TEST_CASES_ISSUES.md` fájl alapján létrehozza az összes tesztesetet Git issue-ként a GitHub-on.

**Használat:**
```bash
./scripts/create_test_issues.sh
```

**Funkciók:**
- Automatikusan kinyeri a teszteseteket a dokumentációból
- Létrehozza a szükséges címkéket (ha még nincsenek)
- Ellenőrzi, hogy mely tesztesetek léteznek már
- Létrehozza az új teszteseteket issue-ként
- Automatikus címkézés (prioritás, típus, modul)

**Előfeltételek:**
- GitHub CLI (gh) telepítve és bejelentkezve
- `docs/TEST_CASES_ISSUES.md` fájl létezik

**Példa:**
```bash
# Ellenőrzés és létrehozás
./scripts/create_test_issues.sh

# A script interaktívan kérdezi, hogy folytassa-e
```

---

### 2. upload_issue_templates.sh

Ez a script segít feltölteni az issue template-eket a GitHub-ra.

**Használat:**
```bash
./scripts/upload_issue_templates.sh
```

**Funkciók:**
- Ellenőrzi a template fájlokat
- Segít commitolni és pusholni a template-eket
- A GitHub automatikusan felismeri a `.github/ISSUE_TEMPLATE/` könyvtárban lévő fájlokat

**Előfeltételek:**
- GitHub CLI (gh) telepítve és bejelentkezve
- Template fájlok a `.github/ISSUE_TEMPLATE/` könyvtárban

**Példa:**
```bash
./scripts/upload_issue_templates.sh
```

**Megjegyzés:** A template-eket Git-en keresztül kell feltölteni. A script segít ebben.

---

## Issue Template-ek

Az issue template-ek a `.github/ISSUE_TEMPLATE/` könyvtárban vannak:

- `config.yml` - Template konfiguráció
- `bug-api.yml` - API bug jelentés
- `bug-source.yml` - Forráskezelés bug jelentés
- `bug-collection.yml` - Adatgyűjtés bug jelentés
- `bug-factcheck.yml` - Fact-checking bug jelentés
- `bug-deploy.yml` - Deployment bug jelentés
- `bug-sec.yml` - Biztonsági bug jelentés

**Használat:**
1. Menj a GitHub issue oldalra
2. Kattints "New issue"
3. Válassz egy template-t
4. Töltsd ki a mezőket

---

## Teszt Dokumentáció

### TESTING.md

Részletes tesztelési dokumentáció a `docs/TESTING.md` fájlban:
- Tesztelési stratégia
- Tesztesetek katalógus
- Modulok szerinti tesztesetek
- Tesztelési folyamat

### TEST_CASES_ISSUES.md

Tesztesetek issue formátumban a `docs/TEST_CASES_ISSUES.md` fájlban:
- Minden teszteset issue formátumban
- Kész az issue létrehozásra
- Script-tel automatikusan feltölthető

---

## Gyors Útmutató

### 1. Template-ek feltöltése

```bash
# Template-ek ellenőrzése és commit
./scripts/upload_issue_templates.sh

# Vagy manuálisan:
git add .github/ISSUE_TEMPLATE/
git commit -m "feat: Add issue templates"
git push
```

### 2. Tesztesetek issue-k létrehozása

```bash
# Tesztesetek issue-k létrehozása
./scripts/create_test_issues.sh
```

---

## Címkék

A scriptek automatikusan létrehozzák a következő címkéket:

**Prioritás:**
- `priority-p1` - Critical
- `priority-p2` - High
- `priority-p3` - Medium
- `priority-p4` - Low

**Típus:**
- `type-functional` - Funkcionális
- `type-integration` - Integration
- `type-security` - Biztonsági
- `type-performance` - Teljesítmény

**Egyéb:**
- `testing` - Tesztelés
- `test-case` - Teszteset
- `source` - Forráskezelés
- `collection` - Adatgyűjtés
- `factcheck` - Fact-checking
- `search` - Keresés

---

**Megjegyzés:** Ez a dokumentum folyamatosan frissül a scriptek változásával!




