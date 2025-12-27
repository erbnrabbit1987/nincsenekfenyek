#!/bin/bash

# SSH GitHub Connection Check Script
# Segít ellenőrizni és beállítani az SSH kapcsolatot GitHub-hoz

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

echo "=== GitHub SSH Kapcsolat Ellenőrzése ==="
echo ""

# Check SSH keys
echo "1. SSH kulcsok ellenőrzése..."
if [ -f ~/.ssh/id_rsa.pub ] || [ -f ~/.ssh/id_ed25519.pub ]; then
    log_info "SSH kulcs(ok) találva:"
    ls -1 ~/.ssh/*.pub 2>/dev/null | while read key; do
        echo "   - $key"
    done
else
    log_warn "Nem található SSH publikus kulcs!"
    log_info "Hozz létre egyet:"
    echo "   ssh-keygen -t ed25519 -C \"your_email@example.com\""
    exit 1
fi

echo ""
echo "2. SSH kulcs hozzáadása az ssh-agent-hez..."
if ! ssh-add -l &>/dev/null; then
    log_warn "Nincs kulcs betöltve az ssh-agent-be"
    
    # Try to add keys
    if [ -f ~/.ssh/id_ed25519 ]; then
        ssh-add ~/.ssh/id_ed25519 2>/dev/null || log_warn "Nem sikerült betölteni ~/.ssh/id_ed25519"
    fi
    if [ -f ~/.ssh/id_rsa ]; then
        ssh-add ~/.ssh/id_rsa 2>/dev/null || log_warn "Nem sikerült betölteni ~/.ssh/id_rsa"
    fi
else
    log_info "SSH kulcs(ok) betöltve az ssh-agent-be ✓"
    ssh-add -l
fi

echo ""
echo "3. GitHub SSH kapcsolat tesztelése..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    log_info "✅ SSH kapcsolat működik GitHub-hoz!"
    exit 0
else
    log_error "❌ SSH kapcsolat nem működik GitHub-hoz"
    echo ""
    echo "Ellenőrizd:"
    echo ""
    echo "1. Hozzáadtad az SSH kulcsot a GitHub-hoz?"
    echo "   - Másold ki a publikus kulcsot:"
    echo ""
    if [ -f ~/.ssh/id_ed25519.pub ]; then
        echo "   cat ~/.ssh/id_ed25519.pub"
        echo ""
        log_info "Itt a publikus kulcsod (másold ki és add hozzá GitHub-hoz):"
        echo ""
        cat ~/.ssh/id_ed25519.pub
    elif [ -f ~/.ssh/id_rsa.pub ]; then
        echo "   cat ~/.ssh/id_rsa.pub"
        echo ""
        log_info "Itt a publikus kulcsod (másold ki és add hozzá GitHub-hoz):"
        echo ""
        cat ~/.ssh/id_rsa.pub
    fi
    echo ""
    echo "2. GitHub-on:"
    echo "   - Settings → SSH and GPG keys → New SSH key"
    echo "   - Add hozzá a fenti kulcsot"
    echo ""
    echo "3. Utána futtasd újra ezt a scriptet:"
    echo "   ./scripts/check-ssh-github.sh"
    echo ""
    exit 1
fi


