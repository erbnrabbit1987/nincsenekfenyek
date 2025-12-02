#!/bin/bash

# Nincsenek Fények! - Service Status Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "=== Service Status ==="
docker-compose ps

echo ""
echo "=== Service Health ==="

# Check Backend API
if curl -f http://localhost:8000/health &> /dev/null; then
    echo "✓ Backend API: Healthy"
else
    echo "✗ Backend API: Unhealthy or not responding"
fi

# Check MongoDB
if docker-compose exec -T mongodb mongosh --eval "db.version()" &> /dev/null; then
    echo "✓ MongoDB: Running"
else
    echo "✗ MongoDB: Not responding"
fi

# Check PostgreSQL
if docker-compose exec -T postgres pg_isready -U postgres &> /dev/null; then
    echo "✓ PostgreSQL: Running"
else
    echo "✗ PostgreSQL: Not responding"
fi

# Check Redis
if docker-compose exec -T redis redis-cli ping &> /dev/null; then
    echo "✓ Redis: Running"
else
    echo "✗ Redis: Not responding"
fi

echo ""
echo "=== Service URLs ==="
echo "  Backend API: http://localhost:8000"
echo "  API Docs: http://localhost:8000/docs"
echo "  MongoDB: mongodb://localhost:27017"
echo "  PostgreSQL: postgresql://postgres:postgres@localhost:5432/nincsenekfenyek"
echo "  Redis: redis://localhost:6379"

echo ""
echo "=== Logs (last 10 lines) ==="
docker-compose logs --tail=10

