#!/bin/bash

# OpenClaw Quick Start Script
# Khởi động OpenClaw với ChiaSeGPU LLM Provider

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  OpenClaw Quick Start${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

# Check Docker Compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed${NC}"
    exit 1
fi

# Create .env if not exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env from .env.example...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✓ .env created${NC}"
else
    echo -e "${GREEN}✓ .env already exists${NC}"
fi

# Ask for Discord setup
echo ""
echo -e "${YELLOW}Do you want to configure Discord bot? (optional)${NC}"
read -p "Configure Discord? (y/N): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    read -p "Enter Discord Bot Token: " BOT_TOKEN
    read -p "Enter Discord Channel ID: " CHANNEL_ID

    if [ -n "$BOT_TOKEN" ] && [ -n "$CHANNEL_ID" ]; then
        # Update .env
        sed -i "s/# DISCORD_BOT_TOKEN=.*/DISCORD_BOT_TOKEN=$BOT_TOKEN/" .env
        sed -i "s/# DISCORD_CHANNEL_ID=.*/DISCORD_CHANNEL_ID=$CHANNEL_ID/" .env
        echo -e "${GREEN}✓ Discord configured${NC}"
    fi
fi

# Pull latest image
echo ""
echo -e "${BLUE}Pulling latest OpenClaw image...${NC}"
docker compose pull

# Start services
echo ""
echo -e "${BLUE}Starting OpenClaw...${NC}"
docker compose up -d

# Wait for health check
echo ""
echo -e "${YELLOW}Waiting for OpenClaw to be ready...${NC}"
sleep 5

# Check status
if docker compose ps | grep -q "Up"; then
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}  OpenClaw is running!${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo -e "Access at: ${BLUE}http://localhost:3000${NC}"
    echo ""
    echo -e "Useful commands:"
    echo -e "  ${BLUE}docker compose logs -f${NC}     # View logs"
    echo -e "  ${BLUE}docker compose restart${NC}     # Restart"
    echo -e "  ${BLUE}docker compose down${NC}        # Stop"
    echo ""
else
    echo ""
    echo -e "${RED}Failed to start OpenClaw${NC}"
    echo -e "Check logs: ${BLUE}docker compose logs${NC}"
    exit 1
fi
