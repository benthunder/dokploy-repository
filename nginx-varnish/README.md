# Nginx + Varnish Stack

Stack này bao gồm Nginx (backend) và Varnish (cache layer).

## Cấu trúc

```
nginx-varnish/
├── docker-compose.yml          # Main compose file
├── .env.example               # Environment variables template
├── nginx/
│   └── conf.d/
│       └── default.conf       # Nginx config
└── varnish/
    └── default.vcl            # Varnish config
```

## Luồng request

```
Client → Varnish (port 80) → Nginx (port 8080) → Application
```

## Cách sử dụng

### 1. Setup

```bash
# Copy environment file
cp .env.example .env

# Tạo thư mục cần thiết
mkdir -p nginx/certs
mkdir -p /var/www/html
```

### 2. Deploy trên Dokploy

1. Upload toàn bộ thư mục `nginx-varnish/`
2. Dokploy sẽ tự động đọc `docker-compose.yml`
3. Services sẽ start theo thứ tự: Nginx → Varnish (nhờ `depends_on`)

### 3. Test

```bash
# Test Nginx trực tiếp
curl http://localhost:8080

# Test qua Varnish
curl http://localhost:80

# Check cache status
curl -I http://localhost:80
# Xem header X-Cache: HIT hoặc MISS
```

### 4. Purge cache

```bash
# Purge specific URL
curl -X PURGE http://localhost:80/path/to/page

# Purge all (cần vào container)
docker exec varnish-cache varnishadm "ban req.url ~ ."
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NGINX_PORT` | 8080 | Nginx backend port |
| `VARNISH_PORT` | 80 | Varnish public port |
| `VARNISH_ADMIN_PORT` | 6082 | Varnish admin port |
| `VARNISH_SIZE` | 512M | Cache size |
| `CONF_DIR` | ./nginx/conf.d | Nginx config directory |
| `PROJECT_DIR` | /var/www | Web root directory |
| `VARNISH_VCL` | ./varnish/default.vcl | Varnish VCL file |

## Features

### Nginx
- Health check endpoint: `/nginx-health`
- Static file caching
- PHP-FPM support (nếu có)

### Varnish
- Cache static files: 7 days
- Cache HTML: 1 hour
- Không cache POST/PUT/DELETE
- Không cache nếu có session cookie
- Purge cache support
- Debug headers (X-Cache, X-Cache-Hits)

## Monitoring

```bash
# Xem Varnish stats
docker exec varnish-cache varnishstat

# Xem Varnish log
docker exec varnish-cache varnishlog

# Xem cache hits
docker exec varnish-cache varnishadm "backend.list"
```

## Troubleshooting

### Varnish không connect được Nginx
```bash
# Check network
docker exec varnish-cache ping nginx-backend

# Check Nginx health
docker exec nginx-backend nginx -t
```

### Cache không hoạt động
```bash
# Check VCL syntax
docker exec varnish-cache varnishadm vcl.list

# Reload VCL
docker exec varnish-cache varnishadm vcl.load new_config /etc/varnish/default.vcl
docker exec varnish-cache varnishadm vcl.use new_config
```

## Notes

- Varnish chỉ start sau khi Nginx healthy (nhờ `condition: service_healthy`)
- Nginx expose port 8080 (backend), Varnish expose port 80 (public)
- Tất cả trong cùng 1 file `docker-compose.yml` để Dokploy có thể deploy
- Network `web-tier` được tạo tự động, không cần external network
