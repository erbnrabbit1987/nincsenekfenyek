#!/bin/bash

# Fix Remote URL - Change HTTPS to SSH
# Segít átállítani a remote URL-t SSH-ra

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "=== Remote URL átállítása SSH-ra ==="
echo ""

# Check if remote exists
if ! git remote | grep -q "origin"; then
    echo -e "${RED}Nincs remote repository beállítva!${NC}"
    echo "Használd: ./scripts/setup-github-ssh.sh"
    exit 1
fi

current_url=$(git remote get-url origin)
echo -e "${YELLOW}Jelenlegi remote URL:${NC} $current_url"
echo ""

# Check if already SSH
if echo "$current_url" | grep -q "^git@github.com:"; then
    echo -e "${GREEN}✅ A remote már SSH-t használ!${NC}"
    exit 0
fi

# Extract repository path from HTTPS URL
if echo "$current_url" | grep -q "github.com"; then
    # Extract username/repo from HTTPS URL
    repo_path=$(echo "$current_url" | sed -E 's|.*github\.com[:/]([^/]+/[^/]+)(\.git)?/?$|\1|')
    repo_path=$(echo "$repo_path" | sed 's|\.git$||')
    
    echo "Detektált repository path: $repo_path"
    read -p "Jó ez a repository path? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        read -p "Add meg a helyes repository path-t (username/repo-name): " repo_path
    fi
    
    # Build SSH URL
    ssh_url="git@github.com:${repo_path}.git"
    
    echo ""
    echo -e "${GREEN}Új SSH URL:${NC} $ssh_url"
    echo ""
    read -p "Átállítom SSH-ra? (Y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        git remote set-url origin "$ssh_url"
        echo ""
        echo -e "${GREEN}✅ Remote URL sikeresen átállítva SSH-ra!${NC}"
        echo ""
        echo "Új remote URL:"
        git remote -v
        echo ""
        echo "Most próbáld meg újra:"
        echo "  git push -u origin main"
    fi
else
    echo -e "${RED}Ismeretlen remote URL formátum${NC}"
    echo "Add meg manuálisan a repository path-t:"
    read -p "Repository path (username/repo-name): " repo_path
    ssh_url="git@github.com:${repo_path}.git"
    git remote set-url origin "$ssh_url"
    echo -e "${GREEN}✅ Remote URL beállítva: $ssh_url${NC}"
fi

