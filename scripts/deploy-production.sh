#!/bin/bash

# Nincsenek Fények! - Production Deployment Script
# Biztonságos production deployment script

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

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    log_error "This script should be run as root or with sudo for production deployment"
    exit 1
fi

# Production checks
log_info "Running production deployment checks..."

# Check .env.production exists
if [ ! -f "$PROJECT_ROOT/.env.production" ]; then
    log_error ".env.production file not found!"
    log_error "Create .env.production with production configuration."
    exit 1
fi

# Backup existing data
log_info "Creating backup..."
BACKUP_DIR="$PROJECT_ROOT/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

if docker-compose ps | grep -q "Up"; then
    log_info "Backing up MongoDB..."
    docker-compose exec -T mongodb mongodump --archive > "$BACKUP_DIR/mongodb_backup.archive" || true
    
    log_info "Backing up PostgreSQL..."
    docker-compose exec -T postgres pg_dump -U postgres nincsenekfenyek > "$BACKUP_DIR/postgres_backup.sql" || true
fi

# Use production environment file
export $(cat "$PROJECT_ROOT/.env.production" | xargs)

# Build and deploy
cd "$PROJECT_ROOT"

log_info "Building production images..."
docker-compose -f docker-compose.yml build --no-cache

log_info "Stopping existing services..."
docker-compose down

log_info "Starting production services..."
docker-compose -f docker-compose.yml up -d

log_info "Production deployment completed!"
log_info "Backup saved to: $BACKUP_DIR"

