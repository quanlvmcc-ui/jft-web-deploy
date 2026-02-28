#!/bin/bash

#######################################################
# PostgreSQL Backup Script
# Tự động backup database và compress
# Retention: giữ 14 bản backup gần nhất
#######################################################

set -e  # Exit on error

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../.env.backup"

if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env.backup not found at $ENV_FILE"
    exit 1
fi

source "$ENV_FILE"

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/var/backups/postgres}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
POSTGRES_CONTAINER="${POSTGRES_CONTAINER:-jft-postgres}"
LOG_FILE="/var/log/postgres-backup.log"

# Create backup directory if not exists
mkdir -p "$BACKUP_DIR"

# Generate timestamp
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
DATE_ONLY=$(date +%Y-%m-%d)
BACKUP_FILE="jft_backup_${TIMESTAMP}.sql.gz"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting backup..." | tee -a "$LOG_FILE"

# Check if PostgreSQL container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER}$"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: PostgreSQL container '${POSTGRES_CONTAINER}' is not running" | tee -a "$LOG_FILE"
    exit 1
fi

# Execute pg_dump and compress
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dumping database: ${DB_NAME}..." | tee -a "$LOG_FILE"

if docker exec "$POSTGRES_CONTAINER" pg_dump \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    --no-owner \
    --no-acl \
    --verbose \
    2>> "$LOG_FILE" \
    | gzip > "$BACKUP_PATH"; then
    
    # Get backup file size
    BACKUP_SIZE=$(du -h "$BACKUP_PATH" | cut -f1)
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Backup successful: ${BACKUP_FILE} (${BACKUP_SIZE})" | tee -a "$LOG_FILE"
    
    # Verify backup integrity
    if gunzip -t "$BACKUP_PATH" 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Backup file integrity verified" | tee -a "$LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  WARNING: Backup file may be corrupted" | tee -a "$LOG_FILE"
    fi
    
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ ERROR: Backup failed" | tee -a "$LOG_FILE"
    exit 1
fi

# Cleanup old backups (retention policy)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleaning up old backups (retention: ${RETENTION_DAYS} days)..." | tee -a "$LOG_FILE"

OLD_BACKUPS=$(find "$BACKUP_DIR" -name "jft_backup_*.sql.gz" -type f -mtime +${RETENTION_DAYS})

if [ -n "$OLD_BACKUPS" ]; then
    echo "$OLD_BACKUPS" | while read -r old_file; do
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Deleting old backup: $(basename "$old_file")" | tee -a "$LOG_FILE"
        rm -f "$old_file"
    done
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] No old backups to delete" | tee -a "$LOG_FILE"
fi

# Show backup summary
TOTAL_BACKUPS=$(find "$BACKUP_DIR" -name "jft_backup_*.sql.gz" -type f | wc -l)
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup summary:" | tee -a "$LOG_FILE"
echo "  - Total backups: ${TOTAL_BACKUPS}" | tee -a "$LOG_FILE"
echo "  - Total size: ${TOTAL_SIZE}" | tee -a "$LOG_FILE"
echo "  - Latest: ${BACKUP_FILE}" | tee -a "$LOG_FILE"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup completed successfully" | tee -a "$LOG_FILE"
echo "---" | tee -a "$LOG_FILE"

exit 0
