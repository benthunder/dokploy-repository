#!/bin/bash

# Script to clean up Dokploy and Docker resources
# Run with: bash cleanup-server.sh

set -e

echo "=========================================="
echo "Server Cleanup Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Confirm before proceeding
echo -e "${RED}⚠️  WARNING: This will:${NC}"
echo "  1. Uninstall Dokploy"
echo "  2. Stop and remove ALL Docker containers"
echo "  3. Remove ALL unused Docker images"
echo "  4. Remove unused Docker volumes"
echo "  5. Remove unused Docker networks"
echo ""
read -p "Are you sure you want to continue? (type 'YES' to confirm): " confirm

if [ "$confirm" != "YES" ]; then
    print_error "Cleanup cancelled."
    exit 1
fi

echo ""
print_info "Starting cleanup process..."
echo ""

# Step 1: Uninstall Dokploy
print_info "Step 1: Uninstalling Dokploy..."

# Check if Docker Swarm is active
if docker info 2>/dev/null | grep -q "Swarm: active"; then
    print_info "Docker Swarm detected. Removing Dokploy services..."

    # Remove Dokploy stack/services
    print_info "Removing Dokploy stack..."
    docker stack rm dokploy 2>/dev/null || true

    # Wait for stack removal
    print_info "Waiting for services to stop..."
    sleep 5

    # Remove individual services if stack removal didn't work
    for service in $(docker service ls --filter name=dokploy -q 2>/dev/null); do
        print_info "Removing service: $service"
        docker service rm $service || true
    done

    # Leave swarm if no other services
    service_count=$(docker service ls -q 2>/dev/null | wc -l)
    if [ "$service_count" -eq 0 ]; then
        print_warning "No other services found. Leaving Docker Swarm..."
        read -p "Do you want to leave Docker Swarm? (y/N): " leave_swarm
        if [ "$leave_swarm" = "y" ] || [ "$leave_swarm" = "Y" ]; then
            docker swarm leave --force || true
            print_info "Left Docker Swarm."
        fi
    fi
fi

# Remove Dokploy containers (if any standalone containers exist)
print_info "Checking for standalone Dokploy containers..."
dokploy_containers=$(docker ps -aq --filter name=dokploy 2>/dev/null)
if [ -n "$dokploy_containers" ]; then
    print_info "Removing Dokploy containers..."
    echo "$dokploy_containers" | xargs -r docker rm -f || true
fi

# Remove Dokploy volumes
print_info "Removing Dokploy volumes..."
docker volume ls -q --filter name=dokploy 2>/dev/null | xargs -r docker volume rm || true

# Remove Dokploy networks
print_info "Removing Dokploy networks..."
docker network ls -q --filter name=dokploy 2>/dev/null | xargs -r docker network rm || true

# Remove Dokploy binary
if [ -f "/usr/local/bin/dokploy" ]; then
    print_info "Removing Dokploy binary..."
    sudo rm -f /usr/local/bin/dokploy
fi

# Remove Dokploy data directories
for dir in /etc/dokploy /opt/dokploy /var/lib/dokploy; do
    if [ -d "$dir" ]; then
        print_info "Removing Dokploy data directory: $dir"
        sudo rm -rf "$dir"
    fi
done

print_info "Dokploy uninstalled successfully."

echo ""

# Step 2: Stop and remove all containers
print_info "Step 2: Stopping and removing ALL Docker containers..."
container_count=$(docker ps -aq | wc -l)
if [ "$container_count" -gt 0 ]; then
    print_info "Found $container_count containers. Removing..."
    docker stop $(docker ps -aq) 2>/dev/null || true
    docker rm $(docker ps -aq) 2>/dev/null || true
    print_info "All containers removed."
else
    print_info "No containers found."
fi

echo ""

# Step 3: Remove all images
print_info "Step 3: Removing ALL Docker images..."
image_count=$(docker images -q | wc -l)
if [ "$image_count" -gt 0 ]; then
    print_info "Found $image_count images. Removing..."
    docker rmi $(docker images -q) -f 2>/dev/null || true
    print_info "All images removed."
else
    print_info "No images found."
fi

echo ""

# Step 4: Remove unused volumes
print_info "Step 4: Removing unused Docker volumes..."
docker volume prune -f
print_info "Unused volumes removed."

echo ""

# Step 5: Remove unused networks
print_info "Step 5: Removing unused Docker networks..."
docker network prune -f
print_info "Unused networks removed."

echo ""

# Step 6: Clean up Docker system
print_info "Step 6: Running Docker system prune..."
docker system prune -a -f --volumes
print_info "Docker system cleaned."

echo ""

# Step 7: Show disk space freed
print_info "Cleanup completed!"
echo ""
print_info "Current Docker disk usage:"
docker system df

echo ""
print_info "=========================================="
print_info "Cleanup Summary:"
print_info "✓ Dokploy uninstalled"
print_info "✓ All containers removed"
print_info "✓ All images removed"
print_info "✓ Unused volumes removed"
print_info "✓ Unused networks removed"
print_info "✓ Docker system cleaned"
print_info "=========================================="
