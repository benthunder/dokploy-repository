#!/bin/bash

# OpenClaw Agent Monitor
# Theo dõi hoạt động của agents và LLM requests

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
echo -e "${BLUE}  OpenClaw Agent Monitor${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check if container is running
if ! docker compose ps | grep -q "openclaw.*Up"; then
    echo -e "${RED}Error: OpenClaw container is not running${NC}"
    exit 1
fi

echo -e "${CYAN}Monitoring OpenClaw agents and LLM requests...${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
echo ""
echo -e "${BLUE}Legend:${NC}"
echo -e "  ${GREEN}[AGENT]${NC}  - Agent activity"
echo -e "  ${CYAN}[LLM]${NC}    - LLM API requests"
echo -e "  ${MAGENTA}[DISCORD]${NC} - Discord bot activity"
echo -e "  ${YELLOW}[SYSTEM]${NC} - System events"
echo ""
echo -e "${BLUE}================================${NC}"
echo ""

# Monitor logs with filtering
docker compose logs -f openclaw 2>&1 | while read -r line; do
    timestamp=$(date '+%H:%M:%S')

    # Filter and colorize different types of logs
    if echo "$line" | grep -qi "agent"; then
        echo -e "${GREEN}[$timestamp] [AGENT]${NC} $line"
    elif echo "$line" | grep -qi "llm\|anthropic\|claude\|model"; then
        echo -e "${CYAN}[$timestamp] [LLM]${NC} $line"
    elif echo "$line" | grep -qi "discord\|bot"; then
        echo -e "${MAGENTA}[$timestamp] [DISCORD]${NC} $line"
    elif echo "$line" | grep -qi "error\|fail"; then
        echo -e "${RED}[$timestamp] [ERROR]${NC} $line"
    elif echo "$line" | grep -qi "warn"; then
        echo -e "${YELLOW}[$timestamp] [WARN]${NC} $line"
    elif echo "$line" | grep -qi "start\|ready\|listen"; then
        echo -e "${YELLOW}[$timestamp] [SYSTEM]${NC} $line"
    else
        # Show all other logs in default color
        echo -e "[$timestamp] $line"
    fi
done
