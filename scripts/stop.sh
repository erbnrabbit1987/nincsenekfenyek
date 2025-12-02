#!/bin/bash

# Nincsenek Fények! - Stop Services Script

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

CLEAN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--clean)
            CLEAN=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

cd "$PROJECT_ROOT"

if [ "$CLEAN" = true ]; then
    log_warn "Stopping and removing all containers and volumes..."
    docker-compose down -v
    log_info "All services stopped and removed (including volumes) ✓"
else
    log_info "Stopping services..."
    docker-compose stop
    log_info "Services stopped ✓"
    echo ""
    echo "To remove containers: docker-compose down"
    echo "To remove containers and volumes: docker-compose down -v"
fi

