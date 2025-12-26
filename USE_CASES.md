# Nincsenek Fények! - Use Cases

## Projekt Áttekintés
A "Nincsenek Fények!" egy fact-checking és információs monitoring alkalmazás, amely különböző online forrásokat (Facebook profilok, híroldalak, statisztikák) figyeli, összeveti egymással, és tényellenőrzést végez.

---

## 1. Forráskezelés Use Cases

### UC-1.1: Facebook Profil Hozzáadása
**Akció:** Felhasználó hozzáad egy Facebook profilt forrásként
- **Előfeltételek:** Felhasználó be van jelentkezve, van forráscsoport
- **Átfolyam:**
  1. Felhasználó megadja a Facebook profil URL-t vagy felhasználónevet
  2. Rendszer validálja a profilt (létezik-e, elérhető-e)
  3. Felhasználó hozzárendeli egy forráscsoporthoz
  4. Rendszer elindítja a real-time figyelést
- **Eredmény:** A profil aktív forrásként működik, postjai automatikusan gyűjtődnek

### UC-1.2: Híroldal Forrás Hozzáadása
**Akció:** Felhasználó hozzáad egy híroldalt forrásként
- **Átfolyam:**
  1. Felhasználó megadja a híroldal URL-t vagy RSS feed-et
  2. Rendszer beállítja az automatikus cikkgyűjtést
  3. Felhasználó szűrőket állíthat be (pl. kategória, címke)
- **Eredmény:** A híroldal cikkei automatikusan gyűjtődnek

### UC-1.3: Statisztikai Forrás Hozzáadása (EUROSTAT stb.)
**Akció:** Felhasználó hozzáad egy statisztikai portált
- **Átfolyam:**
  1. Felhasználó kiválasztja a statisztikai forrást (EUROSTAT, KSH, stb.)
  2. Rendszer beállítja az API kapcsolatot
  3. Felhasználó megadja, mely adatkészletekre kíváncsi
- **Eredmény:** A statisztikai adatok elérhetők tényellenőrzéshez

### UC-1.4: Forráscsoport Létrehozása és Kezelése
**Akció:** Felhasználó létrehoz és kezel forráscsoportokat
- **Átfolyam:**
  1. Felhasználó létrehoz egy új forráscsoportot (pl. "Politikusok", "Híroldalak")
  2. Hozzáad forrásokat a csoporthoz
  3. Beállítja a csoport figyelési paramétereit
- **Eredmény:** Logikailag csoportosított források könnyebb kezeléshez

---

## 2. Adatgyűjtés Use Cases

### UC-2.1: Real-time Facebook Post Gyűjtés
**Akció:** Rendszer automatikusan gyűjti a Facebook profilok posztjait
- **Trigger:** Időzített feladat vagy új post észlelése
- **Átfolyam:**
  1. Rendszer ellenőrzi az összes aktív Facebook profilt
  2. Letölti az új/update-elt posztokat
  3. Parse-olja a szöveget, képeket, linkeket
  4. Metaadatok mentése (időpont, like-ok, kommentek stb.)
- **Eredmény:** Új posztok az adatbázisban, ready fact-checkinghez

### UC-2.2: Híroldal Cikk Gyűjtés
**Akció:** Rendszer gyűjti a híroldalak cikkeit
- **Átfolyam:**
  1. RSS feed olvasás vagy web scraping
  2. Új cikkek azonosítása
  3. Cikk tartalmának és metaadatainak kinyerése
- **Eredmény:** Cikkek az adatbázisban

### UC-2.3: Statisztikai Adat Frissítés
**Akció:** Rendszer frissíti a statisztikai források adatait
- **Átfolyam:**
  1. API hívások a statisztikai portálokhoz
  2. Új adatok letöltése
  3. Adatok normalizálása és tárolása
- **Eredmény:** Naprakész statisztikák a tényellenőrzéshez

---

## 3. Tényellenőrzés (Fact-checking) Use Cases

### UC-3.1: Automatikus Tényellenőrzés Facebook Postokon
**Akció:** Rendszer automatikusan fact-checkeli a Facebook posztokat
- **Trigger:** Új post érkezése
- **Átfolyam:**
  1. Rendszer azonosítja a posztban lévő állításokat/allegációkat
  2. Keres kapcsolódó cikkeket más forrásokban
  3. Összeveti statisztikai adatokkal
  4. Azonosítja az eltéréseket/ellentmondásokat
  5. Keres hivatkozásokat/hiteles forrásokat
  6. Generál fact-check eredményt (megbízható, kérdéses, cáfolt stb.)
- **Eredmény:** Fact-check jelentés minden poszthoz

### UC-3.2: Hivatkozások Keresése
**Akció:** Rendszer hivatkozásokat keres az állításokhoz
- **Átfolyam:**
  1. Rendszer azonosítja a posztban lévő kulcsszavakat/állításokat
  2. Keres a saját forrásokban (híroldalak, statisztikák)
  3. Keres külső forrásokban (Google, fact-checking oldalak)
  4. Rangsorolja a hivatkozásokat relevancia szerint
- **Eredmény:** Hivatkozások listája minden állításhoz

### UC-3.3: Eltérések Azonosítása
**Akció:** Rendszer azonosítja az eltéréseket különböző források között
- **Átfolyam:**
  1. Összehasonlítja ugyanazt az információt különböző forrásokból
  2. Detektálja a számbeli eltéréseket
  3. Detektálja az ellentmondásokat
  4. Kategorizálja az eltéréseket (súlyos, kisebb, stb.)
- **Eredmény:** Eltérés jelentés

---

## 4. Keresés és Szűrés Use Cases

### UC-4.1: Tényalapú Keresés
**Akció:** Felhasználó keres tényeket/kijelentéseket
- **Átfolyam:**
  1. Felhasználó megad keresőkifejezéseket
  2. Választhat szűrőket (forrás, időszak, megbízhatóság)
  3. Rendszer listázza az eredményeket relevancia szerint
- **Eredmény:** Szűrt lista tényekkel és hivatkozásokkal

### UC-4.2: Forrás szerinti Szűrés
**Akció:** Felhasználó szűr forrás szerint
- **Átfolyam:**
  1. Felhasználó kiválaszt egy forrást vagy forráscsoportot
  2. Rendszer megjeleníti az összes releváns tartalmat
- **Eredmény:** Forrás-specifikus tartalom lista

### UC-4.3: Időszak szerinti Szűrés
**Akció:** Felhasználó szűr dátum szerint
- **Átfolyam:**
  1. Felhasználó megad egy dátumtartományt
  2. Rendszer szűri a tartalmat
- **Eredmény:** Időszakra szűrt tartalom

---

## 5. Összefoglaló és Jelentés Use Cases

### UC-5.1: Automatikus Összefoglaló Generálás
**Akció:** Rendszer generál összefoglalót egy témáról/időszakról
- **Trigger:** Felhasználó kérése vagy automatikus (napi/havi)
- **Átfolyam:**
  1. Rendszer gyűjti az adott időszak/téma összes tartalmát
  2. Csoportosítja a kapcsolódó állításokat
  3. Összefoglalja a fact-check eredményeket
  4. Kiemeli a legfontosabb eltéréseket
  5. Generál olvasható összefoglalót
- **Eredmény:** Strukturált összefoglaló dokumentum

### UC-5.2: Dashboard Megjelenítés
**Akció:** Felhasználó megtekinti a dashboardot
- **Átfolyam:**
  1. Rendszer betölti a legfontosabb statisztikákat
  2. Megjeleníti az aktív forrásokat
  3. Kiemeli a friss fact-check eredményeket
  4. Grafikonok/diagramok a trendekről
- **Eredmény:** Interaktív dashboard áttekintéssel

---

## 6. Felhasználói Műveletek Use Cases

### UC-6.1: Felhasználói Regisztráció és Bejelentkezés
**Akció:** Új felhasználó regisztrál vagy bejelentkezik
- **Átfolyam:** Standard auth folyamat
- **Eredmény:** Bejelentkezett felhasználó

### UC-6.2: Értesítések Beállítása
**Akció:** Felhasználó beállítja az értesítéseket
- **Átfolyam:**
  1. Felhasználó választhat, mikor kapjon értesítést
  2. Beállíthat email/notifikáció típusokat
  3. Szűrhet mely forrásokról/kategóriákról szeretne értesítést
- **Eredmény:** Testreszabott értesítési beállítások

---

## Kérdések a pontosításhoz:
1. **Facebook API integráció:** Hogyan szeretnéd elérni? (Meta Graph API, scraping?)
2. **Felhasználói szerepkörök:** Vannak különböző jogosultságok? (admin, viewer, editor?)
3. **Adatbázis:** Milyen adatbázist szeretnél használni?
4. **Tech stack:** Milyen technológiákat preferálsz? (backend: Python, Node.js? frontend: React, Vue?)
5. **Deployment:** Hol fog futni? (cloud, saját szerver?)
6. **Részletes fact-checking:** Manuális review lehetősége is kell, vagy teljesen automatikus?



