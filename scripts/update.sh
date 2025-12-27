#!/bin/bash

# Nincsenek Fények! - Update Services Script

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

# Pull latest changes
log_info "Pulling latest code changes..."
if [ -d ".git" ]; then
    git pull
    log_info "Code updated ✓"
else
    log_warn "Not a git repository, skipping git pull"
fi

# Pull latest Docker images
log_info "Pulling latest Docker images..."
docker-compose pull

# Rebuild if needed
log_info "Rebuilding services..."
docker-compose build

# Restart services
log_info "Restarting services..."
docker-compose up -d

log_info "Services updated and restarted ✓"
log_info "Check status with: ./scripts/status.sh"


