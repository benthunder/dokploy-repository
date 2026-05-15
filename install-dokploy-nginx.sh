#!/bin/bash

# Dokploy Installation Script with Nginx (No Traefik)
# Author: Claude Code
# Date: 2026-05-13

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root or with sudo"
        exit 1
    fi
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_warn "Docker not found. Installing..."
        curl -fsSL https://get.docker.com | sh
        usermod -aG docker $SUDO_USER
        log_info "Docker installed successfully"
    else
        log_info "Docker already installed"
    fi
}

check_docker_compose() {
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose not found. Please install Docker Compose v2"
        exit 1
    fi
    log_info "Docker Compose found"
}

create_directories() {
    log_info "Creating directories..."
    mkdir -p /opt/dokploy/{ssl,logs}
    cd /opt/dokploy
}

generate_secret() {
    openssl rand -hex 32
}

create_env_file() {
    log_info "Creating .env file..."
    cat > /opt/dokploy/.env << EOF
SECRET_KEY=$(generate_secret)
POSTGRES_USER=dokploy
POSTGRES_PASSWORD=$(generate_secret)
POSTGRES_DB=dokploy
EOF
    log_info ".env file created"
}

create_docker_compose() {
    log_info "Creating docker-compose.yml..."
    cat > /opt/dokploy/docker-compose.yml << 'EOF'
version: '3.8'

services:
  dokploy:
    image: dokploy/dokploy:latest
    container_name: dokploy
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:3000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - dokploy-data:/app/data
    environment:
      - DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
      - REDIS_URL=redis://redis:6379
      - SECRET_KEY=${SECRET_KEY}
      - TRAEFIK_ENABLED=false
    networks:
      - dokploy-network
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started

  postgres:
    image: postgres:16-alpine
    container_name: dokploy-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - dokploy-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: dokploy-redis
    restart: unless-stopped
    volumes:
      - redis-data:/data
    networks:
      - dokploy-network

  nginx:
    image: nginx:alpine
    container_name: dokploy-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
      - ./logs:/var/log/nginx
    networks:
      - dokploy-network
    depends_on:
      - dokploy

volumes:
  dokploy-data:
  postgres-data:
  redis-data:

networks:
  dokploy-network:
    driver: bridge
EOF
    log_info "docker-compose.yml created"
}

create_nginx_config() {
    log_info "Creating nginx.conf..."
    cat > /opt/dokploy/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss
               application/rss+xml font/truetype font/opentype
               application/vnd.ms-fontobject image/svg+xml;

    upstream dokploy {
        server dokploy:3000;
    }

    server {
        listen 80 default_server;
        server_name _;

        client_max_body_size 100M;

        location / {
            proxy_pass http://dokploy;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Timeouts
            proxy_connect_timeout 60s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
        }
    }

    # SSL Configuration Template (uncomment and configure)
    # server {
    #     listen 443 ssl http2;
    #     server_name dokploy.yourdomain.com;
    #
    #     ssl_certificate /etc/nginx/ssl/cert.pem;
    #     ssl_certificate_key /etc/nginx/ssl/key.pem;
    #     ssl_protocols TLSv1.2 TLSv1.3;
    #     ssl_ciphers HIGH:!aNULL:!MD5;
    #     ssl_prefer_server_ciphers on;
    #
    #     client_max_body_size 100M;
    #
    #     location / {
    #         proxy_pass http://dokploy;
    #         proxy_http_version 1.1;
    #         proxy_set_header Upgrade $http_upgrade;
    #         proxy_set_header Connection 'upgrade';
    #         proxy_set_header Host $host;
    #         proxy_cache_bypass $http_upgrade;
    #         proxy_set_header X-Real-IP $remote_addr;
    #         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    #         proxy_set_header X-Forwarded-Proto $scheme;
    #     }
    # }
}
EOF
    log_info "nginx.conf created"
}

create_network() {
    log_info "Creating Docker network..."
    if ! docker network inspect dokploy-network &> /dev/null; then
        docker network create dokploy-network
        log_info "Network created"
    else
        log_info "Network already exists"
    fi
}

start_services() {
    log_info "Starting services..."
    cd /opt/dokploy
    docker compose up -d
    log_info "Services started"
}

show_status() {
    echo ""
    log_info "Waiting for services to be ready..."
    sleep 10

    echo ""
    log_info "=== Service Status ==="
    docker compose ps

    echo ""
    log_info "=== Dokploy Installation Complete ==="
    echo ""
    echo "📦 Installation Directory: /opt/dokploy"
    echo "🌐 Access Dokploy at: http://$(hostname -I | awk '{print $1}')"
    echo "🔐 Default credentials will be set on first access"
    echo ""
    echo "📝 Useful Commands:"
    echo "  - View logs: docker logs dokploy"
    echo "  - Restart: cd /opt/dokploy && docker compose restart"
    echo "  - Stop: cd /opt/dokploy && docker compose stop"
    echo "  - Update: cd /opt/dokploy && docker compose pull && docker compose up -d"
    echo ""
    echo "🔧 Configuration Files:"
    echo "  - Docker Compose: /opt/dokploy/docker-compose.yml"
    echo "  - Nginx Config: /opt/dokploy/nginx.conf"
    echo "  - Environment: /opt/dokploy/.env"
    echo "  - SSL Certs: /opt/dokploy/ssl/"
    echo ""
    log_warn "Note: Traefik is disabled. You need to manually configure SSL if needed."
    echo ""
}

# Main Installation
main() {
    echo ""
    log_info "=== Dokploy Installation with Nginx (No Traefik) ==="
    echo ""

    check_root
    check_docker
    check_docker_compose
    create_directories
    create_env_file
    create_docker_compose
    create_nginx_config
    create_network
    start_services
    show_status
}

main "$@"
