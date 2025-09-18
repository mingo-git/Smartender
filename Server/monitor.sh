#!/bin/bash

# =============================================================================
# Smartender Production Monitoring
# =============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}📊 Smartender Production Status${NC}"
echo "================================="

# Container Status
echo -e "\n${YELLOW}🐳 Container Status:${NC}"
docker-compose ps

# Health Checks
echo -e "\n${YELLOW}🏥 Health Checks:${NC}"

# Backend Health
if curl -s http://localhost:17051/status > /dev/null; then
    echo -e "✅ Backend: ${GREEN}OK${NC} (http://localhost:17051)"
else
    echo -e "❌ Backend: ${RED}FAILED${NC} (http://localhost:17051)"
fi

# Database Health
if docker exec smartender-postgres-prod pg_isready -U smartender_user > /dev/null 2>&1; then
    echo -e "✅ Database: ${GREEN}OK${NC}"
else
    echo -e "❌ Database: ${RED}FAILED${NC}"
fi

# WebSocket Health (basic check)
WS_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:17051/api/ws)
if [ "$WS_RESPONSE" = "426" ]; then
    echo -e "✅ WebSocket: ${GREEN}OK${NC} (Upgrade Required - normal)"
else
    echo -e "❌ WebSocket: ${RED}Status $WS_RESPONSE${NC}"
fi

# Disk Usage
echo -e "\n${YELLOW}💾 Disk Usage:${NC}"
docker system df

# Recent Logs (last 5 lines)
echo -e "\n${YELLOW}📋 Recent Logs:${NC}"
docker-compose logs --tail=5

echo -e "\n${GREEN}Monitoring complete!${NC}"