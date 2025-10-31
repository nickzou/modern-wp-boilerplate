#!/bin/bash
set -e  # Exit on error

source /root/.env

# Usage: ./deploy-preview.sh feature-branch-name
TARGET_ENV=$1

if [ -z "$TARGET_ENV" ]; then
    echo "Usage: $0 <staging|dev>"
    exit 1
fi

echo "🔄 Syncing production to $TARGET_ENV..."

# Set paths and URLs based on target environment
TARGET_PATH="/var/www/$TARGET_ENV"
TARGET_URL="$TARGET_ENV.${DOMAIN}"

echo "📦 Exporting production database..."
sudo -u www-data wp --path=/var/www/production db export /tmp/prod-to-$TARGET_ENV.sql

echo "💾 Importing to $TARGET_ENV database..."
sudo -u www-data wp --path=$TARGET_PATH db import /tmp/prod-to-$TARGET_ENV.sql

echo "🔗 Updating URLs for $TARGET_ENV..."
sudo -u www-data wp --path=$TARGET_PATH search-replace "${DOMAIN}" "$TARGET_URL" --skip-columns=guid

echo "📸 Syncing uploads..."
rsync -a --delete /var/www/production/wp-content/uploads/ $TARGET_PATH/wp-content/uploads/

echo "🧹 Flushing cache..."
sudo -u www-data wp --path=$TARGET_PATH cache flush || true
sudo -u www-data wp --path=$TARGET_PATH redis flush || true
