#!/bin/bash
# ===========================================
# Nincsenek Fények! - Issue Template-ek Feltöltése
# ===========================================
# Ez a script segít feltölteni az issue template-eket a GitHub-ra
# ===========================================

set -e

# Színek
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script könyvtár
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATES_DIR="${PROJECT_ROOT}/.github/ISSUE_TEMPLATE"

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Ellenőrzések
check_requirements() {
    log "Követelmények ellenőrzése..."
    
    if [ ! -d "${TEMPLATES_DIR}" ]; then
        error "Issue template könyvtár nem található: ${TEMPLATES_DIR}"
        exit 1
    fi
    
    if command -v gh &> /dev/null; then
        log "GitHub CLI (gh) található"
        if ! gh auth status &> /dev/null; then
            error "GitHub CLI nincs bejelentkezve! Futtasd: gh auth login"
            exit 1
        fi
    else
        error "GitHub CLI (gh) nincs telepítve!"
        error "Telepítsd: https://cli.github.com/"
        exit 1
    fi
    
    log "✓ Minden követelmény teljesül"
}

# Template fájlok listázása
list_templates() {
    find "${TEMPLATES_DIR}" -name "*.yml" -o -name "*.yaml" | sort
}

# Fő függvény
main() {
    echo "=========================================="
    echo "📋 Issue Template-ek Feltöltése"
    echo "=========================================="
    echo ""
    
    check_requirements
    
    local repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
    log "Repository: $repo"
    echo ""
    
    # Template fájlok listája
    log "Template fájlok keresése..."
    local templates=$(list_templates)
    local template_count=$(echo "$templates" | grep -v '^$' | wc -l | tr -d ' ')
    
    if [ "$template_count" -eq 0 ]; then
        error "Nem található template fájl!"
        exit 1
    fi
    
    log "Talált template fájlok: $template_count"
    echo ""
    
    echo "Template fájlok:"
    echo "$templates" | while read -r template; do
        echo "  - $(basename "$template")"
    done
    echo ""
    
    log "⚠️  Megjegyzés:"
    echo ""
    echo "Az issue template-eket a Git repository-ba kell commitolni."
    echo "A GitHub automatikusan felismeri a .github/ISSUE_TEMPLATE/ könyvtárban lévő fájlokat."
    echo ""
    echo "Lépések:"
    echo "  1. Commitold a template fájlokat"
    echo "  2. Pushold a GitHub-ra"
    echo "  3. A template-ek automatikusan elérhetők lesznek a GitHub issue oldalon"
    echo ""
    
    read -p "Szeretnéd ellenőrizni, hogy minden template fájl commitolva van? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo ""
        log "Git állapot ellenőrzése..."
        
        cd "$PROJECT_ROOT"
        local untracked=$(git status --porcelain .github/ISSUE_TEMPLATE/ 2>/dev/null | grep "^??" || true)
        local modified=$(git status --porcelain .github/ISSUE_TEMPLATE/ 2>/dev/null | grep "^ M" || true)
        
        if [ -n "$untracked" ] || [ -n "$modified" ]; then
            warning "Van nem commitolt template fájl!"
            echo ""
            git status .github/ISSUE_TEMPLATE/
            echo ""
            read -p "Szeretnéd commitolni és pusholni a template-eket? (Y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                git add .github/ISSUE_TEMPLATE/
                git commit -m "feat: Add GitHub issue templates

- Add bug report templates (API, Source, Collection, Fact-check, Deploy, Security)
- Add config.yml for issue template configuration
- Templates for structured bug reporting"
                
                log "Commit kész! Push-olni szeretnéd? (Y/n): "
                read -p "" -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                    git push
                    log "✓ Template-ek feltöltve a GitHub-ra!"
                    echo ""
                    log "A template-ek mostantól elérhetők:"
                    echo "  https://github.com/$repo/issues/new"
                fi
            fi
        else
            log "✓ Minden template fájl már commitolva van!"
        fi
    fi
    
    echo ""
    log "Kész! A template-ek elérhetők lesznek a GitHub issue oldalon."
}

# Script futtatása
main "$@"

