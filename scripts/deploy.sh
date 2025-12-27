#!/bin/bash

# Nincsenek Fények! - Deployment Script
# Ez a script segít a projekt telepítésében és futtatásában

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default values
ENVIRONMENT="development"
BUILD=false
CLEAN=false
HELP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -b|--build)
            BUILD=true
            shift
            ;;
        -c|--clean)
            # Note: Cleanup now happens automatically at the start
            # This flag is kept for backward compatibility but has no effect
            log_warn "Note: Container cleanup now happens automatically. This flag has no effect."
            shift
            ;;
        -h|--help)
            HELP=true
            shift
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Help message
if [ "$HELP" = true ]; then
    echo "Nincsenek Fények! - Deployment Script"
    echo ""
    echo "Usage: ./scripts/deploy.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -e, --environment ENV   Deployment environment (development|production) [default: development]"
    echo "  -b, --build            Build Docker images before deployment"
    echo "  -c, --clean            Clean up containers and volumes before deployment"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./scripts/deploy.sh                          # Development deployment"
    echo "  ./scripts/deploy.sh -e production -b        # Production with build"
    echo "  ./scripts/deploy.sh -c                       # Clean deployment"
    echo ""
    echo "Note:"
    echo "  If .env file is missing, the script will prompt for interactive creation."
    echo "  You can also manually run: ./scripts/interactive-env-setup.sh"
    exit 0
fi

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    
    log_info "Prerequisites check passed ✓"
}

check_env_file() {
    log_info "Checking environment configuration..."
    
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        log_warn ".env file not found."
        
        # Interaktív .env létrehozás opció
        if [ -f "$PROJECT_ROOT/scripts/interactive-env-setup.sh" ]; then
            echo ""
            echo "Válassz egy opciót:"
            echo "  1) Interaktív .env létrehozás (ajánlott)"
            echo "  2) .env.example másolása"
            echo "  3) Kihagyás (folytatás .env nélkül)"
            read -p "Választás [1-3] (1): " env_choice
            env_choice="${env_choice:-1}"
            
            case $env_choice in
                1)
                    log_info "Interaktív .env létrehozás indítása..."
                    "$PROJECT_ROOT/scripts/interactive-env-setup.sh"
                    if [ $? -eq 0 ] && [ -f "$PROJECT_ROOT/.env" ]; then
                        log_info "Environment file created ✓"
                        return 0
                    else
                        log_error "Failed to create .env file interactively"
                        exit 1
                    fi
                    ;;
                2)
                    if [ -f "$PROJECT_ROOT/.env.example" ]; then
                        cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
                        log_warn "Please edit .env file with your configuration before continuing."
                        log_warn "Press Enter to continue or Ctrl+C to cancel..."
                        read -r
                    else
                        log_error ".env.example file not found. Cannot create .env file."
                        exit 1
                    fi
                    ;;
                3)
                    log_warn "Continuing without .env file..."
                    return 0
                    ;;
            esac
        elif [ -f "$PROJECT_ROOT/.env.example" ]; then
            cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
            log_warn "Please edit .env file with your configuration before continuing."
            log_warn "Press Enter to continue or Ctrl+C to cancel..."
            read -r
        else
            log_error ".env.example file not found. Cannot create .env file."
            log_error "Please create .env file manually or run: ./scripts/interactive-env-setup.sh"
            exit 1
        fi
    else
        log_info "Environment file found ✓"
    fi
}

cleanup_existing_containers() {
    log_info "Cleaning up existing containers and services..."
    
    cd "$PROJECT_ROOT"
    
    # First, try to stop containers gracefully, then force remove
    log_info "Listing all containers with project name..."
    local containers=$(docker ps -a --filter "name=nincsenekfenyek" --format "{{.Names}}" 2>/dev/null || true)
    
    if [ -n "$containers" ]; then
        log_info "Found containers:"
        echo "$containers" | while read -r container; do
            if [ -n "$container" ]; then
                echo "  - $container ($(docker ps -a --filter "name=^${container}$" --format '{{.Status}}' 2>/dev/null || echo 'unknown status'))"
            fi
        done
        
        log_info "Step 1: Stopping containers gracefully..."
        echo "$containers" | while read -r container; do
            if [ -n "$container" ]; then
                log_info "  Stopping: $container"
                timeout 5 docker stop "$container" 2>&1 | head -5 || log_warn "  Failed to stop $container (will force remove)"
            fi
        done
        
        log_info "Step 2: Force removing containers (with timeout)..."
        echo "$containers" | while read -r container; do
            if [ -n "$container" ]; then
                log_info "  Force removing: $container"
                # Use timeout to prevent hanging (10 seconds max per container)
                if timeout 10 docker rm -f "$container" 2>&1; then
                    log_info "  ✓ Removed: $container"
                else
                    log_warn "  ✗ Failed to remove: $container (may be stuck, trying kill signal)"
                    # Try sending kill signal directly
                    docker kill "$container" 2>/dev/null || true
                    sleep 1
                    timeout 5 docker rm -f "$container" 2>/dev/null || log_error "  ✗✗ Could not remove: $container"
                fi
            fi
        done
        log_info "Container removal process completed ✓"
    else
        log_info "No containers found to remove ✓"
    fi
    
    # Now try docker compose down (with timeout to avoid hanging)
    log_info "Step 3: Cleaning up Docker Compose resources..."
    # Try docker compose first (newer version), fallback to docker-compose
    if command -v docker &> /dev/null && docker compose version > /dev/null 2>&1; then
        log_info "  Using 'docker compose down --remove-orphans' (timeout: 15s)..."
        if timeout 15 docker compose down --remove-orphans 2>&1; then
            log_info "  ✓ Docker Compose cleanup successful"
        else
            log_warn "  ✗ Docker Compose cleanup timed out or failed (continuing anyway)"
        fi
    else
        log_info "  Using 'docker-compose down --remove-orphans' (timeout: 15s)..."
        if timeout 15 docker-compose down --remove-orphans 2>&1; then
            log_info "  ✓ Docker Compose cleanup successful"
        else
            log_warn "  ✗ Docker Compose cleanup timed out or failed (continuing anyway)"
        fi
    fi
    
    # Final cleanup: remove any remaining containers (force with timeout)
    log_info "Step 4: Final cleanup - checking for remaining containers..."
    local remaining=$(docker ps -a --filter "name=nincsenekfenyek" --format "{{.Names}}" 2>/dev/null || true)
    if [ -n "$remaining" ]; then
        log_warn "  Found remaining containers:"
        echo "$remaining" | while read -r container; do
            if [ -n "$container" ]; then
                log_warn "    - $container"
                log_info "    Attempting final force remove (timeout: 5s)..."
                timeout 5 docker rm -f "$container" 2>&1 || log_error "    ✗ Could not remove: $container (may need manual removal)"
            fi
        done
    else
        log_info "  ✓ No remaining containers found"
    fi
    
    log_info "Container cleanup completed ✓"
}

check_and_free_port() {
    local port=$1
    local port_name=$2
    
    log_info "Checking if port $port ($port_name) is available..."
    
    # Check if port is in use
    local port_in_use=false
    
    # Try different methods to check port availability
    if command -v lsof &> /dev/null; then
        if lsof -i :$port &> /dev/null; then
            port_in_use=true
        fi
    elif command -v netstat &> /dev/null; then
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            port_in_use=true
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln 2>/dev/null | grep -q ":$port "; then
            port_in_use=true
        fi
    else
        # Fallback: check if Docker container is using the port
        local container_using_port=$(docker ps --filter "publish=$port" --format "{{.Names}}" 2>/dev/null || true)
        if [ -n "$container_using_port" ]; then
            port_in_use=true
            log_info "  Found container using port: $container_using_port"
        fi
    fi
    
    if [ "$port_in_use" = true ]; then
        log_warn "Port $port is already in use!"
        
        # Try to find and stop containers using this port
        log_info "  Searching for containers using port $port..."
        local containers=$(docker ps --filter "publish=$port" --format "{{.Names}}" 2>/dev/null || true)
        
        if [ -z "$containers" ]; then
            # Try alternative method: check all containers
            containers=$(docker ps -a --format "{{.Names}}" | while read -r name; do
                docker port "$name" 2>/dev/null | grep -q ":$port" && echo "$name"
            done || true)
        fi
        
        if [ -n "$containers" ]; then
            log_info "  Found containers using port $port:"
            echo "$containers" | while read -r container; do
                if [ -n "$container" ]; then
                    log_info "    - $container"
                    log_info "    Stopping and removing container..."
                    timeout 10 docker stop "$container" 2>/dev/null || true
                    timeout 5 docker rm -f "$container" 2>/dev/null || true
                    log_info "    ✓ Container removed: $container"
                fi
            done
            
            # Wait a moment for port to be released
            sleep 2
            
            # Verify port is now free
            if command -v lsof &> /dev/null; then
                if ! lsof -i :$port &> /dev/null; then
                    log_info "  ✓ Port $port is now available"
                    return 0
                fi
            fi
        fi
        
        log_warn "  Port $port may still be in use. Trying to continue anyway..."
        log_warn "  If deployment fails, manually stop the process using port $port:"
        log_warn "    - Find process: sudo lsof -i :$port"
        log_warn "    - Or: sudo netstat -tulpn | grep :$port"
        log_warn "    - Stop it: sudo kill -9 <PID>"
        return 1
    else
        log_info "  ✓ Port $port is available"
        return 0
    fi
}

build_images() {
    if [ "$BUILD" = true ]; then
        log_info "Building Docker images..."
        cd "$PROJECT_ROOT"
        docker-compose build --no-cache
        log_info "Build completed ✓"
    else
        # Always build frontend even without --build flag, as it needs npm install
        log_info "Building frontend Docker image (always required)..."
        cd "$PROJECT_ROOT"
        docker-compose build frontend
        log_info "Frontend build completed ✓"
    fi
}

create_directories() {
    log_info "Creating necessary directories..."
    mkdir -p "$PROJECT_ROOT/logs"
    mkdir -p "$PROJECT_ROOT/data/mongodb"
    mkdir -p "$PROJECT_ROOT/data/mongodb-config"
    mkdir -p "$PROJECT_ROOT/data/postgres"
    mkdir -p "$PROJECT_ROOT/data/redis"
    log_info "Directories created ✓"
    log_info "Database data will be stored in: $PROJECT_ROOT/data/"
}

deploy_services() {
    log_info "Deploying services for $ENVIRONMENT environment..."
    cd "$PROJECT_ROOT"
    
    if [ "$ENVIRONMENT" = "production" ]; then
        log_info "Starting production deployment..."
        docker-compose -f docker-compose.yml up -d
    else
        log_info "Starting development deployment..."
        docker-compose up -d
    fi
    
    log_info "Services deployment initiated ✓"
}

wait_for_services() {
    log_info "Waiting for services to be healthy..."
    
    max_attempts=30
    attempt=0
    backend_ready=false
    frontend_ready=false
    
    while [ $attempt -lt $max_attempts ]; do
        if docker-compose ps | grep -q "Up"; then
            sleep 2
            
            # Check backend
            if [ "$backend_ready" = false ] && curl -f http://localhost:8095/health &> /dev/null; then
                log_info "Backend API is healthy ✓"
                backend_ready=true
            fi
            
            # Check frontend
            if [ "$frontend_ready" = false ] && curl -f http://localhost:8075 &> /dev/null; then
                log_info "Frontend is healthy ✓"
                frontend_ready=true
            fi
            
            # If both are ready, we can exit
            if [ "$backend_ready" = true ] && [ "$frontend_ready" = true ]; then
                break
            fi
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    echo ""
    
    if [ "$backend_ready" = false ]; then
        log_warn "Backend API is taking longer than expected to start."
    fi
    if [ "$frontend_ready" = false ]; then
        log_warn "Frontend is taking longer than expected to start."
    fi
    if [ $attempt -eq $max_attempts ]; then
        log_warn "Some services are taking longer than expected to start."
        log_warn "Check logs with: docker-compose logs -f"
    fi
}

show_status() {
    log_info "Service Status:"
    cd "$PROJECT_ROOT"
    docker-compose ps
    
    echo ""
    log_info "Service URLs:"
    echo "  - Frontend: http://localhost:8075"
    echo "  - Backend API: http://localhost:8095"
    echo "  - API Docs: http://localhost:8095/docs"
    echo "  - MongoDB: mongodb://localhost:27017"
    echo "  - PostgreSQL: postgresql://postgres:postgres@localhost:5432/nincsenekfenyek"
    echo "  - Redis: redis://localhost:6379"
    echo ""
    log_info "Useful commands:"
    echo "  - View logs: docker-compose logs -f"
    echo "  - Stop services: docker-compose stop"
    echo "  - Restart services: docker-compose restart"
    echo "  - Remove services: docker-compose down"
}

# Main deployment flow
main() {
    log_info "Starting deployment process..."
    echo ""
    
    check_prerequisites
    cleanup_existing_containers
    
    # Check and free up required ports
    check_and_free_port 8095 "Backend API"
    check_and_free_port 8075 "Frontend" || true  # Don't fail if Frontend port is busy
    check_and_free_port 27017 "MongoDB" || true  # Don't fail if MongoDB port is busy
    check_and_free_port 5432 "PostgreSQL" || true  # Don't fail if PostgreSQL port is busy
    check_and_free_port 6379 "Redis" || true  # Don't fail if Redis port is busy
    
    check_env_file
    create_directories
    build_images
    deploy_services
    wait_for_services
    show_status
    
    echo ""
    log_info "Deployment completed successfully! 🎉"
}

# Run main function
main

