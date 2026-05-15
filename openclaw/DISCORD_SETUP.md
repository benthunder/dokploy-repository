# Discord Bot Setup Guide

## Bước 1: Tạo Discord Application

1. Truy cập https://discord.com/developers/applications
2. Click **"New Application"**
3. Đặt tên cho bot (ví dụ: "OpenClaw Bot")
4. Click **"Create"**

## Bước 2: Tạo Bot

1. Trong Application, chọn tab **"Bot"** ở sidebar
2. Click **"Add Bot"** → Confirm
3. Trong phần **"Token"**, click **"Reset Token"** → Copy token này
   - ⚠️ **Lưu token này an toàn, không share công khai**
   - Token có dạng: `MTIzNDU2Nzg5MDEyMzQ1Njc4.GaBcDe.FgHiJkLmNoPqRsTuVwXyZ123456789`

## Bước 3: Cấu hình Bot Permissions

1. Vẫn trong tab **"Bot"**
2. Scroll xuống **"Privileged Gateway Intents"**
3. Bật các intents sau:
   - ✅ **Message Content Intent** (bắt buộc)
   - ✅ **Server Members Intent** (optional)
   - ✅ **Presence Intent** (optional)

## Bước 4: Invite Bot vào Server

1. Chọn tab **"OAuth2"** → **"URL Generator"**
2. Trong **"Scopes"**, chọn:
   - ✅ `bot`
   - ✅ `applications.commands` (nếu dùng slash commands)
3. Trong **"Bot Permissions"**, chọn:
   - ✅ Read Messages/View Channels
   - ✅ Send Messages
   - ✅ Read Message History
   - ✅ Embed Links
   - ✅ Attach Files
   - ✅ Add Reactions (optional)
4. Copy **Generated URL** ở dưới cùng
5. Paste URL vào browser → Chọn server → **"Authorize"**

## Bước 5: Lấy Channel ID

1. Mở Discord Desktop/Web
2. Vào **User Settings** → **Advanced**
3. Bật **"Developer Mode"**
4. Quay lại server, **right-click** vào channel muốn bot hoạt động
5. Click **"Copy Channel ID"**
   - Channel ID có dạng: `123456789012345678` (18 chữ số)

## Bước 6: Cấu hình OpenClaw

Mở file `.env` và uncomment + điền:

```env
DISCORD_BOT_TOKEN=MTIzNDU2Nzg5MDEyMzQ1Njc4.GaBcDe.FgHiJkLmNoPqRsTuVwXyZ123456789
DISCORD_CHANNEL_ID=123456789012345678
```

## Bước 7: Khởi động

```bash
docker compose restart
```

## Kiểm tra Bot hoạt động

1. Vào Discord channel đã cấu hình
2. Bot sẽ xuất hiện **Online** trong member list
3. Gửi message test để bot phản hồi

## Troubleshooting

### Bot offline
- Kiểm tra token đúng chưa
- Kiểm tra bot đã được invite vào server chưa
- Xem logs: `docker compose logs -f`

### Bot không đọc được messages
- Kiểm tra **Message Content Intent** đã bật chưa
- Kiểm tra bot có quyền **Read Messages** trong channel

### Bot không gửi được messages
- Kiểm tra bot có quyền **Send Messages** trong channel
- Kiểm tra Channel ID đúng chưa

## Permissions Summary

| Permission | Required | Purpose |
|------------|----------|---------|
| View Channels | ✅ Yes | Xem channel |
| Send Messages | ✅ Yes | Gửi messages |
| Read Message History | ✅ Yes | Đọc lịch sử chat |
| Embed Links | ✅ Yes | Gửi rich embeds |
| Attach Files | ⚠️ Recommended | Gửi files/images |
| Add Reactions | ❌ Optional | React vào messages |
| Manage Messages | ❌ Optional | Xóa messages |

## Security Notes

⚠️ **Quan trọng:**
- **Không** commit file `.env` vào Git
- **Không** share Bot Token công khai
- Nếu token bị leak, reset ngay tại Discord Developer Portal
- Chỉ cấp quyền tối thiểu cần thiết cho bot

## Example .env

```env
# ChiaSeGPU LLM Provider
ANTHROPIC_API_KEY=sk-895afcbf05487cbe22c8455886865c2a0a77167950279771065baa7754d01232
ANTHROPIC_BASE_URL=https://llm.chiasegpu.vn

# Model Configuration
MODEL_SMALL=claude-haiku-4-5-20251001
MODEL_MEDIUM=claude-haiku-4-5-20251001
MODEL_HIGH=claude-haiku-4-5-20251001

# Discord Bot
DISCORD_BOT_TOKEN=MTIzNDU2Nzg5MDEyMzQ1Njc4.GaBcDe.FgHiJkLmNoPqRsTuVwXyZ123456789
DISCORD_CHANNEL_ID=123456789012345678

# Application Settings
NODE_ENV=production
PORT=3001
```

## Useful Links

- Discord Developer Portal: https://discord.com/developers/applications
- Discord.js Guide: https://discordjs.guide/
- Discord API Docs: https://discord.com/developers/docs
