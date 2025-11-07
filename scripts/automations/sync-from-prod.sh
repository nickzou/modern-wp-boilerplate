#!/bin/bash
set -e

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo "❌ .env not found!"
    exit 1
fi

SERVER="root@$(cd infrastructure && terraform output -raw droplet_ip)"
REMOTE_WP_PATH="/var/www/production"

echo "🔄 Syncing production to local wp-env..."

# Export database on server
echo "📦 Exporting production database..."
ssh $SERVER "sudo -u www-data wp --path=$REMOTE_WP_PATH db export /tmp/prod-export.sql"

# Download database
echo "⬇️  Downloading database..."
scp $SERVER:/tmp/prod-export.sql ./tmp/prod-export.sql

# Import to local wp-env
echo "💾 Importing to local database..."
npx wp-env run cli wp db import ./tmp/prod-export.sql

# Update URLs for local environment
echo "🔗 Updating URLs..."
npx wp-env run cli wp search-replace "$TF_DOMAIN_NAME" "localhost:8888" --skip-columns=guid

# Discouraging search engines
echo "🚫 Discouraging search engines..."
npx wp-env run cli wp option update blog_public 0

# Flush Redis cache (if you're using Redis locally)
echo "🧹 Flushing cache..."
npx wp-env run cli wp cache flush || true

# Download media/uploads
echo "📸 Syncing media files..."
rsync -avz --progress $SERVER:/var/www/production/wp-content/uploads/ ./web/wp-content/uploads/

# Cleanup
echo "🧹 Cleaning up remote temp files..."
ssh $SERVER "rm /tmp/prod-export.sql"
rm ./tmp/prod-export.sql

echo "✅ Done! Your local environment is now synced with production."
echo "🌐 Visit: http://localhost:8888"
echo ""
echo "💡 You may need to log in again."
echo "   If you forgot your password, run:"
echo "   npx wp-env run cli wp user update admin --user_pass=password"
