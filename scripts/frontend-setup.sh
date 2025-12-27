#!/bin/bash

# Frontend Setup Script
# Installs dependencies and prepares the frontend for development

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FRONTEND_DIR="$PROJECT_ROOT/frontend"

cd "$PROJECT_ROOT"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Frontend Setup - Nincsenek Fények!                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js nincs telepítve!"
    echo "Telepítsd Node.js 20+ verziót: https://nodejs.org/"
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "⚠️  Node.js 18+ szükséges, jelenlegi: $(node --version)"
    echo "Telepítsd Node.js 20+ verziót: https://nodejs.org/"
    exit 1
fi

echo "✓ Node.js verzió: $(node --version)"
echo "✓ npm verzió: $(npm --version)"
echo ""

# Check if frontend directory exists
if [ ! -d "$FRONTEND_DIR" ]; then
    echo "❌ Frontend directory nem található: $FRONTEND_DIR"
    exit 1
fi

cd "$FRONTEND_DIR"

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "📝 .env fájl létrehozása..."
    cat > .env << EOF
# API Base URL
VITE_API_URL=http://localhost:8095/api
EOF
    echo "✓ .env fájl létrehozva"
fi

# Install dependencies
echo ""
echo "📦 Dependencies telepítése..."
npm install

echo ""
echo "✅ Frontend setup sikeres!"
echo ""
echo "Indítás fejlesztési módban:"
echo "  cd frontend && npm run dev"
echo ""
echo "Build production verzióhoz:"
echo "  cd frontend && npm run build"
echo ""

