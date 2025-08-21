#!/bin/bash

# =============================================================================
# Smartender Backend V2 - Production Deployment
# =============================================================================

set -e

# Farben für Output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Smartender Backend V2 - Production Deployment${NC}"
echo "=============================================="

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${RED}❌ ERROR: .env file not found!${NC}"
    echo "Please create a .env file with your production settings."
    exit 1
fi

# Check if ENVIRONMENT=prod in .env
if ! grep -q "ENVIRONMENT=prod" .env; then
    echo -e "${YELLOW}⚠️  WARNING: ENVIRONMENT is not set to 'prod' in .env${NC}"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo -e "${GREEN}1. Building Docker images...${NC}"
docker-compose -f docker-compose.prod.yaml build --no-cache

echo -e "${GREEN}2. Starting production services...${NC}"
docker-compose -f docker-compose.prod.yaml up -d

echo -e "${GREEN}3. Waiting for services to start...${NC}"
sleep 10

# Health check
echo -e "${GREEN}4. Checking service health...${NC}"
if curl -f http://localhost:17051/status > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend is healthy!${NC}"
else
    echo -e "${RED}❌ Backend health check failed!${NC}"
    echo "Check logs: docker-compose -f docker-compose.prod.yaml logs"
    exit 1
fi

echo -e "${GREEN}🎉 Deployment successful!${NC}"
echo ""
echo "Services running:"
echo "- Backend:   http://localhost:17051"
echo "- WebSocket: ws://localhost:17051/api/ws"
echo "- Database:  localhost:5432"
echo ""
echo "Useful commands:"
echo "- View logs:    docker-compose -f docker-compose.prod.yaml logs -f"
echo "- Stop:         docker-compose -f docker-compose.prod.yaml down"
echo "- Restart:      docker-compose -f docker-compose.prod.yaml restart"
echo "- Status:       docker-compose -f docker-compose.prod.yaml ps"