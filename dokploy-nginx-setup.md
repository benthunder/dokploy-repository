# Dokploy Installation Without Traefik

## 🎯 Mục Tiêu
Cài đặt Dokploy nhưng sử dụng Nginx làm reverse proxy thay vì Traefik.

---

## 📋 Prerequisites

```bash
# 1. Install Docker & Docker Compose
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# 2. Create network
docker network create dokploy-network
```

---

## 🚀 Method 1: Install Dokploy Rồi Disable Traefik

### Step 1: Install Dokploy Bình Thường

```bash
curl -sSL https://dokploy.com/install.sh | sh
```

### Step 2: Stop Traefik Container

```bash
# Sau khi cài xong, stop Traefik
docker stop dokploy-traefik
docker rm dokploy-traefik

# Hoặc disable trong docker-compose
cd /etc/dokploy
docker compose stop traefik
```

### Step 3: Setup Nginx Reverse Proxy

Tạo file `/etc/nginx/sites-available/dokploy`:

```nginx
server {
    listen 80;
    server_name dokploy.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable site:
```bash
sudo ln -s /etc/nginx/sites-available/dokploy /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔧 Method 2: Custom Docker Compose (Recommended)

### Step 1: Tạo Thư Mục

```bash
mkdir -p /opt/dokploy
cd /opt/dokploy
```

### Step 2: Tạo docker-compose.yml

```yaml
version: '3.8'

services:
  dokploy:
    image: dokploy/dokploy:latest
    container_name: dokploy
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - dokploy-data:/app/data
      - /etc/dokploy:/etc/dokploy
    environment:
      - DATABASE_URL=postgresql://dokploy:dokploy@postgres:5432/dokploy
      - REDIS_URL=redis://redis:6379
      - SECRET_KEY=${SECRET_KEY}
      # Disable Traefik
      - TRAEFIK_ENABLED=false
    networks:
      - dokploy-network
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:16-alpine
    container_name: dokploy-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=dokploy
      - POSTGRES_PASSWORD=dokploy
      - POSTGRES_DB=dokploy
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - dokploy-network

  redis:
    image: redis:7-alpine
    container_name: dokploy-redis
    restart: unless-stopped
    volumes:
      - redis-data:/data
    networks:
      - dokploy-network

  # Nginx Reverse Proxy
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
      - nginx-logs:/var/log/nginx
    networks:
      - dokploy-network
    depends_on:
      - dokploy

volumes:
  dokploy-data:
  postgres-data:
  redis-data:
  nginx-logs:

networks:
  dokploy-network:
    external: true
```

### Step 3: Tạo nginx.conf

```nginx
events {
    worker_connections 1024;
}

http {
    upstream dokploy {
        server dokploy:3000;
    }

    server {
        listen 80;
        server_name _;

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
        }
    }

    # SSL Configuration (optional)
    # server {
    #     listen 443 ssl http2;
    #     server_name dokploy.yourdomain.com;
    #
    #     ssl_certificate /etc/nginx/ssl/cert.pem;
    #     ssl_certificate_key /etc/nginx/ssl/key.pem;
    #
    #     location / {
    #         proxy_pass http://dokploy;
    #         # ... same proxy settings as above
    #     }
    # }
}
```

### Step 4: Tạo .env

```bash
cat > .env << 'EOF'
SECRET_KEY=$(openssl rand -hex 32)
EOF
```

### Step 5: Start Services

```bash
docker network create dokploy-network
docker compose up -d
```

---

## 🔍 Verify Installation

```bash
# Check containers
docker ps | grep dokploy

# Check logs
docker logs dokploy
docker logs dokploy-nginx

# Access Dokploy
curl http://localhost
# Or open browser: http://your-server-ip
```

---

## 🎯 Deploy Apps Without Traefik

Khi deploy apps trong Dokploy, bạn cần:

1. **Expose ports manually** trong Docker Compose của app
2. **Configure Nginx** để proxy đến app ports

Example app deployment:

```yaml
# Your app docker-compose.yml
services:
  myapp:
    image: myapp:latest
    ports:
      - "8080:8080"  # Expose port
    networks:
      - dokploy-network
```

Thêm vào nginx.conf:

```nginx
upstream myapp {
    server myapp:8080;
}

server {
    listen 80;
    server_name myapp.yourdomain.com;

    location / {
        proxy_pass http://myapp;
        # ... proxy settings
    }
}
```

---

## 🛠️ Troubleshooting

### Dokploy không start

```bash
# Check logs
docker logs dokploy

# Check database connection
docker exec -it dokploy-postgres psql -U dokploy -d dokploy
```

### Nginx không proxy

```bash
# Test nginx config
docker exec dokploy-nginx nginx -t

# Reload nginx
docker exec dokploy-nginx nginx -s reload

# Check nginx logs
docker logs dokploy-nginx
```

---

## 📝 Notes

- Dokploy mặc định dùng Traefik để auto SSL và routing
- Khi disable Traefik, bạn phải tự quản lý:
  - SSL certificates (dùng Certbot hoặc manual)
  - Domain routing (config Nginx manually)
  - Load balancing (nếu cần)

- **Ưu điểm**: Kiểm soát hoàn toàn reverse proxy
- **Nhược điểm**: Mất tính năng auto SSL và auto routing của Traefik
