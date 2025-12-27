# Cursor Git Setup - Hiba elnyomás

## Probléma

Cursor-ban git parancsok futtatásakor a következő hibák jelennek meg:

```
/usr/bin/base64: line 136: /dev/stdout: Operation not permitted
zsh:1: command not found: dump_zsh_state
```

Ezek a hibák a shell konfigurációból (valószínűleg oh-my-zsh vagy egyedi prompt) jönnek, és nem akadályozzák a git működését, de zavaróak.

## Megoldások

### Megoldás 1: Git Alias használata (Ajánlott)

A `.gitconfig.local` fájl tartalmaz aliasokat, amelyek elnyomják a hibákat:

```bash
# Git config beolvasása
git config --local include.path .gitconfig.local

# Használat:
git status-clean
git log-clean
git diff-clean
```

### Megoldás 2: Error Suppress Script

Source-old a `.giterrors-suppress.sh` fájlt a Cursor terminálban:

```bash
source .giterrors-suppress.sh
```

Ez után a `git` parancs automatikusan elnyomja a hibákat.

### Megoldás 3: Cursor Settings

A Cursor beállításokban állítsd be a shell-t úgy, hogy ne használjon problematikus prompt-okat:

1. Cursor Settings
2. Terminal → Shell Integration → Disable problematic features
3. Vagy használj bash-t zsh helyett ideiglenesen

### Megoldás 4: ZSH Config módosítás (Állandó megoldás)

Ha szeretnéd javítani a zsh konfigurációt:

```bash
# Keresd meg a problematikus sort a ~/.zshrc fájlban
grep -n "base64\|dump_zsh_state" ~/.zshrc

# Kommenteld ki vagy töröld a problematikus sorokat
# Vagy add hozzá ezt a sort a ~/.zshrc végéhez:

# Suppress known errors in non-interactive mode
if [[ $- != *i* ]]; then
    unset ZSH_PROMPT_COMMAND 2>/dev/null
    unset ZSH_DUMP_STATE 2>/dev/null
fi
```

## Git Parancsok Cursor-ban

A hagyományos git parancsok továbbra is működnek:

```bash
# Status (hibák nélkül a suppress script után)
git status

# Commit
git add .
git commit -m "Your message"

# Push
git push origin main
```

## Commit és Push a Cursor-ból

### Lépések:

1. **Változások hozzáadása:**
   ```bash
   git add .
   # vagy konkrét fájlok:
   git add src/ scripts/
   ```

2. **Commit:**
   ```bash
   git commit -m "feat: Your feature description"
   ```

3. **Push:**
   ```bash
   git push origin main
   ```

### Gyors commit script:

```bash
# scripts/quick-commit.sh
#!/bin/bash
source .giterrors-suppress.sh

git add .
git commit -m "$1"
git push origin main
```

Használat:
```bash
chmod +x scripts/quick-commit.sh
./scripts/quick-commit.sh "Your commit message"
```

## Hibaelhárítás

### Ha a hibák továbbra is megjelennek:

1. **Nézd meg a shell konfigurációt:**
   ```bash
   cat ~/.zshrc | grep -E "(base64|dump|PROMPT)"
   ```

2. **Próbáld ki bash-t:**
   ```bash
   bash
   git status
   ```

3. **Disable shell integration ideiglenesen:**
   ```bash
   unset ZSH_PROMPT_COMMAND
   unset ZSH_DUMP_STATE
   git status
   ```

## További információk

- A hibák nem akadályozzák a git működését
- A commit és push működik, csak zavaró a kimenet
- A legjobb megoldás a zsh config javítása, de a suppress script is elég lehet


