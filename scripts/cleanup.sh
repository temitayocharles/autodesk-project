#!/bin/bash
# Cleanup and stop all services

set -e

echo "🧹 Cleaning up AEC Data Infrastructure Platform..."
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT/infrastructure/docker-compose"

# Stop and remove containers
echo "Stopping Docker Compose services..."
docker-compose down -v

# Remove images (optional)
read -p "Remove Docker images? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Removing images..."
    docker rmi -f data-ingestion-service:latest 2>/dev/null || true
    docker rmi -f data-processing-service:latest 2>/dev/null || true
    docker rmi -f data-api-service:latest 2>/dev/null || true
fi

# Clean up Kubernetes resources (if deployed)
if kubectl get namespace aec-data &> /dev/null; then
    read -p "Remove Kubernetes resources? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing Kubernetes resources..."
        kubectl delete namespace aec-data || true
    fi
fi

echo ""
echo "✅ Cleanup complete!"
