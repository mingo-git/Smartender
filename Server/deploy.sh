#!/bin/bash

# =============================================================================
# Smartender Backend V2 - Production Deployment
# =============================================================================

set -e

# Farben für Output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Smartender Backend V2 - Deployment${NC}"
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

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ ERROR: Docker is not running!${NC}"
    echo "Please start Docker and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ ERROR: docker-compose is not installed!${NC}"
    echo "Please install docker-compose and try again."
    exit 1
fi

echo -e "${GREEN}1. Stopping existing services...${NC}"
docker-compose down || echo "No existing services to stop"

echo -e "${GREEN}2. Pulling latest base images...${NC}"
docker-compose pull postgres

echo -e "${GREEN}3. Building Docker images...${NC}"
docker-compose build --no-cache

echo -e "${GREEN}4. Starting production services...${NC}"
docker-compose up -d

echo -e "${GREEN}5. Waiting for services to start...${NC}"
sleep 15

# Extended health check
echo -e "${GREEN}6. Checking service health...${NC}"
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f http://localhost:17051/status > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend is healthy!${NC}"
        break
    else
        echo -n "."
        sleep 2
        RETRY_COUNT=$((RETRY_COUNT + 1))
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo -e "${RED}❌ Backend health check failed after 60 seconds!${NC}"
    echo "Check logs: docker-compose logs smartender-app"
    exit 1
fi

echo -e "${GREEN}7. Verifying database connection...${NC}"
if docker exec smartender-postgres-prod pg_isready -U smartender_user -d smartender_db > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Database is healthy!${NC}"
else
    echo -e "${YELLOW}⚠️  Database health check failed, but continuing...${NC}"
fi

echo -e "${GREEN}8. Testing WebSocket endpoint...${NC}"
WS_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:17051/api/ws)
if [ "$WS_RESPONSE" = "426" ]; then
    echo -e "${GREEN}✅ WebSocket endpoint is ready (HTTP 426 = Upgrade Required)!${NC}"
else
    echo -e "${YELLOW}⚠️  WebSocket endpoint returned HTTP $WS_RESPONSE${NC}"
fi

echo -e "${GREEN}🎉 Deployment successful!${NC}"
echo ""
echo -e "${BLUE}Service Information:${NC}"
echo "- Backend:   http://localhost:17051"
echo "- API:       http://localhost:17051/api/"
echo "- WebSocket: ws://localhost:17051/api/ws"
echo "- Database:  localhost:5432 (internal)"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "- View logs:    docker-compose logs -f"
echo "- Stop:         docker-compose down"
echo "- Restart:      docker-compose restart"
echo "- Status:       docker-compose ps"
echo "- Monitor:      ./monitor.sh"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Set up your reverse proxy to forward requests to port 17051"
echo "2. Configure SSL/TLS certificates"
echo "3. Set up monitoring and alerting"
echo "4. Configure automated backups with ./backup.sh"