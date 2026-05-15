#!/bin/bash

# OpenClaw LLM Test
# Test LLM provider connection và model availability

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  OpenClaw LLM Test${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Get API credentials from container
API_KEY=$(docker compose exec -T openclaw printenv ANTHROPIC_API_KEY 2>/dev/null || echo "")
BASE_URL=$(docker compose exec -T openclaw printenv ANTHROPIC_BASE_URL 2>/dev/null || echo "")

if [ -z "$API_KEY" ] || [ -z "$BASE_URL" ]; then
    echo -e "${RED}Error: LLM provider not configured${NC}"
    exit 1
fi

echo -e "${CYAN}Testing ChiaSeGPU LLM Provider...${NC}"
echo -e "Endpoint: ${BLUE}$BASE_URL${NC}"
echo -e "API Key: ${BLUE}${API_KEY:0:10}...${NC}"
echo ""

# Test 1: List available models
echo -e "${CYAN}[1/3] Fetching available models...${NC}"
MODELS_RESPONSE=$(curl -s \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    "$BASE_URL/v1/models" 2>/dev/null)

if echo "$MODELS_RESPONSE" | grep -q "data"; then
    echo -e "${GREEN}✓ Successfully fetched models${NC}"
    echo ""
    echo -e "${BLUE}Available models:${NC}"
    echo "$MODELS_RESPONSE" | jq -r '.data[].id' 2>/dev/null | while read -r model; do
        echo -e "  • ${GREEN}$model${NC}"
    done
else
    echo -e "${RED}✗ Failed to fetch models${NC}"
    echo "$MODELS_RESPONSE"
fi
echo ""

# Test 2: Check configured models
echo -e "${CYAN}[2/3] Checking configured models...${NC}"
MODEL_SMALL=$(docker compose exec -T openclaw printenv MODEL_SMALL 2>/dev/null || echo "")
MODEL_MEDIUM=$(docker compose exec -T openclaw printenv MODEL_MEDIUM 2>/dev/null || echo "")
MODEL_HIGH=$(docker compose exec -T openclaw printenv MODEL_HIGH 2>/dev/null || echo "")

echo -e "  Small tier:  ${BLUE}$MODEL_SMALL${NC}"
echo -e "  Medium tier: ${BLUE}$MODEL_MEDIUM${NC}"
echo -e "  High tier:   ${BLUE}$MODEL_HIGH${NC}"

# Verify if configured models exist in available models
if echo "$MODELS_RESPONSE" | grep -q "$MODEL_SMALL"; then
    echo -e "${GREEN}✓ Small tier model available${NC}"
else
    echo -e "${YELLOW}⚠ Small tier model not found in available models${NC}"
fi
echo ""

# Test 3: Send test completion request
echo -e "${CYAN}[3/3] Testing completion request...${NC}"
TEST_RESPONSE=$(curl -s \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"$MODEL_SMALL\",
        \"messages\": [{\"role\": \"user\", \"content\": \"Say 'Hello from OpenClaw!' in one sentence.\"}],
        \"max_tokens\": 50
    }" \
    "$BASE_URL/v1/messages" 2>/dev/null)

if echo "$TEST_RESPONSE" | grep -q "content"; then
    echo -e "${GREEN}✓ Completion request successful${NC}"
    echo ""
    echo -e "${BLUE}Response:${NC}"
    echo "$TEST_RESPONSE" | jq -r '.content[0].text' 2>/dev/null || echo "$TEST_RESPONSE"
else
    echo -e "${RED}✗ Completion request failed${NC}"
    echo "$TEST_RESPONSE"
fi
echo ""

# Summary
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

if echo "$MODELS_RESPONSE" | grep -q "data" && echo "$TEST_RESPONSE" | grep -q "content"; then
    echo -e "${GREEN}✓ All tests passed${NC}"
    echo -e "${GREEN}✓ LLM provider is working correctly${NC}"
    echo ""
    echo -e "OpenClaw agents can now use ChiaSeGPU models!"
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo -e "${YELLOW}Check the errors above and verify your configuration${NC}"
fi
echo ""
