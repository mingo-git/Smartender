#!/bin/bash

# =============================================================================
# Smartender Database Backup Script
# =============================================================================

BACKUP_DIR="./backups"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="smartender_backup_${DATE}.sql"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

echo "🔄 Creating database backup..."

# Create backup
docker exec smartender-postgres-prod pg_dump -U smartender_user smartender_db > "$BACKUP_DIR/$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Backup created: $BACKUP_DIR/$BACKUP_FILE"
    
    # Compress backup
    gzip "$BACKUP_DIR/$BACKUP_FILE"
    echo "✅ Backup compressed: $BACKUP_DIR/$BACKUP_FILE.gz"
    
    # Keep only last 7 backups
    cd $BACKUP_DIR
    ls -t smartender_backup_*.sql.gz | tail -n +8 | xargs -r rm
    echo "🧹 Old backups cleaned up (keeping last 7)"
else
    echo "❌ Backup failed!"
    exit 1
fi