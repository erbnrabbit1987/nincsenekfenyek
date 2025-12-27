#!/bin/bash

# GitHub SSH Setup Script - Legyszerűbb verzió
# Automatikusan SSH-t használ, csak a repository nevét kéri

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "=== GitHub Repository Beállítás (SSH) ==="
echo ""

# Check if remote already exists
if git remote | grep -q "origin"; then
    current_remote=$(git remote get-url origin)
    echo -e "${YELLOW}Már van remote: $current_remote${NC}"
    read -p "Lecserélem? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git remote remove origin
    else
        exit 0
    fi
fi

echo ""
echo "1️⃣  Előbb hozd létre a repository-t GitHub-on:"
echo "   https://github.com/new"
echo "   Név: nincsenekfenyek (vagy amit szeretnél)"
echo ""
read -p "Nyomj Enter-t, ha létrehoztad..."

echo ""
echo "2️⃣  Add meg a repository teljes elérési útját:"
echo "   Példa: username/nincsenekfenyek"
read -p "Repository path: " repo_path

if [ -z "$repo_path" ]; then
    echo -e "${RED}Hiba: Repository path nem lehet üres!${NC}"
    exit 1
fi

# Build SSH URL
repo_url="git@github.com:${repo_path}.git"

echo ""
echo -e "${GREEN}Remote beállítása: $repo_url${NC}"
git remote add origin "$repo_url"

echo ""
echo "Branch ellenőrzése..."
current_branch=$(git branch --show-current)
if [ "$current_branch" != "main" ]; then
    git branch -M main
fi

echo ""
read -p "Feltöltöm a kódot? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "Feltöltés..."
    if git push -u origin main; then
        echo ""
        echo -e "${GREEN}✅ Sikeresen feltöltve!${NC}"
        echo "   https://github.com/${repo_path}"
    else
        echo -e "${RED}Hiba a feltöltés során.${NC}"
        echo "Ellenőrizd az SSH kapcsolatot: ssh -T git@github.com"
        exit 1
    fi
fi

