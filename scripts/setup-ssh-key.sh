#!/bin/bash

# SSH Key Setup Script
# Beállítja az SSH kulcsot az ssh-agent-be

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

echo "=== SSH Kulcs Beállítása ==="
echo ""

# Find SSH keys
echo "1. SSH kulcsok keresése..."
ssh_keys=()
if [ -f ~/.ssh/id_ed25519 ]; then
    ssh_keys+=("~/.ssh/id_ed25519")
fi
if [ -f ~/.ssh/id_rsa ]; then
    ssh_keys+=("~/.ssh/id_rsa")
fi

if [ ${#ssh_keys[@]} -eq 0 ]; then
    log_error "Nem található SSH kulcs!"
    echo ""
    echo "SSH kulcsok keresése máshol..."
    find ~/.ssh -type f -name "id_*" ! -name "*.pub" 2>/dev/null | while read key; do
        echo "  Talált kulcs: $key"
        ssh_keys+=("$key")
    done
fi

if [ ${#ssh_keys[@]} -eq 0 ]; then
    log_error "Nincs SSH kulcs a ~/.ssh könyvtárban!"
    exit 1
fi

# Start ssh-agent if not running
echo ""
echo "2. SSH agent indítása..."
if [ -z "$SSH_AUTH_SOCK" ]; then
    log_info "SSH agent elindítása..."
    eval "$(ssh-agent -s)"
    
    # Add to shell profile
    if [ -f ~/.zshrc ]; then
        if ! grep -q "ssh-agent" ~/.zshrc; then
            echo "" >> ~/.zshrc
            echo "# SSH Agent" >> ~/.zshrc
            echo 'eval "$(ssh-agent -s)"' >> ~/.zshrc
        fi
    fi
else
    log_info "SSH agent már fut ✓"
fi

# Add keys to ssh-agent
echo ""
echo "3. SSH kulcs(ok) hozzáadása az ssh-agent-hez..."

for key_path in "${ssh_keys[@]}"; do
    # Expand ~ to home directory
    key_path="${key_path/#\~/$HOME}"
    
    if [ -f "$key_path" ]; then
        log_info "Kulcs hozzáadása: $key_path"
        ssh-add "$key_path" 2>/dev/null || log_warn "Nem sikerült hozzáadni: $key_path"
    fi
done

echo ""
echo "4. Betöltött kulcsok:"
ssh-add -l || log_warn "Nincs kulcs betöltve"

echo ""
echo "5. GitHub SSH kapcsolat tesztelése..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated\|Hi"; then
    log_info "✅ SSH kapcsolat működik GitHub-hoz!"
    echo ""
    log_info "Most már pusholhatsz:"
    echo "  git push -u origin main"
else
    log_warn "SSH kapcsolat tesztelése..."
    ssh -T git@github.com 2>&1 || true
    echo ""
    log_warn "Ha nem működik, ellenőrizd:"
    echo "  1. A kulcs hozzá van adva GitHub-hoz: https://github.com/settings/ssh"
    echo "  2. A kulcs jó formátumú"
    echo ""
    echo "Publikus kulcs megjelenítése:"
    for key_path in "${ssh_keys[@]}"; do
        key_path="${key_path/#\~/$HOME}"
        if [ -f "${key_path}.pub" ]; then
            echo ""
            echo "Kulcs: ${key_path}.pub"
            cat "${key_path}.pub"
        fi
    done
fi

