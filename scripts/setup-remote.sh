#!/bin/bash

# Git Remote Setup Script
# Ez a script segít beállítani a remote repository-t és feltölteni a kódot

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

log_question() {
    echo -e "${BLUE}[?]${NC} $1"
}

cd "$PROJECT_ROOT"

echo "=== Git Remote Repository Beállítás ==="
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
log_question "Milyen git szolgáltatást használsz?"
echo "1) GitHub"
echo "2) GitLab"
echo "3) Egyéb (saját URL)"
echo ""
read -p "Válasz (1-3): " service_choice

case $service_choice in
    1)
        echo ""
        log_question "Add meg a GitHub felhasználóneved vagy szervezet neved:"
        read -p "Username/Org: " username
        echo ""
        log_question "Létrehoztad már a repository-t GitHub-on? (y/N):"
        read -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_warn "Először hozd létre a repository-t GitHub-on:"
            echo "  1. Menj ide: https://github.com/new"
            echo "  2. Nevezd el: nincsenekfenyek"
            echo "  3. Ne inicializáld README, .gitignore vagy licencel"
            echo "  4. Kattints 'Create repository'"
            echo ""
            read -p "Nyomj Enter-t, ha létrehoztad a repository-t..."
        fi
        repo_url="https://github.com/${username}/nincsenekfenyek.git"
        ;;
    2)
        echo ""
        log_question "Add meg a GitLab felhasználóneved vagy szervezet neved:"
        read -p "Username/Org: " username
        echo ""
        log_question "Létrehoztad már a repository-t GitLab-on? (y/N):"
        read -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_warn "Először hozd létre a repository-t GitLab-on:"
            echo "  1. Menj a GitLab projektedhez"
            echo "  2. Kattints 'New project'"
            echo "  3. Válaszd 'Create blank project'"
            echo "  4. Nevezd el: nincsenekfenyek"
            echo ""
            read -p "Nyomj Enter-t, ha létrehoztad a repository-t..."
        fi
        repo_url="https://gitlab.com/${username}/nincsenekfenyek.git"
        ;;
    3)
        echo ""
        log_question "Add meg a teljes repository URL-t:"
        read -p "Repository URL: " repo_url
        ;;
    *)
        log_error "Érvénytelen válasz"
        exit 1
        ;;
esac

echo ""
log_info "Remote repository hozzáadása: $repo_url"
git remote add origin "$repo_url"

echo ""
log_info "Branch neve ellenőrzése..."
current_branch=$(git branch --show-current)
if [ "$current_branch" != "main" ]; then
    log_info "Branch átnevezése main-re..."
    git branch -M main
fi

echo ""
log_question "Szeretnéd most feltölteni a kódot? (Y/n):"
read -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    log_info "Kód feltöltése..."
    git push -u origin main
    echo ""
    log_info "✅ Sikeresen feltöltve a remote repository-ba!"
    echo ""
    echo "Repository URL: $repo_url"
else
    log_info "Később feltöltheted a következő paranccsal:"
    echo "  git push -u origin main"
fi

