#!/bin/bash

# Teljes GitHub SSH Beállítás
# Új SSH kulcs generálása vagy meglévő használata

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

echo "=== GitHub SSH Teljes Beállítás ==="
echo ""

# Check if keys exist
if [ -f ~/.ssh/id_ed25519 ] || [ -f ~/.ssh/id_rsa ]; then
    log_info "Található SSH kulcs!"
    echo ""
    echo "Meglévő kulcs(ok):"
    ls -1 ~/.ssh/id_* 2>/dev/null | grep -v ".pub" || true
    echo ""
    read -p "Használjuk a meglévő kulcsot? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        USE_EXISTING=false
    else
        USE_EXISTING=true
    fi
else
    USE_EXISTING=false
fi

if [ "$USE_EXISTING" = false ]; then
    echo ""
    log_info "Új SSH kulcs generálása..."
    echo ""
    read -p "Add meg az email címed (GitHub email): " email
    if [ -z "$email" ]; then
        email="bazsonyi.work@gmail.com"
        log_info "Alapértelmezett email használata: $email"
    fi
    
    echo ""
    log_info "SSH kulcs generálása (Ed25519 algoritmussal)..."
    ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N ""
    
    log_info "✅ SSH kulcs sikeresen generálva!"
fi

# Find the key to use
if [ -f ~/.ssh/id_ed25519 ]; then
    PRIVATE_KEY=~/.ssh/id_ed25519
    PUBLIC_KEY=~/.ssh/id_ed25519.pub
elif [ -f ~/.ssh/id_rsa ]; then
    PRIVATE_KEY=~/.ssh/id_rsa
    PUBLIC_KEY=~/.ssh/id_rsa.pub
else
    log_error "Nem található SSH kulcs!"
    exit 1
fi

echo ""
echo "=== Publikus kulcs ==="
log_info "Itt a publikus kulcsod (add hozzá GitHub-hoz):"
echo ""
cat "$PUBLIC_KEY"
echo ""
echo ""

# Display fingerprint
echo "=== Kulcs fingerprint ==="
ssh-keygen -lf "$PUBLIC_KEY"
echo ""

log_warn "Lépések a GitHub-on:"
echo ""
echo "1. Menj ide: https://github.com/settings/ssh/new"
echo ""
echo "2. Add meg:"
echo "   - Title: $(hostname) - $(date +%Y-%m-%d)"
echo "   - Key: másold be a fenti publikus kulcsot"
echo ""
echo "3. Kattints: 'Add SSH key'"
echo ""

# Copy to clipboard if possible
if command -v pbcopy &> /dev/null; then
    read -p "Másoljam a vágólapra? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        cat "$PUBLIC_KEY" | pbcopy
        log_info "✅ Publikus kulcs másolva a vágólapra!"
    fi
fi

echo ""
read -p "Nyomj Enter-t, ha hozzáadtad a kulcsot GitHub-hoz..."

# Start ssh-agent
echo ""
log_info "SSH agent beállítása..."
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
    log_info "SSH agent elindítva"
fi

# Add key to ssh-agent
echo ""
log_info "Kulcs hozzáadása az ssh-agent-hez..."
ssh-add "$PRIVATE_KEY"

# Test connection
echo ""
log_info "GitHub SSH kapcsolat tesztelése..."
echo ""

if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated\|Hi.*You've successfully authenticated"; then
    log_info "✅ SSH kapcsolat működik GitHub-hoz!"
    echo ""
    
    # Ensure remote uses SSH
    cd "$(dirname "$0")/.."
    if git remote | grep -q "origin"; then
        current_url=$(git remote get-url origin)
        if echo "$current_url" | grep -q "https://"; then
            log_info "Remote URL átállítása SSH-ra..."
            repo_path=$(echo "$current_url" | sed -E 's|.*github\.com[:/]([^/]+/[^/]+)(\.git)?/?$|\1|' | sed 's|\.git$||')
            git remote set-url origin "git@github.com:${repo_path}.git"
            log_info "✅ Remote URL átállítva SSH-ra"
        fi
    fi
    
    echo ""
    log_info "🎉 Készen vagy! Most már pusholhatsz:"
    echo "  git push -u origin main"
else
    log_warn "SSH kapcsolat tesztelése..."
    ssh_output=$(ssh -T git@github.com 2>&1)
    echo "$ssh_output"
    echo ""
    
    if echo "$ssh_output" | grep -q "Permission denied"; then
        log_error "Hozzáférés megtagadva. Ellenőrizd:"
        echo "  1. Hozzáadtad a kulcsot GitHub-hoz?"
        echo "  2. A kulcs fingerprint egyezik?"
    fi
fi


