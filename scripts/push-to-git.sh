#!/bin/bash

# Gyors Push Script
# Használd ezt, ha már be van állítva a remote repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Check if remote exists
if ! git remote | grep -q "origin"; then
    echo "❌ Nincs remote repository beállítva!"
    echo ""
    echo "Futtasd először:"
    echo "  ./scripts/setup-remote.sh"
    echo ""
    exit 1
fi

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  Van nem commitolt változás!"
    echo ""
    git status --short
    echo ""
    read -p "Szeretnéd commitolni ezeket a változásokat? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git add -A
        read -p "Commit üzenet: " commit_message
        git commit -m "$commit_message"
    else
        echo "Először commitold a változásokat, majd futtasd újra ezt a scriptet."
        exit 1
    fi
fi

# Get current branch
current_branch=$(git branch --show-current)
remote_url=$(git remote get-url origin)

echo "📤 Kód feltöltése..."
echo "   Branch: $current_branch"
echo "   Remote: $remote_url"
echo ""

git push -u origin "$current_branch"

echo ""
echo "✅ Sikeresen feltöltve!"
