#!/bin/bash

# ============================================
# Homelab Management Script
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if .env exists
if [ ! -f .env ]; then
    print_warning ".env file not found. Creating from .env.example..."
    cp .env.example .env
    print_success ".env file created. Please review and update it."
fi

# Commands
case "${1:-help}" in
    start)
        print_header "Starting Homelab Stack"
        docker compose up -d
        print_success "Stack started successfully"
        echo ""
        echo "Services:"
        echo "  - Varnish:  http://localhost:80"
        echo "  - Nginx:    http://localhost:8080 (HTTPS: 8443)"
        echo "  - PHP 7.2:  homelab-php72:9000"
        echo "  - PHP 7.4:  homelab-php74:9000"
        echo "  - PHP 8.0:  homelab-php80:9000"
        echo "  - PHP 8.1:  homelab-php81:9000"
        echo "  - PHP 8.2:  homelab-php82:9000"
        echo "  - PHP 8.3:  homelab-php83:9000"
        echo "  - PHP 8.4:  homelab-php84:9000"
        ;;

    stop)
        print_header "Stopping Homelab Stack"
        docker compose down
        print_success "Stack stopped successfully"
        ;;

    restart)
        print_header "Restarting Homelab Stack"
        docker compose restart
        print_success "Stack restarted successfully"
        ;;

    rebuild)
        print_header "Rebuilding Homelab Stack"
        docker compose down
        docker compose build --no-cache
        docker compose up -d
        print_success "Stack rebuilt successfully"
        ;;

    logs)
        SERVICE="${2:-}"
        if [ -z "$SERVICE" ]; then
            docker compose logs -f
        else
            docker compose logs -f "$SERVICE"
        fi
        ;;

    status)
        print_header "Homelab Stack Status"
        docker compose ps
        ;;

    exec)
        SERVICE="${2:-php84}"
        shift 2 || true
        docker compose exec "$SERVICE" "${@:-bash}"
        ;;

    php)
        VERSION="${2:-8.4}"
        shift 2 || true
        SERVICE="php${VERSION/./}"
        docker compose exec "$SERVICE" php "${@}"
        ;;

    composer)
        VERSION="${2:-8.4}"
        shift 2 || true
        SERVICE="php${VERSION/./}"
        docker compose exec "$SERVICE" composer "${@}"
        ;;

    wp)
        VERSION="${2:-8.4}"
        shift 2 || true
        SERVICE="php${VERSION/./}"
        docker compose exec "$SERVICE" wp "${@}"
        ;;

    artisan)
        VERSION="${2:-8.4}"
        shift 2 || true
        SERVICE="php${VERSION/./}"
        docker compose exec "$SERVICE" php artisan "${@}"
        ;;

    purge-cache)
        print_header "Purging Varnish Cache"
        docker compose exec varnish varnishadm "ban req.url ~ ."
        print_success "Cache purged successfully"
        ;;

    varnish-stats)
        docker compose exec varnish varnishstat
        ;;

    nginx-test)
        print_header "Testing Nginx Configuration"
        docker compose exec nginx nginx -t
        ;;

    nginx-reload)
        print_header "Reloading Nginx Configuration"
        docker compose exec nginx nginx -s reload
        print_success "Nginx reloaded successfully"
        ;;

    create-vhost)
        DOMAIN="${2:-}"
        PHP_VERSION="${3:-8.4}"

        if [ -z "$DOMAIN" ]; then
            print_error "Usage: $0 create-vhost <domain> [php-version]"
            exit 1
        fi

        VHOST_FILE="configs/nginx/conf.d/${DOMAIN}.conf"
        PHP_SERVICE="php${PHP_VERSION/./}"

        cat > "$VHOST_FILE" <<EOF
server {
    listen 8080;
    server_name ${DOMAIN};

    root /var/www/${DOMAIN}/public;
    index index.php index.html;

    access_log /var/log/nginx/${DOMAIN}-access.log;
    error_log /var/log/nginx/${DOMAIN}-error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass ${PHP_SERVICE}:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }

    location ~ /\.(ht|git|env) {
        deny all;
    }

    location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

        print_success "Virtual host created: $VHOST_FILE"
        print_warning "Don't forget to:"
        echo "  1. Add '$DOMAIN' to /etc/hosts"
        echo "  2. Create project directory: projects/${DOMAIN}/public"
        echo "  3. Reload Nginx: $0 nginx-reload"
        ;;

    help|*)
        print_header "Homelab Management Script"
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Stack Management:"
        echo "  start              Start all services"
        echo "  stop               Stop all services"
        echo "  restart            Restart all services"
        echo "  rebuild            Rebuild and restart all services"
        echo "  status             Show services status"
        echo "  logs [service]     Show logs (all or specific service)"
        echo ""
        echo "Container Access:"
        echo "  exec <service>     Execute bash in service (default: php84)"
        echo "  php <ver> <cmd>    Run PHP command (e.g., $0 php 8.2 -v)"
        echo "  composer <ver>     Run Composer (e.g., $0 composer 8.4 install)"
        echo "  wp <ver> <cmd>     Run WP-CLI (e.g., $0 wp 7.4 core version)"
        echo "  artisan <ver>      Run Laravel Artisan (e.g., $0 artisan 8.3 migrate)"
        echo ""
        echo "Cache & Config:"
        echo "  purge-cache        Purge Varnish cache"
        echo "  varnish-stats      Show Varnish statistics"
        echo "  nginx-test         Test Nginx configuration"
        echo "  nginx-reload       Reload Nginx configuration"
        echo ""
        echo "Virtual Hosts:"
        echo "  create-vhost <domain> [php-ver]  Create new virtual host"
        echo "                                     (e.g., $0 create-vhost mysite.local 8.2)"
        echo ""
        echo "Examples:"
        echo "  $0 start"
        echo "  $0 logs nginx"
        echo "  $0 exec php74"
        echo "  $0 php 8.2 -v"
        echo "  $0 composer 8.4 require laravel/framework"
        echo "  $0 wp 7.4 plugin list"
        echo "  $0 create-vhost myapp.local 8.3"
        ;;
esac
