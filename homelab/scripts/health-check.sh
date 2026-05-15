#!/bin/bash

# ============================================
# Health Check Script
# ============================================
# Checks if all services are healthy
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Homelab Stack Health Check${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if containers are running
SERVICES=(
    "homelab-php72"
    "homelab-php74"
    "homelab-php80"
    "homelab-php81"
    "homelab-php82"
    "homelab-php83"
    "homelab-php84"
)

ALL_HEALTHY=true

for SERVICE in "${SERVICES[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${SERVICE}$"; then
        HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$SERVICE" 2>/dev/null || echo "no-healthcheck")

        if [ "$HEALTH" = "healthy" ] || [ "$HEALTH" = "no-healthcheck" ]; then
            STATUS=$(docker inspect --format='{{.State.Status}}' "$SERVICE")
            if [ "$STATUS" = "running" ]; then
                echo -e "${GREEN}✓${NC} $SERVICE: ${GREEN}running${NC}"
            else
                echo -e "${RED}✗${NC} $SERVICE: ${RED}$STATUS${NC}"
                ALL_HEALTHY=false
            fi
        else
            echo -e "${YELLOW}⚠${NC} $SERVICE: ${YELLOW}$HEALTH${NC}"
            ALL_HEALTHY=false
        fi
    else
        echo -e "${RED}✗${NC} $SERVICE: ${RED}not running${NC}"
        ALL_HEALTHY=false
    fi
done

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}Service Endpoints${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check HTTP endpoints
check_endpoint() {
    local URL=$1
    local NAME=$2

    if curl -s -o /dev/null -w "%{http_code}" "$URL" | grep -q "200\|301\|302"; then
        echo -e "${GREEN}✓${NC} $NAME: ${GREEN}accessible${NC} ($URL)"
    else
        echo -e "${RED}✗${NC} $NAME: ${RED}not accessible${NC} ($URL)"
        ALL_HEALTHY=false
    fi
}

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}PHP Versions${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check PHP versions
for VERSION in 72 74 80 81 82 83 84; do
    PHP_VERSION=$(docker compose exec -T "php${VERSION}" php -v 2>/dev/null | head -n 1 || echo "Error")
    if [[ "$PHP_VERSION" != "Error" ]]; then
        echo -e "${GREEN}✓${NC} PHP ${VERSION:0:1}.${VERSION:1}: $PHP_VERSION"
    else
        echo -e "${RED}✗${NC} PHP ${VERSION:0:1}.${VERSION:1}: ${RED}not accessible${NC}"
        ALL_HEALTHY=false
    fi
done

echo ""
echo -e "${BLUE}============================================${NC}"

if [ "$ALL_HEALTHY" = true ]; then
    echo -e "${GREEN}All services are healthy!${NC}"
    exit 0
else
    echo -e "${RED}Some services are not healthy!${NC}"
    exit 1
fi
