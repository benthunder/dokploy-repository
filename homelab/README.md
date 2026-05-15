# Homelab Stack: Varnish + Nginx + Multi PHP-FPM

Complete development environment với Varnish cache, Nginx web server, và multiple PHP-FPM versions (7.2 - 8.4).

## 🏗️ Architecture

```
Internet (Port 80)
    ↓
Varnish Cache (172.20.0.10:80)
    ↓
Nginx Web Server (172.20.0.20:8080/8443)
    ↓
PHP-FPM Containers:
    - PHP 7.2 (172.20.0.72:9000)
    - PHP 7.4 (172.20.0.74:9000)
    - PHP 8.0 (172.20.0.80:9000)
    - PHP 8.1 (172.20.0.81:9000)
    - PHP 8.2 (172.20.0.82:9000)
    - PHP 8.3 (172.20.0.83:9000)
    - PHP 8.4 (172.20.0.84:9000) [default]
```

## 📦 Services

### Varnish Cache
- **Port**: 80 (HTTP), 6081 (Admin)
- **Purpose**: HTTP cache layer
- **Config**: `configs/varnish/default.vcl`
- **Cache Size**: 256MB (configurable via `.env`)

### Nginx
- **Ports**: 8080 (HTTP), 8443 (HTTPS)
- **Purpose**: Web server & reverse proxy
- **Config**: `configs/nginx/`
- **SSL**: Self-signed certificate (auto-generated)

### PHP-FPM (All Versions)
- **Versions**: 7.2, 7.4, 8.0, 8.1, 8.2, 8.3, 8.4
- **Port**: 9000 (internal)
- **Pre-installed Tools**:
  - Composer (latest)
  - WP-CLI (latest)
  - Laravel Installer
  - Symfony CLI
  - PHPUnit
  - PHP CS Fixer
  - PHPStan
- **Extensions**:
  - PDO (MySQL, PostgreSQL, SQLite)
  - GD, Intl, Zip, BCMath, Soap
  - Redis, Opcache
  - Xdebug (configurable)

## 🚀 Quick Start

### 1. Setup

```bash
# Copy environment file
cp .env.example .env

# Edit .env if needed
nano .env

# Create projects directory
mkdir -p projects/default/public
echo "<?php phpinfo();" > projects/default/public/index.php
```

### 2. Start Stack

```bash
# Using management script
./scripts/homelab.sh start

# Or using docker compose directly
docker compose up -d
```

### 3. Access

- **Varnish**: http://localhost
- **Nginx**: http://localhost:8080 (HTTPS: https://localhost:8443)
- **PHP Info**: http://localhost/index.php

## 🛠️ Management Script

Script `scripts/homelab.sh` cung cấp các commands tiện lợi:

### Stack Management

```bash
./scripts/homelab.sh start          # Start all services
./scripts/homelab.sh stop           # Stop all services
./scripts/homelab.sh restart        # Restart all services
./scripts/homelab.sh rebuild        # Rebuild from scratch
./scripts/homelab.sh status         # Show status
./scripts/homelab.sh logs [service] # View logs
```

### PHP Commands

```bash
# Run PHP command with specific version
./scripts/homelab.sh php 8.2 -v
./scripts/homelab.sh php 7.4 -m

# Run Composer
./scripts/homelab.sh composer 8.4 install
./scripts/homelab.sh composer 8.2 require laravel/framework

# Run WP-CLI
./scripts/homelab.sh wp 7.4 --info
./scripts/homelab.sh wp 8.1 plugin list

# Run Laravel Artisan
./scripts/homelab.sh artisan 8.3 migrate
./scripts/homelab.sh artisan 8.4 make:controller UserController
```

### Varnish Management

```bash
./scripts/homelab.sh purge-cache    # Purge all cache
./scripts/homelab.sh varnish-stats  # Show statistics
```

### Nginx Management

```bash
./scripts/homelab.sh nginx-test     # Test configuration
./scripts/homelab.sh nginx-reload   # Reload configuration
```

### Create Virtual Host

```bash
# Create vhost for domain with PHP 8.2
./scripts/homelab.sh create-vhost mysite.local 8.2

# Then:
# 1. Add to /etc/hosts: 127.0.0.1 mysite.local
# 2. Create project: mkdir -p projects/mysite.local/public
# 3. Reload Nginx: ./scripts/homelab.sh nginx-reload
```

## 📁 Directory Structure

```
homelab/
├── docker-compose.yml              # Main compose file
├── .env.example                    # Environment template
├── .env                           # Your environment (create from .env.example)
│
├── nginx/
│   └── Dockerfile                 # Nginx image
│
├── varnish/
│   └── Dockerfile                 # Varnish image
│
├── php/
│   ├── 7.2/Dockerfile            # PHP 7.2 image
│   ├── 7.4/Dockerfile            # PHP 7.4 image
│   ├── 8.0/Dockerfile            # PHP 8.0 image
│   ├── 8.1/Dockerfile            # PHP 8.1 image
│   ├── 8.2/Dockerfile            # PHP 8.2 image
│   ├── 8.3/Dockerfile            # PHP 8.3 image
│   └── 8.4/Dockerfile            # PHP 8.4 image
│
├── configs/
│   ├── nginx/
│   │   ├── nginx.conf            # Main Nginx config
│   │   ├── conf.d/
│   │   │   ├── default.conf      # Default vhost
│   │   │   └── *.conf            # Your vhosts
│   │   └── ssl/                  # SSL certificates
│   │
│   ├── varnish/
│   │   └── default.vcl           # Varnish VCL
│   │
│   └── php/
│       ├── 7.2/
│       │   ├── php.ini           # PHP configuration
│       │   ├── php-fpm.conf      # PHP-FPM pool config
│       │   └── xdebug.ini        # Xdebug config
│       ├── 7.4/
│       ├── 8.0/
│       ├── 8.1/
│       ├── 8.2/
│       ├── 8.3/
│       └── 8.4/
│
├── projects/                      # Your projects (mounted to /var/www)
│   └── default/
│       └── public/
│           └── index.php
│
└── scripts/
    └── homelab.sh                # Management script
```

## 🔧 Configuration

### Environment Variables (.env)

```bash
# Project directory
PROJECT_DIR=./projects

# User/Group IDs (match your host)
UID=1000
GID=1000

# Xdebug
XDEBUG_MODE=off                    # off, debug, coverage, profile
XDEBUG_CONFIG=                     # Additional Xdebug config
XDEBUG_OUTPUT_DIR=./xdebug-output

# Varnish
VARNISH_SIZE=256M                  # Cache size

# Timezone
TZ=UTC
```

### PHP Configuration

Mỗi PHP version có config riêng tại `configs/php/{version}/`:

- **php.ini**: PHP settings (memory_limit, upload_max_filesize, etc.)
- **php-fpm.conf**: PHP-FPM pool settings (pm.max_children, etc.)
- **xdebug.ini**: Xdebug configuration

### Nginx Virtual Hosts

Tạo file `.conf` trong `configs/nginx/conf.d/`:

```nginx
server {
    listen 8080;
    server_name mysite.local;
    root /var/www/mysite/public;
    index index.php;

    location ~ \.php$ {
        fastcgi_pass php82:9000;  # Choose PHP version
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

**PHP Service Names**:
- `php72:9000` → PHP 7.2
- `php74:9000` → PHP 7.4
- `php80:9000` → PHP 8.0
- `php81:9000` → PHP 8.1
- `php82:9000` → PHP 8.2
- `php83:9000` → PHP 8.3
- `php84:9000` → PHP 8.4

### Varnish VCL

Edit `configs/varnish/default.vcl` để customize caching behavior.

## 🐛 Xdebug Setup

### 1. Enable Xdebug

```bash
# Edit .env
XDEBUG_MODE=debug
XDEBUG_CONFIG=client_host=host.docker.internal client_port=9003

# Restart stack
./scripts/homelab.sh restart
```

### 2. IDE Configuration

**PHPStorm**:
1. Settings → PHP → Debug
2. Xdebug port: `9003`
3. Settings → PHP → Servers
4. Name: `docker`
5. Host: `localhost`
6. Port: `8080`
7. Path mappings: `/path/to/projects` → `/var/www`

**VS Code** (launch.json):
```json
{
    "name": "Listen for Xdebug",
    "type": "php",
    "request": "launch",
    "port": 9003,
    "pathMappings": {
        "/var/www": "${workspaceFolder}/projects"
    }
}
```

### 3. Trigger Xdebug

Add `?XDEBUG_SESSION_START=PHPSTORM` to URL hoặc install browser extension.

## 📊 Monitoring

### View Logs

```bash
# All services
./scripts/homelab.sh logs

# Specific service
./scripts/homelab.sh logs nginx
./scripts/homelab.sh logs php84
./scripts/homelab.sh logs varnish
```

### Varnish Statistics

```bash
./scripts/homelab.sh varnish-stats
```

### PHP-FPM Status

```bash
# Access PHP-FPM status page
curl http://localhost:8080/status?full

# Or via specific PHP version
docker compose exec php84 curl http://localhost:9000/status
```

## 🔄 Switching PHP Versions

### Per Project (Recommended)

Tạo vhost riêng cho mỗi project với PHP version khác nhau:

```bash
# WordPress with PHP 7.4
./scripts/homelab.sh create-vhost wp-site.local 7.4

# Laravel with PHP 8.3
./scripts/homelab.sh create-vhost laravel-app.local 8.3
```

### Global Default

Edit `configs/nginx/conf.d/default.conf` và thay đổi `fastcgi_pass`:

```nginx
fastcgi_pass php82:9000;  # Change to desired version
```

## 🚨 Troubleshooting

### Services Won't Start

```bash
# Check logs
./scripts/homelab.sh logs

# Check status
./scripts/homelab.sh status

# Rebuild
./scripts/homelab.sh rebuild
```

### Permission Issues

```bash
# Update UID/GID in .env to match your host user
id -u  # Get your UID
id -g  # Get your GID

# Edit .env
UID=1000
GID=1000

# Rebuild
./scripts/homelab.sh rebuild
```

### Varnish Not Caching

```bash
# Check VCL syntax
docker compose exec varnish varnishadm vcl.list

# View cache hits/misses
curl -I http://localhost/
# Look for X-Cache: HIT or MISS header
```

### Nginx Configuration Error

```bash
# Test configuration
./scripts/homelab.sh nginx-test

# Check logs
./scripts/homelab.sh logs nginx
```

## 📚 Examples

### WordPress Installation

```bash
# Create project
mkdir -p projects/wordpress/public
cd projects/wordpress/public

# Download WordPress (using PHP 7.4)
./scripts/homelab.sh wp 7.4 core download

# Create vhost
./scripts/homelab.sh create-vhost wordpress.local 7.4

# Add to /etc/hosts
echo "127.0.0.1 wordpress.local" | sudo tee -a /etc/hosts

# Reload Nginx
./scripts/homelab.sh nginx-reload

# Access: http://wordpress.local
```

### Laravel Project

```bash
# Create Laravel project (using PHP 8.3)
./scripts/homelab.sh composer 8.3 create-project laravel/laravel myapp

# Create vhost
./scripts/homelab.sh create-vhost myapp.local 8.3

# Add to /etc/hosts
echo "127.0.0.1 myapp.local" | sudo tee -a /etc/hosts

# Reload Nginx
./scripts/homelab.sh nginx-reload

# Run migrations
./scripts/homelab.sh artisan 8.3 migrate

# Access: http://myapp.local
```

## 🔐 Security Notes

- Self-signed SSL certificate is for **development only**
- Change default passwords in production
- Varnish admin port (6081) should not be exposed publicly
- Review Varnish VCL for your security requirements

## 📝 License

MIT

## 🤝 Contributing

Feel free to submit issues and enhancement requests!
