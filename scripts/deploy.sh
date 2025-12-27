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
            CLEAN=true
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
        log_warn ".env file not found. Creating from .env.example..."
        if [ -f "$PROJECT_ROOT/.env.example" ]; then
            cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
            log_warn "Please edit .env file with your configuration before continuing."
            log_warn "Press Enter to continue or Ctrl+C to cancel..."
            read -r
        else
            log_error ".env.example file not found. Cannot create .env file."
            exit 1
        fi
    else
        log_info "Environment file found ✓"
    fi
}

cleanup() {
    if [ "$CLEAN" = true ]; then
        log_info "Cleaning up existing containers and volumes..."
        cd "$PROJECT_ROOT"
        docker-compose down -v
        log_info "Cleanup completed ✓"
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
    mkdir -p "$PROJECT_ROOT/data"
    log_info "Directories created ✓"
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
    check_env_file
    create_directories
    cleanup
    build_images
    deploy_services
    wait_for_services
    show_status
    
    echo ""
    log_info "Deployment completed successfully! 🎉"
}

# Run main function
main

