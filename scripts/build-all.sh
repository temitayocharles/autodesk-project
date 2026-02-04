#!/bin/bash
# Build all Docker images

set -e

echo "🔨 Building all Docker images..."
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Build Data Ingestion Service
echo -e "${BLUE}Building Data Ingestion Service...${NC}"
cd "$PROJECT_ROOT/services/data-ingestion-service"
docker build -t data-ingestion-service:latest .
echo -e "${GREEN}✅ Data Ingestion Service built${NC}"
echo ""

# Build Data Processing Service
echo -e "${BLUE}Building Data Processing Service...${NC}"
cd "$PROJECT_ROOT/services/data-processing-service"
docker build -t data-processing-service:latest .
echo -e "${GREEN}✅ Data Processing Service built${NC}"
echo ""

# Build Data API Service
echo -e "${BLUE}Building Data API Service...${NC}"
cd "$PROJECT_ROOT/services/data-api-service"
docker build -t data-api-service:latest .
echo -e "${GREEN}✅ Data API Service built${NC}"
echo ""

echo -e "${GREEN}🎉 All images built successfully!${NC}"
echo ""
echo "View images:"
echo "  docker images | grep 'data-'"
echo ""
echo "Next steps:"
echo "  1. Start services: cd infrastructure/docker-compose && docker-compose up -d"
echo "  2. Check logs: docker-compose logs -f"
echo "  3. Test services: ./scripts/test-services.sh"
