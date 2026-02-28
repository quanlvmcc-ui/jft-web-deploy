# 💾 Database Backup - Quick Start

## **📁 CẤU TRÚC FILE**

```
jft-deploy/
├── scripts/
│   ├── backup-database.sh       ← Script backup chính
│   ├── restore-database.sh      ← Script khôi phục
│   └── test-backup.sh           ← Test backup ngay
├── .env.backup.example          ← Template config
├── .env.backup                  ← Config thật (tự tạo)
└── cron-backup.txt              ← Template cron job
```

---

## **🚀 SETUP NHANH (5 PHÚT)**

### **Bước 1: Tạo config file**

```bash
cd jft-deploy
cp .env.backup.example .env.backup
nano .env.backup
```

Điền thông tin:

```env
DB_NAME=jft_database
DB_USER=postgres
DB_PASSWORD=your-password
POSTGRES_CONTAINER=jft-postgres
```

Bảo mật:

```bash
chmod 600 .env.backup
```

### **Bước 2: Cấp quyền thực thi**

```bash
chmod +x scripts/*.sh
```

### **Bước 3: Test backup**

```bash
./scripts/test-backup.sh
```

### **Bước 4: Setup cron (tự động)**

```bash
crontab -e
```

Thêm dòng:

```cron
0 2 * * * /path/to/jft-deploy/scripts/backup-database.sh >> /var/log/postgres-backup.log 2>&1
```

---

## **📝 SỬ DỤNG**

### **Backup thủ công**

```bash
./scripts/backup-database.sh
```

### **Restore backup**

```bash
./scripts/restore-database.sh jft_backup_2026-02-28_02-00-00.sql.gz
```

### **Xem backup hiện có**

```bash
ls -lht /var/backups/postgres/
```

### **Xem log**

```bash
tail -f /var/log/postgres-backup.log
```

---

## **🔍 GIẢI THÍCH CHI TIẾT**

Đọc file [DATABASE_BACKUP_GUIDE.md](../DATABASE_BACKUP_GUIDE.md) để hiểu:

- Backup strategy
- Cách hoạt động từng script
- Troubleshooting
- Best practices

---

## **✅ CHECKLIST**

- [ ] File `.env.backup` đã tạo và có chmod 600
- [ ] Scripts có quyền thực thi (`chmod +x`)
- [ ] Test backup thành công
- [ ] Cron job đã add
- [ ] Test restore thành công (trên DB test)

---

## **⚠️ LƯU Ý**

1. **Restore sẽ GHI ĐÈ dữ liệu hiện tại** - luôn test trên DB dev trước
2. **Backup không mã hóa** - cân nhắc encrypt nếu data nhạy cảm
3. **Retention 14 ngày** - backup cũ hơn sẽ tự động xóa
4. **Monitor disk space** - tránh backup làm đầy ổ đĩa

---

**Cần giúp?** Đọc [DATABASE_BACKUP_GUIDE.md](../DATABASE_BACKUP_GUIDE.md)
