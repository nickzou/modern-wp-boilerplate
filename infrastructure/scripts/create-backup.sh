#!/bin/bash
set -e

source /root/.env

BACKUP_DIR="/root/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

echo "Starting production backup at $(date)"

# Backup production database only
mysqldump -uroot -p"${MYSQL_ROOT_PASSWORD}" wordpress_prod | gzip > $BACKUP_DIR/wordpress_prod.sql.gz

# Backup production uploads only
tar -czf $BACKUP_DIR/production_uploads.tar.gz /var/www/production/wp-content/uploads

# Keep last 7 days only
find /root/backups -type d -mtime +30 -exec rm -rf {} + 2>/dev/null || true

echo "Production backup completed at $(date)"
echo "Database: $(du -sh $BACKUP_DIR/wordpress_prod.sql.gz | cut -f1)"
echo "Uploads: $(du -sh $BACKUP_DIR/production_uploads.tar.gz | cut -f1)"
