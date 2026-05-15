# OpenClaw với ChiaSeGPU LLM Provider

Docker Compose setup cho OpenClaw sử dụng ChiaSeGPU làm LLM provider.

## Cấu trúc

```
openclaw/
├── docker-compose.yml    # Docker Compose configuration
├── .env.example          # Environment variables template
└── README.md            # This file
```

## Cài đặt

### 1. Copy environment file

```bash
cd openclaw
cp .env.example .env
```

### 2. Cấu hình (nếu cần)

File `.env` đã được cấu hình sẵn với:
- **API Key**: ChiaSeGPU API key
- **Endpoint**: https://llm.chiasegpu.vn
- **Models**: claude-haiku-4-5-20251001 cho tất cả tiers

Nếu muốn thêm Telegram bot, uncomment và điền:
```env
TELEGRAM_BOT_TOKEN=your_bot_token_from_@BotFather
TELEGRAM_USER_ID=your_telegram_user_id
```

### 3. Khởi động

```bash
docker compose up -d
```

### 4. Kiểm tra logs

```bash
docker compose logs -f openclaw
```

### 5. Truy cập

OpenClaw sẽ chạy tại: http://localhost:3000

## Quản lý

### Dừng service
```bash
docker compose down
```

### Dừng và xóa volumes
```bash
docker compose down -v
```

### Restart service
```bash
docker compose restart
```

### Xem logs
```bash
docker compose logs -f
```

### Kiểm tra health
```bash
docker compose ps
```

## Cấu hình nâng cao

### Thay đổi port

Sửa trong `docker-compose.yml`:
```yaml
ports:
  - "8080:3000"  # Thay 8080 bằng port bạn muốn
```

### Thay đổi models

Sửa trong `.env`:
```env
MODEL_SMALL=claude-haiku-4-5-20251001
MODEL_MEDIUM=claude-sonnet-4-6
MODEL_HIGH=claude-opus-4-7
```

### Discord Bot Setup

1. Tạo Discord Application tại https://discord.com/developers/applications
2. Tạo Bot và copy Bot Token
3. Enable "Message Content Intent" trong Bot settings
4. Invite bot vào server của bạn với quyền:
   - Read Messages/View Channels
   - Send Messages
   - Read Message History
5. Lấy Channel ID (bật Developer Mode trong Discord → Right click channel → Copy ID)
6. Uncomment và điền vào `.env`:
```env
DISCORD_BOT_TOKEN=your_bot_token_here
DISCORD_CHANNEL_ID=123456789012345678
```

## Volumes

- `openclaw_data`: Lưu trữ dữ liệu ứng dụng
- `openclaw_logs`: Lưu trữ logs

## Network

Service chạy trên network `openclaw_network` (bridge mode).

## Health Check

Docker sẽ tự động kiểm tra health mỗi 30 giây qua endpoint `/health`.

## Troubleshooting

### Container không start
```bash
docker compose logs openclaw
```

### Kiểm tra API key
```bash
curl -H "Authorization: Bearer sk-895afcbf05487cbe22c8455886865c2a0a77167950279771065baa7754d01232" \
  https://llm.chiasegpu.vn/v1/models
```

### Reset hoàn toàn
```bash
docker compose down -v
docker compose up -d
```

## Tích hợp với Dokploy

Để deploy lên Dokploy:

1. Tạo project mới trong Dokploy
2. Chọn "Docker Compose"
3. Upload file `docker-compose.yml`
4. Cấu hình environment variables từ `.env`
5. Deploy

## Bảo mật

⚠️ **Quan trọng**:
- Không commit file `.env` vào Git
- API key đã được cấu hình sẵn, giữ bí mật
- Nếu deploy production, nên rotate API key định kỳ

## Hỗ trợ

- OpenClaw: https://github.com/openclaw/openclaw
- ChiaSeGPU: https://chiasegpu.vn
