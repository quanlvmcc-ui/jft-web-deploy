# 📊 UptimeRobot Monitoring Setup Guide

**Status:** Production-ready
**Time:** 20 minutes setup
**Difficulty:** Easy
**Cost:** FREE (lên đến 50 monitors)

---

## **📋 TỔNG QUAN**

### **UptimeRobot là gì?**

UptimeRobot là dịch vụ **monitoring uptime** (giám sát thời gian hoạt động) của website/API. Nó sẽ:

✅ **Ping website mỗi 5 phút** (hoặc tùy chỉnh)
✅ **Alert ngay khi service down** (qua Email, SMS, Telegram, Slack...)
✅ **Track uptime percentage** (99.9% uptime = bao nhiêu phút down)
✅ **Hiển thị status page** công khai cho user
✅ **Free 100%** cho tối đa 50 monitors

---

### **Monitoring Strategy**

```
UptimeRobot Cloud
    ↓ (mỗi 5 phút)
Ping: https://backend.vjlink-edu.online/health
    ↓
Kiểm tra Response:
  - HTTP Status = 200 ✅
  - Response time < 2s ✅
  - Keyword "ok" có trong response ✅
    ↓
Nếu FAIL 2 lần liên tiếp:
  → Gửi alert qua Email/Telegram
  → Ghi log downtime
  → Update status page
```

---

## **🎯 GIẢI THÍCH TỪ TỪNG BƯỚC**

### **Bước 1: Tại sao cần Monitoring?**

**Vấn đề:**

- Backend crash nhưng không ai biết → User báo mới biết (mất uy tín)
- VPS hết RAM → Service down vài giờ → Mất doanh thu
- SSL certificate hết hạn → HTTPS không hoạt động

**Giải pháp:**

- UptimeRobot ping liên tục → Biết ngay khi down
- Alert tức thì → Team react nhanh (< 5 phút)
- Track uptime → Báo cáo management (SLA 99.9%)

**Ví dụ thực tế:**

```
02:15 AM: Backend crash do hết RAM
02:16 AM: UptimeRobot phát hiện (ping lần 1 fail)
02:17 AM: Ping lần 2 fail → GỬI ALERT
02:18 AM: Developer nhận email/Telegram
02:20 AM: Login VPS, restart service
02:21 AM: Service UP trở lại
```

**Không có monitoring:**

```
02:15 AM: Backend crash
08:00 AM: User đầu tiên vào web → báo lỗi (5h45p sau!)
08:30 AM: Developer thức dậy, mới biết
09:00 AM: Fix xong
→ MẤT 6h45p downtime!
```

---

### **Bước 2: Health Endpoint là gì?**

Trong backend NestJS, bạn đã có endpoint `/health`:

**File: `jft-backend/src/health/health.controller.ts`**

```typescript
@Get('health')
async checkHealth() {
  return {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    database: 'connected' // Optional: check DB
  };
}
```

**Endpoint này:**

- ✅ Trả về HTTP 200 nếu server OK
- ✅ Không cần authentication (public access)
- ✅ Check database connection (optional)
- ✅ Response nhanh (< 100ms)
- ✅ Không bị rate limit (có @SkipThrottle)

**Test:**

```bash
curl https://backend.vjlink-edu.online/health

# Response:
{
  "status": "ok",
  "timestamp": "2026-03-01T10:30:00.000Z",
  "uptime": 3600
}
```

---

### **Bước 3: UptimeRobot Hoạt Động Như Nào?**

**1. Monitor Type: HTTP(s)**

UptimeRobot gửi HTTP GET request:

```
GET https://backend.vjlink-edu.online/health
```

**2. Check Response:**

- **Status code = 200** → UP ✅
- **Status code != 200** (404, 500, timeout) → DOWN ❌

**3. Keyword Monitoring (Optional):**

```json
Response body phải chứa: "ok"
```

- Nếu response = `{"status": "ok"}` → UP ✅
- Nếu response = `{"status": "error"}` → DOWN ❌
- Nếu response = HTML error page → DOWN ❌

**4. Response Time Monitoring:**

- < 1s → Fast ⚡
- 1-2s → Normal 🟡
- > 2s → Slow 🟠
- Timeout (30s) → Down 🔴

**5. Alert Logic:**

```
Ping #1: FAIL (02:15 AM)
  ↓
Chờ 1 phút
  ↓
Ping #2: FAIL (02:16 AM)
  ↓
CONFIRM DOWN → GỬI ALERT
```

Tại sao chờ 2 lần?

- Tránh **false positive** (ping fail do network hiccup tạm thời)
- VPS có thể đang restart (10-20 giây)
- Chỉ alert khi CHẮC CHẮN down

---

## **🔧 SETUP TỪNG BƯỚC**

### **STEP 1: Đăng ký UptimeRobot**

1. Vào: https://uptimerobot.com
2. Click **"Sign Up Free"**
3. Nhập email + password (hoặc login Google)
4. Verify email

**Free Plan bao gồm:**

- ✅ 50 monitors
- ✅ 5-minute intervals
- ✅ 2 months of logs
- ✅ Email/SMS/Webhook alerts
- ✅ Public status pages

_(Không cần thẻ tín dụng)_

---

### **STEP 2: Tạo Monitor Đầu Tiên**

**2.1. Click "Add New Monitor"**

Dashboard → **"+ Add New Monitor"** (nút xanh)

**2.2. Chọn Monitor Type**

```
Monitor Type: HTTP(s)
```

**Giải thích:**

- **HTTP(s):** Check website/API qua HTTP request
- **Ping:** Chỉ check server có online không (không check app)
- **Port:** Check port cụ thể (3000, 5432...)
- **Keyword:** Check response có chứa từ khóa

Chọn **HTTP(s)** vì cần check cả backend app, không chỉ server.

**2.3. Điền Thông Tin Monitor**

```
Friendly Name: JFT Backend Health
URL (or IP): https://backend.vjlink-edu.online/health
Monitoring Interval: 5 minutes (Free plan)
```

**Giải thích:**

- **Friendly Name:** Tên hiển thị (đặt dễ nhận biết)
- **URL:** Endpoint /health đã tạo trong backend
- **Interval:** Mỗi 5 phút ping 1 lần (Free = 5 min, Paid = 1 min)

**2.4. Advanced Settings (Expand)**

```
✅ Monitor Timeout: 30 seconds
✅ Request Method: GET
✅ Keyword (optional): "ok"
✅ Keyword Type: Exists
```

**Giải thích từng option:**

**Monitor Timeout (30s):**

- Nếu request > 30s không trả về → COUNT DOWN
- Backend bình thường response < 500ms
- 30s là buffer đủ cho slow network

**Request Method (GET):**

- GET = chỉ đọc, không thay đổi data
- POST/PUT không phù hợp cho health check

**Keyword "ok":**

- Check response body có chứa text "ok"
- Tăng độ chính xác:
  - Nếu backend trả 200 nhưng response lỗi → DOWN
  - Nếu Caddy/Nginx trả 200 default page → DOWN
  - Chỉ khi response có "ok" → mới UP

**Keyword Type "Exists":**

- **Exists:** Response phải CHỨA "ok"
- **Not Exists:** Response KHÔNG được chứa "error"

**2.5. Click "Create Monitor"**

---

### **STEP 3: Tạo Thêm Monitors Cho Frontend**

Tương tự, tạo monitor cho frontend:

```
Monitor #2:
  Name: JFT Frontend (Main)
  URL: https://vjlink-edu.online
  Type: HTTP(s)
  Keyword: (không cần - Next.js SSR)

Monitor #3:
  Name: JFT Frontend (App)
  URL: https://app.vjlink-edu.online
  Type: HTTP(s)
  Keyword: (không cần)
```

**Tại sao Frontend không cần keyword?**

- Frontend = static HTML/JS → khó xác định keyword chung
- Chỉ cần check HTTP 200 là đủ
- Backend mới cần keyword vì có specific response format

---

### **STEP 4: Setup Alert Contacts**

**4.1. Vào "My Settings" → "Alert Contacts"**

**4.2. Add Email Alert**

```
Type: E-mail
E-mail to Alert: your-email@example.com
✅ Send alerts for: Down + Up
```

**Giải thích:**

- **Down:** Gửi email khi service DOWN
- **Up:** Gửi email khi service UP trở lại (để biết đã fix xong)

**Email sample:**

```
Subject: [DOWN] JFT Backend Health is DOWN

Your monitor "JFT Backend Health" is DOWN since 2026-03-01 02:15:00.

URL: https://backend.vjlink-edu.online/health
Reason: Connection timeout
Down for: 2 minutes

View details: https://uptimerobot.com/...
```

**4.3. Add Telegram Alert (Optional - Khuyến nghị)**

**Tại sao Telegram?**

- ✅ Nhận alert NGAY LẬP TỨC (faster than email)
- ✅ Mobile notification → không bỏ lỡ
- ✅ Có thể reply ngay trong chat
- ✅ Team có thể cùng nhận trong 1 group

**Setup Telegram:**

**Step 1:** Tạo Bot Telegram

```
1. Mở Telegram
2. Search: @BotFather
3. Gửi: /newbot
4. Đặt tên bot: JFT Monitoring Bot
5. Đặt username: jft_monitoring_bot
6. Copy TOKEN: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz
```

**Step 2:** Get Chat ID

```
1. Start chat với bot vừa tạo
2. Gửi bất kỳ tin nhắn: "hello"
3. Vào browser: https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates
4. Tìm "chat":{"id": 123456789}
5. Copy Chat ID
```

**Step 3:** Add vào UptimeRobot

```
Type: Telegram
Bot Token: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz
Chat ID: 123456789
✅ Send alerts for: Down + Up
```

**4.4. Add Slack Alert (Optional - For Team)**

Nếu team dùng Slack:

```
Type: Slack
Webhook URL: (lấy từ Slack Incoming Webhooks)
Channel: #monitoring
```

---

### **STEP 5: Configure Alert Settings**

**5.1. Vào "My Settings" → "Notifications"**

```
✅ Send notification when monitor goes DOWN
✅ Send notification when monitor goes UP
⬜ Send notification when monitor is PAUSED (không cần)
```

**5.2. Alert Frequency**

```
Re-alert if monitor is still down after: 30 minutes
```

**Giải thích:**

- Nếu service down quá 30 phút → Gửi alert NỮA
- Nhắc nhở team nếu quên fix
- Không spam quá nhiều (không gửi mỗi 5 phút)

---

### **STEP 6: Create Public Status Page**

**6.1. Vào "Status Pages" → "Add Status Page"**

```
Status Page URL: jft-status (sẽ là: jft-status.betteruptime.com)
Page Title: JFT Platform Status
Logo: (upload logo nếu có)
```

**6.2. Select Monitors to Show**

```
✅ JFT Backend Health
✅ JFT Frontend (Main)
✅ JFT Frontend (App)
```

**6.3. Customize Design (Optional)**

```
Theme: Dark/Light
Show Response Time: Yes
Show Uptime Percentage: Yes
Show Incident History: Yes (30 days)
```

**6.4. Get Status Page Link**

```
https://jft-status.uptimerobot.com
```

**Sử dụng:**

- Public status page → User có thể check
- Thêm vào footer website: "System Status"
- Share với khách hàng khi có incident

---

## **✅ VERIFICATION CHECKLIST**

### **Monitor Setup:**

- [ ] Backend health monitor created (https://backend.vjlink-edu.online/health)
- [ ] Frontend monitors created (vjlink-edu.online, app.vjlink-edu.online)
- [ ] Keyword "ok" configured for backend monitor
- [ ] All monitors showing "UP" status
- [ ] Response time < 2 seconds

### **Alert Setup:**

- [ ] Email alert contact added
- [ ] Telegram alert added (optional)
- [ ] Test alert received (click "Force Check" → should get notification)
- [ ] Alert frequency configured (30 min re-alert)

### **Status Page:**

- [ ] Public status page created
- [ ] All monitors displayed
- [ ] Status page link accessible
- [ ] Uptime percentage showing (should be 100%)

---

## **🧪 TESTING**

### **Test 1: Force Down**

**Cách test:**

```bash
# Stop backend container
docker stop jft-backend
```

**Kỳ vọng:**

1. Sau 5-10 phút → UptimeRobot phát hiện DOWN
2. Nhận email/Telegram alert
3. Status page hiển thị "DOWN" màu đỏ

**Restart:**

```bash
docker start jft-backend
```

**Kỳ vọng:**

1. Sau 5 phút → UptimeRobot phát hiện UP
2. Nhận email/Telegram "Service is back UP"
3. Status page hiển thị "UP" màu xanh

---

### **Test 2: Manual Alert Test**

**Trong UptimeRobot Dashboard:**

1. Click monitor name
2. Click **"Force Check"** button
3. Should receive test notification

---

### **Test 3: Response Time Check**

**Benchmark health endpoint:**

```bash
# Test from local
time curl https://backend.vjlink-edu.online/health

# Expected: < 500ms
real    0m0.234s
```

**Trong UptimeRobot:**

- View monitor details
- Check "Average Response Time"
- Should be < 1 second

---

## **📊 MONITORING BEST PRACTICES**

### **1. Monitor Multiple Endpoints**

```
✅ /health (backend core)
✅ / (frontend homepage)
✅ /api/auth/login (critical API endpoint)
```

**Tại sao?**

- `/health` UP không đảm bảo login working
- Database có thể down nhưng `process.uptime()` vẫn return

**Improve health check:**

```typescript
@Get('health')
async checkHealth() {
  // Check DB connection
  const dbCheck = await this.prisma.$queryRaw`SELECT 1`;

  return {
    status: 'ok',
    database: dbCheck ? 'connected' : 'error',
    timestamp: new Date().toISOString()
  };
}
```

---

### **2. Set Up Maintenance Windows**

**Khi nào dùng?**

- Deploy production (tránh alert spam)
- VPS maintenance (known downtime)
- Database migration (planned downtime)

**Cách setup:**

```
Dashboard → Monitor → "..." menu → "Create Maintenance"
Duration: 1 hour
Reason: "Production deployment"
```

**Effect:**

- Không gửi alerts trong maintenance window
- Status page hiển thị "Under Maintenance"

---

### **3. Monitor SSL Certificate Expiry**

**Add monitor:**

```
Type: HTTP(s)
URL: https://backend.vjlink-edu.online
✅ Monitor SSL Certificate: Enable
Alert before: 7 days
```

**Tại sao?**

- Let's Encrypt auto-renew có thể fail
- Alert trước 7 ngày → kịp fix
- Tránh HTTPS down đột ngột

---

### **4. Track Uptime SLA**

**Industry standard:**

- **99.9% uptime** = 43.8 minutes downtime/month (Good)
- **99.95% uptime** = 21.9 minutes downtime/month (Excellent)
- **99.99% uptime** = 4.38 minutes downtime/month (World-class)

**Check trong UptimeRobot:**

```
Dashboard → Monitor → "Uptime"
- Last 24 hours: 100%
- Last 7 days: 99.95%
- Last 30 days: 99.90%
```

**Report to management:**

```
Monthly Report:
- Total downtime: 32 minutes
- Uptime: 99.93%
- Incidents: 2 (database crash, VPS reboot)
- MTTR (Mean Time To Repair): 16 minutes
```

---

### **5. Integrate with Incident Management**

**Workflow:**

```
UptimeRobot Alert
    ↓
Telegram/Slack notification
    ↓
Developer acknowledges
    ↓
Create incident ticket (Jira/Linear)
    ↓
Fix issue
    ↓
Post-mortem document
    ↓
Prevent recurrence
```

---

## **🔍 TROUBLESHOOTING**

### **Monitor shows "DOWN" but site works fine**

**Possible reasons:**

**1. Firewall blocking UptimeRobot IPs**

```bash
# Check VPS firewall
sudo iptables -L | grep 3000

# Allow UptimeRobot IPs (optional)
# https://uptimerobot.com/help/monitoring-server-ips/
```

**2. Rate limiting blocking UptimeRobot**

```typescript
// Make sure health endpoint has @SkipThrottle
@SkipThrottle()
@Get('health')
async checkHealth() { ... }
```

**3. SSL certificate issues**

```bash
# Check cert
curl -vI https://backend.vjlink-edu.online/health

# Look for:
# * SSL certificate verify ok
```

**4. Response too slow (timeout)**

```bash
# Check response time
time curl https://backend.vjlink-edu.online/health

# Should be < 10 seconds
```

---

### **Not receiving email alerts**

**1. Check spam folder**

- UptimeRobot emails can go to spam
- Mark as "Not Spam"

**2. Verify alert contact**

```
My Settings → Alert Contacts
Check: Email verified ✅
```

**3. Test alert manually**

```
Monitor → Force Check
Should receive test email
```

---

### **Response time too high**

**Normal:** < 500ms
**Acceptable:** 500ms - 2s
**Slow:** 2s - 10s
**Problem:** > 10s

**Investigate:**

```bash
# Check server load
ssh vps
htop

# Check container memory
docker stats

# Check database queries
# (add query logging to Prisma)
```

---

## **📈 UPTIME REPORTS**

### **Weekly Report (Automated Email)**

UptimeRobot có thể gửi weekly report:

```
Settings → Reports → Add Report

Report Type: Weekly
Email to: team@company.com
Include:
  ✅ Uptime percentage
  ✅ Response time average
  ✅ Downtime incidents
  ✅ Total downtime duration
```

**Sample report:**

```
JFT Platform - Weekly Report (Feb 22-28, 2026)

Overall Uptime: 99.95%

Monitors:
- JFT Backend Health: 99.98% (1 min downtime)
- JFT Frontend (Main): 100% (0 downtime)
- JFT Frontend (App): 99.90% (5 min downtime)

Incidents:
1. Feb 24, 02:15 AM - Backend down (1 min)
   Reason: Automatic restart after deployment

2. Feb 26, 10:30 AM - App frontend slow (5 min)
   Reason: High traffic spike

Average Response Time:
- Backend: 234ms
- Frontend Main: 156ms
- Frontend App: 189ms
```

---

## **🎯 PRODUCTION CHECKLIST**

### **Essential (Must Have):**

- [ ] Backend /health monitor setup
- [ ] Email alert configured
- [ ] Monitor showing "UP" status
- [ ] Test alert received successfully

### **Recommended:**

- [ ] Frontend monitors setup
- [ ] Telegram alert configured
- [ ] Public status page created
- [ ] SSL certificate monitoring enabled
- [ ] Maintenance window process documented

### **Advanced:**

- [ ] Weekly uptime reports enabled
- [ ] Multiple alert contacts (team)
- [ ] Custom status page with branding
- [ ] Integration with Slack/Discord
- [ ] Incident response playbook

---

## **💡 NEXT STEPS**

After UptimeRobot setup:

1. **Log Monitoring** → Track application logs (errors, warnings)
2. **Performance Monitoring** → Response time, memory usage
3. **Error Tracking** → Sentry for exception monitoring
4. **Analytics** → User behavior, API usage

---

## **📚 RESOURCES**

- **UptimeRobot Docs:** https://uptimerobot.com/help
- **Telegram Bot API:** https://core.telegram.org/bots
- **Status Page Examples:** https://uptimerobot.com/statuspage
- **SLA Calculator:** https://uptime.is/

---

**Status:** Ready for implementation
**Estimated Setup Time:** 20 minutes
**Maintenance:** Zero (fully automated)

✅ **Sau khi setup xong, bạn sẽ:**

- Nhận alert ngay khi service down
- Track uptime percentage (SLA reporting)
- Public status page cho users
- Peace of mind 😌 (không lo backend down mà không biết)
