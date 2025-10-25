#!/bin/bash
set -e  # Exit on error

source /root/.env

echo "🧹 Cleaning up preview for: $BRANCH_NAME"

# Sanitize branch name (replace / and _ with -)
SAFE_NAME=$(echo "$BRANCH_NAME" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]')

echo "📝 Safe name: $SAFE_NAME"

# Configuration
PREVIEW_URL="${SAFE_NAME}.${DOMAIN}"
WP_DIR="/var/www/${SAFE_NAME}"
DB_NAME="wordpress_${SAFE_NAME//-/_}"  # Replace - with _ for DB name
DB_USER="wp_${SAFE_NAME//-/_}"

# Step 1: Remove nginx config
echo "⚙️ Removing nginx config..."
if [ -f "/etc/nginx/sites-enabled/${SAFE_NAME}" ]; then
    rm /etc/nginx/sites-enabled/${SAFE_NAME}
    rm /etc/nginx/sites-available/${SAFE_NAME}
    nginx -t && systemctl reload nginx
    echo "✅ Nginx config removed"
else
    echo "⚠️  Nginx config not found"
fi

# Step 2: Remove WordPress directory
echo "📦 Removing WordPress installation..."
if [ -d "${WP_DIR}" ]; then
    rm -rf ${WP_DIR}
    echo "✅ WordPress removed"
else
    echo "⚠️  WordPress directory not found"
fi

# Step 3: Remove database
echo "💾 Removing database..."
mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<EOF
DROP DATABASE IF EXISTS ${DB_NAME};
DROP USER IF EXISTS '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    echo "✅ Database removed"
else
    echo "⚠️  Database removal had issues"
fi

# Step 4: Remove CloudFlare DNS record
echo "🌐 Removing DNS record..."

# Get DNS record ID
RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records?name=${PREVIEW_URL}" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)

if [ -n "$RECORD_ID" ]; then
    curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${RECORD_ID}" \
      -H "Authorization: Bearer ${CF_API_TOKEN}" \
      -H "Content-Type: application/json" > /dev/null
    echo "✅ DNS record removed"
else
    echo "⚠️  DNS record not found"
fi

# Step 5: Remove SSL certificate (optional - Let's Encrypt handles this)
echo "🔒 Note: SSL certificate will auto-expire in 90 days"


# Step 6: Remove environment file
if [ -f "/root/previews/${SAFE_NAME}.env" ]; then
    rm /root/previews/${SAFE_NAME}.env
    echo "✅ Environment file removed"
fi

echo "✅ Cleanup complete for ${PREVIEW_URL}"
