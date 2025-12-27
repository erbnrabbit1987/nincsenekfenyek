#!/bin/bash

##############################################################################
# Quick Commit and Push Script
# Használat: ./scripts/commit-push.sh "Commit message"
##############################################################################

set -e

# Színek
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Projekt gyökér
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Commit message ellenőrzése
if [ -z "$1" ]; then
    echo -e "${RED}Használat: $0 \"Commit message\"${NC}"
    exit 1
fi

COMMIT_MSG="$1"

# Clean git function (hibák elnyomása)
git_clean() {
    # Suppress shell errors before running git
    export ZSH_PROMPT_COMMAND=""
    export ZSH_DUMP_STATE=""
    # Run git and filter errors from output
    command git "$@" 2>&1 | grep -v "base64.*Operation not permitted" | grep -v "dump_zsh_state" | grep -v "command not found: dump_zsh_state" || {
        exit_code=${PIPESTATUS[0]}
        [ $exit_code -eq 0 ] || exit $exit_code
    }
}

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Git Commit és Push                                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Status ellenőrzése
echo -e "${BLUE}[1/4]${NC} Status ellenőrzése..."
STATUS=$(git_clean status --short)
if [ -z "$STATUS" ]; then
    echo -e "${RED}Nincs módosítás a commitoláshoz!${NC}"
    exit 0
fi

echo "$STATUS"
echo ""

# Add
echo -e "${BLUE}[2/4]${NC} Változások hozzáadása..."
git_clean add -A
echo -e "${GREEN}✓${NC} Változások hozzáadva"
echo ""

# Commit
echo -e "${BLUE}[3/4]${NC} Commit..."
if git_clean commit -m "$COMMIT_MSG"; then
    echo -e "${GREEN}✓${NC} Commit sikeres: $COMMIT_MSG"
else
    echo -e "${RED}✗${NC} Commit sikertelen!"
    exit 1
fi
echo ""

# Push
echo -e "${BLUE}[4/4]${NC} Push..."
PUSH_OUTPUT=$(git_clean push origin main 2>&1)
PUSH_EXIT=$?

if [ $PUSH_EXIT -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Push sikeres!"
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Minden sikeresen elkészült!                             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
elif echo "$PUSH_OUTPUT" | grep -q "Permission denied\|Operation not permitted"; then
    echo -e "${YELLOW}⚠${NC} Push sikertelen (SSH kulcs probléma)"
    echo -e "${YELLOW}Commit sikeres volt, de a push nem sikerült.${NC}"
    echo -e "${YELLOW}Próbáld meg manuálisan: git push origin main${NC}"
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Commit sikeres! (Push később)                           ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}✗${NC} Push sikertelen!"
    echo "$PUSH_OUTPUT"
    echo -e "${RED}Ellenőrizd az SSH kulcsokat vagy a hálózati kapcsolatot!${NC}"
    exit 1
fi

