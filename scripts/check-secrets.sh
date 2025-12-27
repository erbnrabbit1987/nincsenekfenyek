#!/bin/bash

# Secrets Check Script
# Ellenőrzi, hogy nincs-e bizalmas információ a repository-ban

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

echo "=== Bizalmas Adatok Ellenőrzése ==="
echo ""

FOUND_ISSUES=false

# Check for SSH keys
echo "1. SSH kulcsok ellenőrzése..."
if git ls-files | grep -qE "(id_rsa|id_ed25519|\.ssh/|\.pub$)"; then
    log_error "❌ SSH kulcsok találhatók a repository-ban!"
    git ls-files | grep -E "(id_rsa|id_ed25519|\.ssh/|\.pub$)"
    FOUND_ISSUES=true
else
    log_info "✅ Nincs SSH kulcs a repository-ban"
fi

# Check for .env files
echo ""
echo "2. .env fájlok ellenőrzése..."
if git ls-files | grep -q "^\.env$"; then
    log_error "❌ .env fájl a repository-ban!"
    git ls-files | grep "^\.env$"
    FOUND_ISSUES=true
elif git ls-files | grep -q "\.env\."; then
    log_warn "⚠️  .env.* fájlok találhatók (lehet, hogy csak .env.example kellene)"
    git ls-files | grep "\.env\."
else
    log_info "✅ Nincs .env fájl a repository-ban"
fi

# Check for secrets
echo ""
echo "3. Secret fájlok ellenőrzése..."
if git ls-files | grep -iqE "(secret|key|token|password|credential|\.pem|\.key)"; then
    log_warn "⚠️  Lehetséges secret fájlok:"
    git ls-files | grep -iE "(secret|key|token|password|credential|\.pem|\.key)" | grep -v ".gitignore" || true
    # Don't mark as error, might be false positives
fi

# Check for passwords in files
echo ""
echo "4. Jelszavak keresése fájlokban..."
if git ls-files | while read file; do
    if [ -f "$file" ]; then
        if grep -qiE "(password|secret|token)\s*[:=]\s*['\"][^'\"]{8,}" "$file" 2>/dev/null; then
            echo "$file"
        fi
    fi
done | head -5 | grep -q .; then
    log_warn "⚠️  Lehetséges jelszavak találhatók fájlokban:"
    git ls-files | while read file; do
        if [ -f "$file" ]; then
            if grep -qiE "(password|secret|token)\s*[:=]\s*['\"][^'\"]{8,}" "$file" 2>/dev/null; then
                echo "  - $file"
            fi
        fi
    done
fi

# Check .gitignore
echo ""
echo "5. .gitignore ellenőrzése..."
if [ -f .gitignore ]; then
    if grep -qE "(\.ssh|id_rsa|id_ed25519|\.env)" .gitignore; then
        log_info "✅ .gitignore tartalmaz SSH és .env szabályokat"
    else
        log_warn "⚠️  .gitignore nem tartalmaz minden szükséges szabályt"
    fi
else
    log_warn "⚠️  Nincs .gitignore fájl!"
fi

# Summary
echo ""
echo "=== Összefoglaló ==="
if [ "$FOUND_ISSUES" = true ]; then
    log_error "❌ Bizalmas információk találhatók a repository-ban!"
    echo ""
    echo "Töröld őket a repository-ból:"
    echo "  git rm --cached <file>"
    echo ""
    exit 1
else
    log_info "✅ Nincs bizalmas információ a repository-ban"
    echo ""
    echo "Biztonságos a push!"
fi


