#!/bin/bash

# Sync with Remote - Pull and Merge
# Biztonságosan szinkronizálja a lokális és remote repository-t

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "=== Remote és Lokális Szinkronizálás ==="
echo ""

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}⚠️  Van nem commitolt változás!${NC}"
    echo ""
    git status --short
    echo ""
    read -p "Először commitold a változásokat? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add -A
        read -p "Commit üzenet: " commit_message
        git commit -m "$commit_message"
    else
        echo "Commitold először a változásokat!"
        exit 1
    fi
fi

# Fetch remote changes
echo ""
echo "1. Remote változások letöltése..."
git fetch origin

# Check if branches have diverged
LOCAL=$(git rev-parse main)
REMOTE=$(git rev-parse origin/main)
BASE=$(git merge-base main origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    echo -e "${GREEN}✅ Lokális és remote már szinkronban vannak!${NC}"
    exit 0
elif [ "$LOCAL" = "$BASE" ]; then
    echo "Remote előrébb van, pull-olás..."
    git pull origin main
elif [ "$REMOTE" = "$BASE" ]; then
    echo "Lokális előrébb van, push-olás..."
    git push -u origin main
else
    echo -e "${YELLOW}Branchek eltértek. Merge szükséges.${NC}"
    echo ""
    echo "Lokális commitok száma: $(git rev-list --count HEAD ^origin/main)"
    echo "Remote commitok száma: $(git rev-list --count origin/main ^HEAD)"
    echo ""
    read -p "Merge-eljük a változásokat? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo ""
        echo "2. Merge folyamat..."
        git pull origin main --no-rebase
        
        echo ""
        echo "3. Push a merge után..."
        git push -u origin main
        
        echo ""
        echo -e "${GREEN}✅ Sikeresen szinkronizálva!${NC}"
    else
        echo "Merge megszakítva."
        exit 1
    fi
fi


