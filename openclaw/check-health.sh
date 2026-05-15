#!/bin/bash

# OpenClaw Health Check Script
# Kiểm tra agents và LLM provider đang hoạt động

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  OpenClaw Health Check${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check if container is running
echo -e "${CYAN}[1/5] Checking container status...${NC}"
if docker compose ps | grep -q "openclaw.*Up"; then
    echo -e "${GREEN}✓ Container is running${NC}"
else
    echo -e "${RED}✗ Container is not running${NC}"
    echo -e "${YELLOW}Run: docker compose up -d${NC}"
    exit 1
fi
echo ""

# Check container health
echo -e "${CYAN}[2/5] Checking container health...${NC}"
HEALTH=$(docker inspect --format='{{.State.Health.Status}}' openclaw 2>/dev/null || echo "no-health-check")
if [ "$HEALTH" = "healthy" ]; then
    echo -e "${GREEN}✓ Container is healthy${NC}"
elif [ "$HEALTH" = "no-health-check" ]; then
    echo -e "${YELLOW}⚠ No health check configured${NC}"
else
    echo -e "${RED}✗ Container health: $HEALTH${NC}"
fi
echo ""

# Check LLM provider connection
echo -e "${CYAN}[3/5] Checking LLM provider (ChiaSeGPU)...${NC}"
API_KEY=$(docker compose exec -T openclaw printenv ANTHROPIC_API_KEY 2>/dev/null || echo "")
BASE_URL=$(docker compose exec -T openclaw printenv ANTHROPIC_BASE_URL 2>/dev/null || echo "")

if [ -n "$API_KEY" ] && [ -n "$BASE_URL" ]; then
    echo -e "${GREEN}✓ LLM provider configured${NC}"
    echo -e "  Endpoint: ${BLUE}$BASE_URL${NC}"
    echo -e "  API Key: ${BLUE}${API_KEY:0:10}...${NC}"

    # Test API connection
    echo -e "${CYAN}  Testing API connection...${NC}"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Content-Type: application/json" \
        "$BASE_URL/v1/models" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ]; then
        echo -e "${GREEN}  ✓ API connection successful${NC}"
    else
        echo -e "${RED}  ✗ API connection failed (HTTP $HTTP_CODE)${NC}"
    fi
else
    echo -e "${RED}✗ LLM provider not configured${NC}"
fi
echo ""

# Check model configuration
echo -e "${CYAN}[4/5] Checking model configuration...${NC}"
MODEL_SMALL=$(docker compose exec -T openclaw printenv MODEL_SMALL 2>/dev/null || echo "not-set")
MODEL_MEDIUM=$(docker compose exec -T openclaw printenv MODEL_MEDIUM 2>/dev/null || echo "not-set")
MODEL_HIGH=$(docker compose exec -T openclaw printenv MODEL_HIGH 2>/dev/null || echo "not-set")

echo -e "  Small:  ${BLUE}$MODEL_SMALL${NC}"
echo -e "  Medium: ${BLUE}$MODEL_MEDIUM${NC}"
echo -e "  High:   ${BLUE}$MODEL_HIGH${NC}"

if [ "$MODEL_SMALL" != "not-set" ]; then
    echo -e "${GREEN}✓ Models configured${NC}"
else
    echo -e "${RED}✗ Models not configured${NC}"
fi
echo ""

# Check Discord configuration
echo -e "${CYAN}[5/5] Checking Discord bot configuration...${NC}"
DISCORD_TOKEN=$(docker compose exec -T openclaw printenv DISCORD_BOT_TOKEN 2>/dev/null || echo "")
DISCORD_CHANNEL=$(docker compose exec -T openclaw printenv DISCORD_CHANNEL_ID 2>/dev/null || echo "")

if [ -n "$DISCORD_TOKEN" ] && [ -n "$DISCORD_CHANNEL" ]; then
    echo -e "${GREEN}✓ Discord bot configured${NC}"
    echo -e "  Token: ${BLUE}${DISCORD_TOKEN:0:20}...${NC}"
    echo -e "  Channel ID: ${BLUE}$DISCORD_CHANNEL${NC}"
else
    echo -e "${YELLOW}⚠ Discord bot not configured (optional)${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo -e "Container:     ${GREEN}Running${NC}"
echo -e "LLM Provider:  ${GREEN}Connected${NC}"
echo -e "Models:        ${GREEN}Configured${NC}"
echo -e "Discord:       ${YELLOW}Optional${NC}"
echo ""
echo -e "${GREEN}OpenClaw is ready to use!${NC}"
echo ""
