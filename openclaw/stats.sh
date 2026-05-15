#!/bin/bash

# OpenClaw Stats
# Hiển thị thống kê về agents và LLM usage

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  OpenClaw Statistics${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check if container is running
if ! docker compose ps | grep -q "openclaw.*Up"; then
    echo -e "${RED}Error: OpenClaw container is not running${NC}"
    exit 1
fi

# Container info
echo -e "${CYAN}Container Information:${NC}"
CONTAINER_ID=$(docker compose ps -q openclaw)
UPTIME=$(docker inspect --format='{{.State.StartedAt}}' $CONTAINER_ID | xargs -I {} date -d {} '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "Unknown")
CPU=$(docker stats --no-stream --format "{{.CPUPerc}}" $CONTAINER_ID 2>/dev/null || echo "N/A")
MEM=$(docker stats --no-stream --format "{{.MemUsage}}" $CONTAINER_ID 2>/dev/null || echo "N/A")

echo -e "  Status:    ${GREEN}Running${NC}"
echo -e "  Started:   ${BLUE}$UPTIME${NC}"
echo -e "  CPU:       ${BLUE}$CPU${NC}"
echo -e "  Memory:    ${BLUE}$MEM${NC}"
echo ""

# LLM Configuration
echo -e "${CYAN}LLM Configuration:${NC}"
API_KEY=$(docker compose exec -T openclaw printenv ANTHROPIC_API_KEY 2>/dev/null || echo "not-set")
BASE_URL=$(docker compose exec -T openclaw printenv ANTHROPIC_BASE_URL 2>/dev/null || echo "not-set")
MODEL_SMALL=$(docker compose exec -T openclaw printenv MODEL_SMALL 2>/dev/null || echo "not-set")
MODEL_MEDIUM=$(docker compose exec -T openclaw printenv MODEL_MEDIUM 2>/dev/null || echo "not-set")
MODEL_HIGH=$(docker compose exec -T openclaw printenv MODEL_HIGH 2>/dev/null || echo "not-set")

echo -e "  Provider:  ${BLUE}ChiaSeGPU${NC}"
echo -e "  Endpoint:  ${BLUE}$BASE_URL${NC}"
echo -e "  API Key:   ${BLUE}${API_KEY:0:10}...${NC}"
echo ""
echo -e "  Models:"
echo -e "    Small:   ${GREEN}$MODEL_SMALL${NC}"
echo -e "    Medium:  ${GREEN}$MODEL_MEDIUM${NC}"
echo -e "    High:    ${GREEN}$MODEL_HIGH${NC}"
echo ""

# Discord Configuration
echo -e "${CYAN}Discord Configuration:${NC}"
DISCORD_TOKEN=$(docker compose exec -T openclaw printenv DISCORD_BOT_TOKEN 2>/dev/null || echo "")
DISCORD_CHANNEL=$(docker compose exec -T openclaw printenv DISCORD_CHANNEL_ID 2>/dev/null || echo "")

if [ -n "$DISCORD_TOKEN" ] && [ -n "$DISCORD_CHANNEL" ]; then
    echo -e "  Status:     ${GREEN}Configured${NC}"
    echo -e "  Token:      ${BLUE}${DISCORD_TOKEN:0:20}...${NC}"
    echo -e "  Channel ID: ${BLUE}$DISCORD_CHANNEL${NC}"
else
    echo -e "  Status:     ${YELLOW}Not configured${NC}"
fi
echo ""

# Log Statistics
echo -e "${CYAN}Recent Activity (last 100 lines):${NC}"
LOGS=$(docker compose logs --tail=100 openclaw 2>&1)

AGENT_COUNT=$(echo "$LOGS" | grep -ci "agent" 2>/dev/null || echo "0")
LLM_COUNT=$(echo "$LOGS" | grep -ci "llm\|anthropic\|claude" 2>/dev/null || echo "0")
DISCORD_COUNT=$(echo "$LOGS" | grep -ci "discord\|bot" 2>/dev/null || echo "0")
ERROR_COUNT=$(echo "$LOGS" | grep -ci "error\|fail" 2>/dev/null || echo "0")
WARN_COUNT=$(echo "$LOGS" | grep -ci "warn" 2>/dev/null || echo "0")

echo -e "  Agent events:    ${GREEN}$AGENT_COUNT${NC}"
echo -e "  LLM requests:    ${CYAN}$LLM_COUNT${NC}"
echo -e "  Discord events:  ${MAGENTA}$DISCORD_COUNT${NC}"
echo -e "  Errors:          ${RED}$ERROR_COUNT${NC}"
echo -e "  Warnings:        ${YELLOW}$WARN_COUNT${NC}"
echo ""

# Recent Errors (if any)
if [ "$ERROR_COUNT" -gt 0 ]; then
    echo -e "${RED}Recent Errors:${NC}"
    echo "$LOGS" | grep -i "error\|fail" | tail -5 | while read -r line; do
        echo -e "  ${RED}•${NC} $line"
    done
    echo ""
fi

# Volumes
echo -e "${CYAN}Storage Volumes:${NC}"
DATA_SIZE=$(docker volume inspect openclaw_openclaw_data --format '{{.Mountpoint}}' 2>/dev/null | xargs -I {} du -sh {} 2>/dev/null | cut -f1 || echo "N/A")
LOGS_SIZE=$(docker volume inspect openclaw_openclaw_logs --format '{{.Mountpoint}}' 2>/dev/null | xargs -I {} du -sh {} 2>/dev/null | cut -f1 || echo "N/A")

echo -e "  Data:  ${BLUE}$DATA_SIZE${NC}"
echo -e "  Logs:  ${BLUE}$LOGS_SIZE${NC}"
echo ""

# Quick Actions
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Quick Actions${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo -e "  ${GREEN}./check-health.sh${NC}      - Run health check"
echo -e "  ${GREEN}./monitor-agents.sh${NC}    - Monitor agents in real-time"
echo -e "  ${GREEN}./test-llm.sh${NC}          - Test LLM connection"
echo -e "  ${GREEN}docker compose logs -f${NC} - View all logs"
echo -e "  ${GREEN}docker compose restart${NC} - Restart service"
echo ""
