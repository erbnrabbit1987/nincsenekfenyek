#!/bin/bash

# Git Remote Setup Script - GitHub SSH
# Egyszerűsített verzió SSH autentikációval

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

cd "$PROJECT_ROOT"

echo "=== GitHub Remote Repository Beállítás (SSH) ==="
echo ""

# Check if remote already exists
if git remote | grep -q "origin"; then
    current_remote=$(git remote get-url origin)
    log_warn "Már van remote repository beállítva: $current_remote"
    read -p "Szeretnéd lecserélni? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git remote remove origin
        log_info "Régi remote eltávolítva"
    else
        log_info "Megtartjuk a jelenlegi remote-ot"
        exit 0
    fi
fi

echo ""
log_warn "Előbb hozd létre a repository-t GitHub-on:"
echo ""
echo "  1. Menj ide: https://github.com/new"
echo "  2. Nevezd el: nincsenekfenyek (vagy amit szeretnél)"
echo "  3. Válaszd ki a visibility-t (public/private)"
echo "  4. NE inicializáld README, .gitignore vagy licencel"
echo "  5. Kattints 'Create repository'"
echo ""
read -p "Nyomj Enter-t, ha létrehoztad a repository-t..."

echo ""
log_info "Add meg a repository teljes elérési útját (pl: username/nincsenekfenyek)"
read -p "Repository path (username/repo-name): " repo_path

if [ -z "$repo_path" ]; then
    log_error "Repository path nem lehet üres!"
    exit 1
fi

# Build SSH URL
repo_url="git@github.com:${repo_path}.git"

echo ""
log_info "Remote repository beállítása: $repo_url"
git remote add origin "$repo_url"

echo ""
log_info "Branch neve ellenőrzése..."
current_branch=$(git branch --show-current)
if [ "$current_branch" != "main" ]; then
    log_info "Branch átnevezése main-re..."
    git branch -M main
fi

echo ""
read -p "Szeretnéd most feltölteni a kódot? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    log_info "Kód feltöltése SSH-val..."
    if git push -u origin main; then
        echo ""
        log_info "✅ Sikeresen feltöltve a GitHub repository-ba!"
        echo ""
        echo "Repository URL: https://github.com/${repo_path}"
    else
        log_error "Hiba történt a feltöltés során."
        log_info "Ellenőrizd:"
        echo "  - Létezik-e a repository GitHub-on?"
        echo "  - Van-e jogosultságod a repository-hoz?"
        echo "  - Működik-e az SSH kapcsolat? (ssh -T git@github.com)"
        exit 1
    fi
else
    log_info "Később feltöltheted a következő paranccsal:"
    echo "  git push -u origin main"
fi
