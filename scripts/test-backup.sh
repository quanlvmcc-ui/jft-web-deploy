#!/bin/bash

#######################################################
# Test Backup Script
# Chạy backup ngay lập tức để test
#######################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "Testing Database Backup"
echo "========================================="
echo ""

# Run backup
echo "Running backup script..."
"${SCRIPT_DIR}/backup-database.sh"

echo ""
echo "========================================="
echo "Backup Test Results"
echo "========================================="
echo ""

# Show latest backup
BACKUP_DIR="/var/backups/postgres"
LATEST_BACKUP=$(ls -t "${BACKUP_DIR}"/jft_backup_*.sql.gz 2>/dev/null | head -1)

if [ -n "$LATEST_BACKUP" ]; then
    echo "✅ Latest backup created:"
    echo "  File: $(basename "$LATEST_BACKUP")"
    echo "  Size: $(du -h "$LATEST_BACKUP" | cut -f1)"
    echo "  Date: $(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$LATEST_BACKUP" 2>/dev/null || stat -c "%y" "$LATEST_BACKUP" 2>/dev/null)"
    echo ""
    
    # Test file integrity
    echo "Testing backup file integrity..."
    if gunzip -t "$LATEST_BACKUP" 2>/dev/null; then
        echo "✅ Backup file integrity OK"
    else
        echo "❌ Backup file is corrupted"
        exit 1
    fi
    echo ""
    
    # Show file content preview
    echo "Backup file preview (first 10 lines):"
    gunzip -c "$LATEST_BACKUP" | head -10
    echo "..."
    echo ""
    
    # Show all backups
    echo "All available backups:"
    ls -lht "${BACKUP_DIR}"/jft_backup_*.sql.gz | head -10
    echo ""
    
    # Show total backup size
    TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
    TOTAL_COUNT=$(ls -1 "${BACKUP_DIR}"/jft_backup_*.sql.gz 2>/dev/null | wc -l)
    echo "Total backups: ${TOTAL_COUNT}"
    echo "Total size: ${TOTAL_SIZE}"
    
else
    echo "❌ No backup file found"
    exit 1
fi

echo ""
echo "========================================="
echo "✅ Backup test completed successfully"
echo "========================================="
