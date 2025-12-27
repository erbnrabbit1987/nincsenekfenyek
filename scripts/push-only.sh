#!/bin/bash

##############################################################################
# Push Only Script
# Csak push-olás (feltételezi, hogy már van commit)
##############################################################################

# Színek
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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
echo -e "${BLUE}║  Git Push                                                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Remote ellenőrzése
REMOTE=$(git_clean remote get-url origin 2>/dev/null)
if [ -z "$REMOTE" ]; then
    echo -e "${RED}✗${NC} Nincs remote beállítva!"
    echo "Használd: git remote add origin git@github.com:erbnrabbit1987/nincsenekfenyek-devel.git"
    exit 1
fi

echo -e "${BLUE}Remote:${NC} $REMOTE"
echo ""

# Push
echo -e "${BLUE}Push-olás...${NC}"
PUSH_OUTPUT=$(git_clean push origin main 2>&1)
PUSH_EXIT=$?

if [ $PUSH_EXIT -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Push sikeres!"
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Push elkészült!                                         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
elif echo "$PUSH_OUTPUT" | grep -q "Permission denied\|Operation not permitted"; then
    echo -e "${YELLOW}⚠${NC} SSH kulcs probléma"
    echo ""
    echo -e "${YELLOW}Lehetséges megoldások:${NC}"
    echo "1. Ellenőrizd az SSH kulcsot:"
    echo "   ssh -T git@github.com"
    echo ""
    echo "2. Add hozzá a kulcsot az ssh-agenthez:"
    echo "   eval \"\$(ssh-agent -s)\""
    echo "   ssh-add ~/.ssh/id_ed25519"
    echo ""
    echo "3. Vagy használj HTTPS-t:"
    echo "   git remote set-url origin https://github.com/erbnrabbit1987/nincsenekfenyek-devel.git"
    echo ""
    echo -e "${YELLOW}Részletes útmutató: docs/PUSH_GUIDE.md${NC}"
    exit 1
else
    echo -e "${RED}✗${NC} Push sikertelen!"
    echo "$PUSH_OUTPUT"
    exit 1
fi


