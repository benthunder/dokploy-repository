# OpenClaw - ChiaSeGPU Integration

## Files Created

```
openclaw/
├── docker-compose.yml    # Docker Compose configuration
├── .env.example          # Environment template
├── start.sh             # Quick start script
└── README.md            # Documentation
```

## Quick Start

```bash
cd openclaw
./start.sh
```

Script sẽ tự động:
- Tạo file `.env` từ template
- Hỏi có muốn cấu hình Telegram không (optional)
- Pull image mới nhất
- Khởi động OpenClaw
- Hiển thị URL truy cập

## Manual Start

```bash
cd openclaw
cp .env.example .env
docker compose up -d
```

## Configuration

### LLM Provider (ChiaSeGPU)
- **Endpoint**: https://llm.chiasegpu.vn
- **API Key**: Đã được cấu hình sẵn
- **Models**: claude-haiku-4-5-20251001

### Discord Bot (Optional)
Uncomment trong `.env`:
```env
DISCORD_BOT_TOKEN=your_bot_token
DISCORD_CHANNEL_ID=your_channel_id
```

**Cách lấy Discord credentials:**
1. Tạo app tại https://discord.com/developers/applications
2. Tạo Bot → Copy Token
3. Enable "Message Content Intent"
4. Invite bot vào server (quyền: Read/Send Messages)
5. Copy Channel ID (Developer Mode → Right click channel)

## Access

- **URL**: http://localhost:3001
- **Port**: 3001 (có thể thay đổi trong docker-compose.yml)

## Management

```bash
# View logs
docker compose logs -f

# Restart
docker compose restart

# Stop
docker compose down

# Stop and remove data
docker compose down -v
```

## Deploy to Dokploy

1. Upload `docker-compose.yml` to Dokploy
2. Set environment variables from `.env`
3. Deploy

## Notes

- API key đã được cấu hình sẵn từ chiasegpu.vn
- Port mặc định: 3001 (tránh conflict với các service khác)
- Health check tự động mỗi 30 giây
- Data được lưu trong Docker volumes
