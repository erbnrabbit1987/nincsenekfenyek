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
    
    # Stop and remove all containers, networks (but keep volumes - data is now in ./data/)
    if docker compose ps -q > /dev/null 2>&1 || docker-compose ps -q > /dev/null 2>&1; then
        log_info "Stopping existing containers..."
        # Try docker compose first (newer version), fallback to docker-compose
        if command -v docker &> /dev/null && docker compose version > /dev/null 2>&1; then
            docker compose down 2>/dev/null || true
        else
            docker-compose down 2>/dev/null || true
        fi
        log_info "Existing containers stopped and removed ✓"
    else
        log_info "No existing containers found ✓"
    fi
    
    # Remove any orphaned containers with project name (safety check)
    if docker ps -a --filter "name=nincsenekfenyek" --format "{{.Names}}" 2>/dev/null | grep -q .; then
        log_info "Cleaning up orphaned containers..."
        docker ps -a --filter "name=nincsenekfenyek" --format "{{.Names}}" | xargs -r docker rm -f 2>/dev/null || true
        log_info "Orphaned containers removed ✓"
    fi
}

build_images() {
    if [ "$BUILD" = true ]; then
        log_info "Building Docker images..."
        cd "$PROJECT_ROOT"
        docker-compose build --no-cache
        log_info "Build completed ✓"
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
    
    while [ $attempt -lt $max_attempts ]; do
        if docker-compose ps | grep -q "Up"; then
            sleep 2
            if curl -f http://localhost:8000/health &> /dev/null; then
                log_info "Backend API is healthy ✓"
                break
            fi
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    echo ""
    
    if [ $attempt -eq $max_attempts ]; then
        log_warn "Services are taking longer than expected to start."
        log_warn "Check logs with: docker-compose logs -f"
    fi
}

show_status() {
    log_info "Service Status:"
    cd "$PROJECT_ROOT"
    docker-compose ps
    
    echo ""
    log_info "Service URLs:"
    echo "  - Backend API: http://localhost:8000"
    echo "  - API Docs: http://localhost:8000/docs"
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

