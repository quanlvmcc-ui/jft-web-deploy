#!/bin/bash

#######################################################
# PostgreSQL Restore Script
# Khôi phục database từ backup file
# Usage: ./restore-database.sh <backup-filename>
#######################################################

set -e  # Exit on error

# Check if backup file is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <backup-filename>"
    echo ""
    echo "Example:"
    echo "  $0 jft_backup_2026-02-28_02-00-00.sql.gz"
    echo ""
    echo "Available backups:"
    ls -lht /var/backups/postgres/jft_backup_*.sql.gz 2>/dev/null | head -10 || echo "  (no backups found)"
    exit 1
fi

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
POSTGRES_CONTAINER="${POSTGRES_CONTAINER:-jft-postgres}"
BACKUP_FILE="$1"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"

# Check if backup file exists
if [ ! -f "$BACKUP_PATH" ]; then
    echo "Error: Backup file not found: $BACKUP_PATH"
    echo ""
    echo "Available backups:"
    ls -lht "$BACKUP_DIR"/jft_backup_*.sql.gz 2>/dev/null | head -10
    exit 1
fi

# Verify backup file integrity
echo "Verifying backup file integrity..."
if ! gunzip -t "$BACKUP_PATH" 2>/dev/null; then
    echo "Error: Backup file is corrupted or not a valid gzip file"
    exit 1
fi

echo "✅ Backup file integrity OK"
echo ""

# Warning prompt
echo "⚠️  WARNING: This will OVERWRITE the current database!"
echo ""
echo "Database: ${DB_NAME}"
echo "Backup file: ${BACKUP_FILE}"
echo "Backup size: $(du -h "$BACKUP_PATH" | cut -f1)"
echo "Backup date: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$BACKUP_PATH" 2>/dev/null || stat -c "%y" "$BACKUP_PATH" 2>/dev/null)"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
echo

if [ "$REPLY" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

# Check if PostgreSQL container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${POSTGRES_CONTAINER}$"; then
    echo "ERROR: PostgreSQL container '${POSTGRES_CONTAINER}' is not running"
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting database restore..."

# Drop existing connections (optional, comment out if not needed)
echo "Terminating existing database connections..."
docker exec "$POSTGRES_CONTAINER" psql -U "$DB_USER" -d postgres -c "
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '${DB_NAME}'
  AND pid <> pg_backend_pid();"

# Restore database
echo "Restoring database from backup..."
if gunzip -c "$BACKUP_PATH" | docker exec -i "$POSTGRES_CONTAINER" \
    psql -U "$DB_USER" -d "$DB_NAME" \
    --single-transaction \
    2>&1 | tee /tmp/restore.log; then
    
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Database restore successful"
    
    # Verify restored data
    echo ""
    echo "Verifying restored data..."
    
    USER_COUNT=$(docker exec "$POSTGRES_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM users;" 2>/dev/null | xargs)
    EXAM_COUNT=$(docker exec "$POSTGRES_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM exams;" 2>/dev/null | xargs)
    
    echo "  - Users: ${USER_COUNT}"
    echo "  - Exams: ${EXAM_COUNT}"
    echo ""
    echo "✅ Restore completed successfully"
    
else
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ ERROR: Database restore failed"
    echo "Check /tmp/restore.log for details"
    exit 1
fi

exit 0
