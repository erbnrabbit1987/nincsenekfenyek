#!/bin/bash

# GitHub Authentication Setup
# Segít beállítani az authentikációt GitHub-hoz

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

echo "=== GitHub Authentikáció Beállítása ==="
echo ""
echo "Válassz egy módszert:"
echo ""
echo "1) SSH kulcs (Ajánlott - hosszútávú megoldás)"
echo "2) GitHub Personal Access Token (HTTPS - gyors megoldás)"
echo ""
read -p "Választás (1 vagy 2): " auth_choice

case $auth_choice in
    1)
        echo ""
        log_info "SSH kulcs beállítása..."
        echo ""
        
        # Check if SSH key exists
        if [ ! -f ~/.ssh/id_ed25519 ] && [ ! -f ~/.ssh/id_rsa ]; then
            log_warn "Nincs SSH kulcs. Létrehozunk egyet..."
            echo ""
            read -p "Add meg az email címed: " email
            if [ -z "$email" ]; then
                email="bazsonyi.work@gmail.com"
            fi
            
            log_info "SSH kulcs generálása..."
            ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N ""
            
            log_info "SSH kulcs hozzáadása az ssh-agent-hez..."
            eval "$(ssh-agent -s)"
            ssh-add ~/.ssh/id_ed25519
        else
            log_info "SSH kulcs már létezik"
        fi
        
        # Display public key
        if [ -f ~/.ssh/id_ed25519.pub ]; then
            pub_key_file=~/.ssh/id_ed25519.pub
        elif [ -f ~/.ssh/id_rsa.pub ]; then
            pub_key_file=~/.ssh/id_rsa.pub
        fi
        
        echo ""
        log_info "Hozzá kell adnod ezt a kulcsot a GitHub-hoz:"
        echo ""
        cat "$pub_key_file"
        echo ""
        echo ""
        log_warn "Lépések:"
        echo "1. Másold ki a fenti SSH kulcsot"
        echo "2. Menj ide: https://github.com/settings/ssh/new"
        echo "3. Add hozzá a kulcsot"
        echo ""
        read -p "Nyomj Enter-t, ha hozzáadtad a kulcsot GitHub-hoz..."
        
        # Test connection
        echo ""
        log_info "GitHub SSH kapcsolat tesztelése..."
        if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            log_info "✅ SSH kapcsolat működik!"
            
            # Set remote to SSH
            current_remote=$(git remote get-url origin 2>/dev/null || echo "")
            if [ -n "$current_remote" ] && echo "$current_remote" | grep -q "https://"; then
                log_info "Remote URL átállítása SSH-ra..."
                repo_path=$(echo "$current_remote" | sed -E 's|.*github\.com[:/]([^/]+/[^/]+)(\.git)?/?$|\1|' | sed 's|\.git$||')
                git remote set-url origin "git@github.com:${repo_path}.git"
                log_info "✅ Remote URL átállítva SSH-ra"
            fi
        else
            log_error "SSH kapcsolat még nem működik. Ellenőrizd a kulcs hozzáadását."
        fi
        ;;
        
    2)
        echo ""
        log_info "GitHub Personal Access Token beállítása..."
        echo ""
        log_warn "Lépések:"
        echo "1. Menj ide: https://github.com/settings/tokens/new"
        echo "2. Adj nevet (pl: nincsenekfenyek)"
        echo "3. Válaszd ki a jogosultságokat:"
        echo "   - repo (full control)"
        echo "4. Generate token"
        echo "5. Másold ki a token-t (csak egyszer látható!)"
        echo ""
        read -p "Nyomj Enter-t, ha létrehoztad a token-t..."
        echo ""
        read -p "Add meg a token-t: " -s token
        echo ""
        
        if [ -z "$token" ]; then
            log_error "Token nem lehet üres!"
            exit 1
        fi
        
        # Set remote to HTTPS with token
        current_remote=$(git remote get-url origin 2>/dev/null || echo "")
        if [ -n "$current_remote" ]; then
            repo_path=$(echo "$current_remote" | sed -E 's|.*github\.com[:/]([^/]+/[^/]+)(\.git)?/?$|\1|' | sed 's|\.git$||')
            username=$(echo "$repo_path" | cut -d'/' -f1)
            repo_name=$(echo "$repo_path" | cut -d'/' -f2)
            git remote set-url origin "https://${username}:${token}@github.com/${repo_path}.git"
            log_info "✅ Remote URL beállítva token-nel"
        else
            log_warn "Nincs remote beállítva. Add hozzá manuálisan."
        fi
        
        log_warn "Fontos: A token a git config-ban van tárolva. Érdemes credential helper-t használni:"
        echo "  git config --global credential.helper osxkeychain"
        ;;
        
    *)
        log_error "Érvénytelen válasz"
        exit 1
        ;;
esac

echo ""
log_info "Készen vagy! Próbáld meg:"
echo "  git push -u origin main"


