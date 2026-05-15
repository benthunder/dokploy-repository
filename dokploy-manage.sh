#!/bin/bash

# Dokploy Management Script
# Usage: ./dokploy-manage.sh [start|stop|restart|logs|status|update]

set -e

DOKPLOY_DIR="/opt/dokploy"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_installation() {
    if [ ! -d "$DOKPLOY_DIR" ]; then
        log_error "Dokploy not installed at $DOKPLOY_DIR"
        exit 1
    fi
    cd "$DOKPLOY_DIR"
}

cmd_start() {
    log_info "Starting Dokploy..."
    docker compose up -d
    log_info "Dokploy started successfully"
    echo ""
    cmd_status
}

cmd_stop() {
    log_info "Stopping Dokploy..."
    docker compose down
    log_info "Dokploy stopped"
}

cmd_restart() {
    log_info "Restarting Dokploy..."
    docker compose restart
    log_info "Dokploy restarted"
}

cmd_logs() {
    SERVICE=${1:-dokploy}
    log_info "Showing logs for $SERVICE (Ctrl+C to exit)..."
    docker compose logs -f "$SERVICE"
}

cmd_status() {
    log_info "Dokploy Status:"
    echo ""
    docker compose ps
    echo ""

    # Check if Dokploy is accessible
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:80 | grep -q "200\|302"; then
        echo -e "${GREEN}✓${NC} Dokploy is accessible at http://localhost"
    else
        echo -e "${RED}✗${NC} Dokploy is not accessible"
    fi
}

cmd_update() {
    log_info "Updating Dokploy..."
    docker compose pull
    docker compose up -d
    log_info "Dokploy updated successfully"
}

cmd_backup() {
    BACKUP_DIR="/opt/dokploy-backups"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/dokploy_backup_$TIMESTAMP.tar.gz"

    log_info "Creating backup..."
    mkdir -p "$BACKUP_DIR"

    # Backup database
    docker exec dokploy-postgres pg_dump -U dokploy dokploy > "$BACKUP_DIR/db_$TIMESTAMP.sql"

    # Backup volumes
    docker run --rm \
        -v dokploy-data:/data \
        -v "$BACKUP_DIR":/backup \
        alpine tar czf "/backup/volumes_$TIMESTAMP.tar.gz" /data

    # Backup configs
    tar czf "$BACKUP_FILE" \
        -C /opt \
        dokploy/docker-compose.yml \
        dokploy/nginx.conf \
        dokploy/.env \
        dokploy/ssl 2>/dev/null || true

    log_info "Backup created: $BACKUP_FILE"
    log_info "Database backup: $BACKUP_DIR/db_$TIMESTAMP.sql"
    log_info "Volumes backup: $BACKUP_DIR/volumes_$TIMESTAMP.tar.gz"
}

cmd_restore() {
    if [ -z "$1" ]; then
        log_error "Usage: $0 restore <backup_timestamp>"
        log_info "Available backups:"
        ls -lh /opt/dokploy-backups/*.sql 2>/dev/null | awk '{print $9}' | xargs -n1 basename
        exit 1
    fi

    TIMESTAMP=$1
    BACKUP_DIR="/opt/dokploy-backups"

    log_warn "This will restore Dokploy to backup: $TIMESTAMP"
    read -p "Continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "Restore cancelled"
        exit 0
    fi

    log_info "Stopping Dokploy..."
    docker compose down

    log_info "Restoring database..."
    docker compose up -d postgres
    sleep 5
    docker exec -i dokploy-postgres psql -U dokploy dokploy < "$BACKUP_DIR/db_$TIMESTAMP.sql"

    log_info "Restoring volumes..."
    docker run --rm \
        -v dokploy-data:/data \
        -v "$BACKUP_DIR":/backup \
        alpine tar xzf "/backup/volumes_$TIMESTAMP.tar.gz" -C /

    log_info "Starting Dokploy..."
    docker compose up -d

    log_info "Restore completed"
}

cmd_ssl() {
    DOMAIN=$1
    EMAIL=$2

    if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
        log_error "Usage: $0 ssl <domain> <email>"
        exit 1
    fi

    log_info "Setting up SSL for $DOMAIN..."

    # Install certbot if not exists
    if ! command -v certbot &> /dev/null; then
        log_info "Installing certbot..."
        apt-get update
        apt-get install -y certbot
    fi

    # Stop nginx temporarily
    docker compose stop nginx

    # Get certificate
    certbot certonly --standalone \
        -d "$DOMAIN" \
        --email "$EMAIL" \
        --agree-tos \
        --non-interactive

    # Copy certificates
    mkdir -p "$DOKPLOY_DIR/ssl"
    cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$DOKPLOY_DIR/ssl/cert.pem"
    cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$DOKPLOY_DIR/ssl/key.pem"

    # Update nginx config
    log_info "Updating nginx configuration..."
    sed -i "s/# server {/server {/g" "$DOKPLOY_DIR/nginx.conf"
    sed -i "s/dokploy.yourdomain.com/$DOMAIN/g" "$DOKPLOY_DIR/nginx.conf"

    # Start nginx
    docker compose up -d nginx

    log_info "SSL configured successfully for $DOMAIN"
    log_info "Dokploy is now accessible at https://$DOMAIN"
}

cmd_clean() {
    log_warn "This will remove all Dokploy data including databases!"
    read -p "Are you sure? Type 'yes' to confirm: " confirm
    if [ "$confirm" != "yes" ]; then
        log_info "Clean cancelled"
        exit 0
    fi

    log_info "Stopping and removing Dokploy..."
    docker compose down -v

    log_info "Removing Dokploy directory..."
    rm -rf "$DOKPLOY_DIR"

    log_info "Dokploy completely removed"
}

cmd_help() {
    cat << EOF
${BLUE}Dokploy Management Script${NC}

Usage: $0 [command] [options]

Commands:
  ${GREEN}start${NC}              Start Dokploy services
  ${GREEN}stop${NC}               Stop Dokploy services
  ${GREEN}restart${NC}            Restart Dokploy services
  ${GREEN}logs${NC} [service]     Show logs (default: dokploy)
                       Services: dokploy, postgres, redis, nginx
  ${GREEN}status${NC}             Show Dokploy status
  ${GREEN}update${NC}             Update Dokploy to latest version
  ${GREEN}backup${NC}             Create backup of Dokploy data
  ${GREEN}restore${NC} <timestamp> Restore from backup
  ${GREEN}ssl${NC} <domain> <email> Setup SSL certificate with Let's Encrypt
  ${GREEN}clean${NC}              Remove Dokploy completely (dangerous!)
  ${GREEN}help${NC}               Show this help message

Examples:
  $0 start
  $0 logs nginx
  $0 ssl dokploy.example.com admin@example.com
  $0 backup
  $0 restore 20260513_120000

EOF
}

# Main
check_installation

case "${1:-help}" in
    start)
        cmd_start
        ;;
    stop)
        cmd_stop
        ;;
    restart)
        cmd_restart
        ;;
    logs)
        cmd_logs "$2"
        ;;
    status)
        cmd_status
        ;;
    update)
        cmd_update
        ;;
    backup)
        cmd_backup
        ;;
    restore)
        cmd_restore "$2"
        ;;
    ssl)
        cmd_ssl "$2" "$3"
        ;;
    clean)
        cmd_clean
        ;;
    help|*)
        cmd_help
        ;;
esac
