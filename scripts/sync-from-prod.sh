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

# Step 1: Export database on server
echo "📦 Exporting production database..."
ssh $SERVER "sudo -u www-data wp --path=$REMOTE_WP_PATH db export /tmp/prod-export.sql"

# Step 2: Download database
echo "⬇️  Downloading database..."
scp $SERVER:/tmp/prod-export.sql /tmp/prod-export.sql

# Step 3: Import to local wp-env
echo "💾 Importing to local database..."
npx wp-env run cli wp db import ./tmp/prod-export.sql

# Step 4: Update URLs for local environment
echo "🔗 Updating URLs..."
npx wp-env run cli wp search-replace "$TF_DOMAIN_NAME" "localhost:8888" --skip-columns=guid

# Step 5: Flush Redis cache (if you're using Redis locally)
echo "🧹 Flushing cache..."
npx wp-env run cli wp cache flush || true

# Step 6: Download media/uploads
echo "📸 Syncing media files..."
rsync -avz --progress $SERVER:/var/www/production/wp-content/uploads/ ./web/wp-content/uploads/

# Step 7: Cleanup
echo "🧹 Cleaning up remote temp files..."
ssh $SERVER "rm /tmp/prod-export.sql"
rm ./tmp/prod-export.sql

echo "✅ Done! Your local environment is now synced with production."
echo "🌐 Visit: http://$LOCAL_URL"
echo ""
echo "💡 You may need to log in again."
echo "   If you forgot your password, run:"
echo "   npx wp-env run cli wp user update admin --user_pass=password"
