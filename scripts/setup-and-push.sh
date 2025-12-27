#!/bin/bash

##############################################################################
# Setup and Push Script
# Repository létrehozása ellenőrzése és push végrehajtása
##############################################################################

# Színek
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Projekt gyökér
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Clean git function
git_clean() {
    export ZSH_PROMPT_COMMAND=""
    export ZSH_DUMP_STATE=""
    command git "$@" 2>&1 | grep -v "base64.*Operation not permitted" | grep -v "dump_zsh_state" | grep -v "command not found: dump_zsh_state" | cat
}

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Repository Setup és Push                                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Remote ellenőrzése
REMOTE=$(git_clean remote get-url origin 2>/dev/null)
if [ -z "$REMOTE" ]; then
    echo -e "${YELLOW}⚠${NC} Nincs remote beállítva!"
    echo ""
    echo -e "${CYAN}Remote hozzáadása...${NC}"
    git_clean remote add origin git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git
    REMOTE="git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git"
    echo -e "${GREEN}✓${NC} Remote hozzáadva: $REMOTE"
fi

echo -e "${BLUE}Remote:${NC} $REMOTE"
echo ""

# SSH kapcsolat ellenőrzése
echo -e "${CYAN}[1/4]${NC} SSH kapcsolat ellenőrzése..."
SSH_TEST=$(ssh -T git@github.com 2>&1)
if echo "$SSH_TEST" | grep -q "successfully authenticated"; then
    echo -e "${GREEN}✓${NC} SSH kapcsolat OK"
else
    echo -e "${RED}✗${NC} SSH kapcsolat probléma"
    echo "$SSH_TEST"
    echo ""
    echo -e "${YELLOW}Próbáld meg:${NC}"
    echo "  eval \"\$(ssh-agent -s)\""
    echo "  ssh-add ~/.ssh/id_ed25519"
    exit 1
fi
echo ""

# Repository létezés ellenőrzése
echo -e "${CYAN}[2/4]${NC} Repository létezés ellenőrzése..."
REPO_NAME="nincsenekfenyek-devel"
REPO_USER="erbnrabbit1987"

# Próbáljuk meg lekérdezni a repository-t
GIT_LS_OUTPUT=$(git_clean ls-remote origin 2>&1)
LS_EXIT=$?

if [ $LS_EXIT -eq 0 ] && [ -n "$GIT_LS_OUTPUT" ]; then
    echo -e "${GREEN}✓${NC} Repository létezik: ${REPO_USER}/${REPO_NAME}"
elif echo "$GIT_LS_OUTPUT" | grep -q "not found\|does not exist"; then
    echo -e "${YELLOW}⚠${NC} Repository még nincs létrehozva!"
    echo ""
    echo -e "${CYAN}Hozd létre a repository-t a GitHub-on:${NC}"
    echo ""
    echo "  1. Menj a https://github.com/new oldalra"
    echo "  2. Repository neve: ${YELLOW}${REPO_NAME}${NC}"
    echo "  3. Privát: ${YELLOW}Igen (ajánlott)${NC}"
    echo "  4. ${RED}NE${NC} inicializáld README-mel, .gitignore-gel vagy licenccel"
    echo "  5. Kattints \"Create repository\""
    echo ""
    echo -e "${CYAN}Vagy használd a GitHub CLI-t (ha telepítve van):${NC}"
    echo "  gh repo create ${REPO_NAME} --private --source=. --remote=origin --push"
    echo ""
    read -p "Nyomj Enter-t, ha létrehoztad a repository-t, vagy Ctrl+C-t a megszakításhoz: "
    
    # Újraellenőrzés
    GIT_LS_OUTPUT=$(git_clean ls-remote origin 2>&1)
    LS_EXIT=$?
    if [ $LS_EXIT -ne 0 ] || [ -z "$GIT_LS_OUTPUT" ]; then
        echo -e "${RED}✗${NC} Repository még mindig nem található!"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} Repository megtalálva!"
else
    echo -e "${YELLOW}⚠${NC} Nem sikerült ellenőrizni a repository létezését"
    echo "  Folytatjuk a push-t..."
fi
echo ""

# Branch ellenőrzése és beállítása
echo -e "${CYAN}[3/4]${NC} Branch ellenőrzése..."
CURRENT_BRANCH=$(git_clean branch --show-current)
if [ -z "$CURRENT_BRANCH" ]; then
    echo -e "${YELLOW}⚠${NC} Nincs branch, létrehozás..."
    git_clean checkout -b main
    CURRENT_BRANCH="main"
fi

if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${CYAN}Branch átnevezése main-re...${NC}"
    git_clean branch -M main
    CURRENT_BRANCH="main"
fi
echo -e "${GREEN}✓${NC} Branch: $CURRENT_BRANCH"
echo ""

# Push
echo -e "${CYAN}[4/4]${NC} Push-olás..."
PUSH_OUTPUT=$(git_clean push -u origin main 2>&1)
PUSH_EXIT=$?

if [ $PUSH_EXIT -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Push sikeres!"
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Repository sikeresen feltöltve a GitHub-ra!            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Repository URL:${NC} https://github.com/${REPO_USER}/${REPO_NAME}"
elif echo "$PUSH_OUTPUT" | grep -q "Repository not found"; then
    echo -e "${RED}✗${NC} Repository nem található!"
    echo ""
    echo -e "${YELLOW}Hozd létre a repository-t a GitHub-on:${NC}"
    echo "  https://github.com/new"
    echo "  Név: ${REPO_NAME}"
    echo "  Privát: Igen"
    echo ""
    echo "Ezután futtasd újra ezt a scriptet:"
    echo "  ./scripts/setup-and-push.sh"
    exit 1
elif echo "$PUSH_OUTPUT" | grep -q "Permission denied\|Operation not permitted"; then
    echo -e "${RED}✗${NC} SSH kulcs probléma"
    echo ""
    echo -e "${YELLOW}Lehetséges megoldások:${NC}"
    echo "1. Ellenőrizd az SSH kulcsot:"
    echo "   ssh -T git@github.com"
    echo ""
    echo "2. Add hozzá a kulcsot az ssh-agenthez:"
    echo "   eval \"\$(ssh-agent -s)\""
    echo "   ssh-add ~/.ssh/id_ed25519"
    echo ""
    echo -e "${YELLOW}Részletes útmutató: docs/PUSH_GUIDE.md${NC}"
    exit 1
else
    echo -e "${RED}✗${NC} Push sikertelen!"
    echo "$PUSH_OUTPUT"
    exit 1
fi

