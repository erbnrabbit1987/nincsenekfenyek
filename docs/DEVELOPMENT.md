# Fejlesztési Dokumentáció

> Ez a dokumentum a projekt fejlesztési folyamatát, szabályait és best practice-eket tartalmazza. **Folyamatosan frissül és maintainelendő.**

## Tartalomjegyzék

1. [Fejlesztési Környezet](#fejlesztési-környezet)
2. [Projekt Struktúra](#projekt-struktúra)
3. [Kódolási Szabályok](#kódolási-szabályok)
4. [Git Munkafolyamat](#git-munkafolyamat)
5. [Tesztelés](#tesztelés)
6. [Dokumentáció Karbantartása](#dokumentáció-karbantartása)
7. [Issue és Feature Kezelés](#issue-és-feature-kezelés)
8. [Deployment](#deployment)

---

## Fejlesztési Környezet

### Előfeltételek
- Python 3.10+ (vagy Node.js, attól függően, mit választunk)
- Git
- Database (PostgreSQL/MySQL/MongoDB - később meghatározandó)
- Virtual environment manager (venv, pipenv, poetry)

### Környezeti Változók
Készítendő: `.env.example` fájl a szükséges környezeti változókkal.

---

## Projekt Struktúra

```
nincsenekfenyek/
├── docs/                      # Dokumentáció
│   ├── DEVELOPMENT.md        # Ez a fájl
│   ├── ARCHITECTURE.md       # Architektúra
│   └── API.md                # API dokumentáció (ha van)
├── src/                       # Forráskód
│   ├── api/                  # API réteg (ha REST API)
│   ├── core/                 # Core logika
│   ├── services/             # Business logika
│   ├── models/               # Adatmodell
│   ├── utils/                # Segédfüggvények
│   └── config/               # Konfiguráció
├── tests/                     # Tesztek
│   ├── unit/                 # Unit tesztek
│   ├── integration/          # Integrációs tesztek
│   └── fixtures/             # Teszt adatok
├── migrations/                # Adatbázis migrációk
├── scripts/                   # Utility scriptek
├── .gitignore
├── .env.example
├── requirements.txt          # Python dependencies (vagy package.json)
├── README.md
└── USE_CASES.md
```

---

## Kódolási Szabályok

### Általános Elvek
- **Tiszta kód**: Olvasható, érthető, jól strukturált
- **DRY**: Don't Repeat Yourself
- **SOLID elvek**: Különösen Single Responsibility és Dependency Inversion
- **Kommentek**: Csak szükséges helyeken, a kódnak önmagát kell dokumentálnia
- **Naming**: Beszédes változó/függvény nevek angolul (kivéve, ha üzleti logika magyarul jobban érthető)

### Kód Formázás
- Használjunk formattert (Black Pythonhoz, Prettier JS-hez)
- Linter használata kötelező (pylint, eslint stb.)
- Maximum sorhossz: 100-120 karakter

### Dokumentációs Stringek
- Funkciók/classok dokumentálása docstring formátumban
- Paraméterek és visszatérési értékek dokumentálása

### Error Handling
- Explicit error handling minden kritikus ponton
- Logging használata (strukturált logging)
- User-friendly hibaüzenetek

---

## Git Munkafolyamat

### Branch Strategy
- `main/master`: Production-ready kód
- `develop`: Fejlesztői ág, ide merge-elünk feature brancheket
- `feature/<feature-name>`: Új funkciók fejlesztése
- `fix/<bug-name>`: Bug javítások
- `hotfix/<hotfix-name>`: Sürgős javítások a main ágon

### Commit Üzenetek
Formátum: `[típus] Rövid leírás`

Típusok:
- `feat`: Új funkció
- `fix`: Bug javítás
- `docs`: Dokumentáció változás
- `style`: Formázás (nincs funkcionális változás)
- `refactor`: Kód refaktorálás
- `test`: Tesztek hozzáadása/módosítása
- `chore`: Build folyamat, tooling változások

Példa:
```
feat: Add Facebook profile monitoring service
fix: Resolve database connection timeout issue
docs: Update USE_CASES.md with new requirements
```

### Pull Request Folyamat
1. Feature branch létrehozása `develop`-ből
2. Fejlesztés, commit, push
3. Pull Request nyitása `develop`-be
4. Code review
5. Tesztek futtatása
6. Merge (ha minden oké)

---

## Tesztelés

### Tesztelési Stratégia
- **Unit tesztek**: Minden függvény/method legalább egyszer tesztelve
- **Integration tesztek**: Modulok közötti interakciók
- **E2E tesztek**: Kritikus felhasználói folyamatok

### Tesztelési Követelmények
- Minimum 70% code coverage (célozzunk 80%+)
- Minden új funkcióhoz tesztek írása kötelező
- CI/CD pipeline-ban automatikus tesztfuttatás

### Tesztfuttatás
```bash
# Unit tesztek
pytest tests/unit

# Minden teszt
pytest tests/

# Coverage report
pytest --cov=src tests/
```

---

## Dokumentáció Karbantartása

### Frissítendő Dokumentumok
Ez a dokumentum mellett a következő dokumentumok is folyamatosan frissüljenek:

1. **USE_CASES.md**: Új use case-ek hozzáadásakor
2. **ARCHITECTURE.md**: Architektúra változásoknál
3. **README.md**: Főbb változások, új funkciók
4. **API.md** (ha van): API változásoknál
5. **CHANGELOG.md**: Verziók és változások nyilvántartása

### Frissítési Szabály
- **Minden funkcióhoz**: Update USE_CASES.md és README.md
- **Minden architektúra változáshoz**: Update ARCHITECTURE.md
- **Minden release-hez**: Update CHANGELOG.md
- **Minden API változáshoz**: Update API.md

---

## Issue és Feature Kezelés

### Issue Létrehozás
- **Template használata**: Minden issue-hoz template
- **Címkezés**: labels használata (bug, feature, enhancement, documentation)
- **Milestone**: Tervezett verzióhoz rendelés

### Feature Lifecycle
1. Issue létrehozása a feature-hez
2. Megbeszélés, terv kidolgozása
3. Use case dokumentálása (USE_CASES.md)
4. Implementáció
5. Tesztelés
6. Dokumentáció frissítése
7. Review és merge

---

## Deployment

### Environment-ek
- **Development**: Fejlesztői környezet
- **Staging**: Tesztelési környezet (production-hez hasonló)
- **Production**: Éles környezet

### Deployment Folyamat
1. Kód merge a `main`-be
2. Automatikus CI/CD pipeline
3. Tesztek futtatása
4. Build
5. Deployment staging-re (automatikus vagy manuális)
6. Staging tesztelés
7. Production deployment (jóváhagyás után)

---

## Code Review Guidelines

### Revieweléskor figyelni:
- Kód minősége és olvashatósága
- Tesztlefedettség
- Dokumentáció frissítése
- Security concern-ek
- Performance issue-k
- Best practice-ek betartása

### Review Kommentek
- Konstruktív kritika
- Javaslatok konkrét példákkal
- Approve csak ha minden rendben

---

## Security Best Practices

- **Secrets**: Soha ne commit-oljunk secrets-t (.env fájlok)
- **Dependencies**: Rendszeres frissítés, security audit
- **Input validation**: Minden user input validálva
- **SQL Injection**: Parameterized queries használata
- **Rate limiting**: API endpointokon
- **Authentication**: Biztonságos auth implementáció

---

## Performance Guidelines

- **Adatbázis**: Indexek használata, query optimization
- **Caching**: Strategia alkalmazása ahol értelmes
- **Async**: Aszinkron műveletek ahol lehetséges
- **Monitoring**: Performance metrikák követése

---

## Changelog

### 2024-01-XX - Initial Setup
- Projekt inicializálása
- Alap dokumentáció létrehozása
- Git repository beállítása

---

**Megjegyzés**: Ez a dokumentum folyamatosan fejlesztendő a projekt haladtával. Kérjük, tartsd naprakészen!

