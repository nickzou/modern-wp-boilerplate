#!/bin/bash
set -e  # Exit on error

mkdir -p /root/previews

source /root/.env

# Usage: ./deploy-preview.sh feature-branch-name
BRANCH_NAME=$1

if [ -z "$BRANCH_NAME" ]; then
    echo "Usage: $0 <branch-name>"
    exit 1
fi

echo "Deploying preview for branch: $BRANCH_NAME"

# Sanitize branch name (replace / and _ with -)
SAFE_NAME=$(echo "$BRANCH_NAME" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]')

echo "📝 Safe name: $SAFE_NAME"

# Configuration
PREVIEW_URL="${SAFE_NAME}.${DOMAIN}"
WP_DIR="/var/www/${SAFE_NAME}"
DB_NAME="wordpress_${SAFE_NAME//-/_}"  # Replace - with _ for DB name
DB_USER="wp_${SAFE_NAME//-/_}"
DB_PASS=$(openssl rand -base64 16)  # Random password
DROPLET_IP=$(curl -s -4 icanhazip.com)

# Step 1: Create CloudFlare DNS record
echo "🌐 Creating DNS record for ${PREVIEW_URL}..."

CF_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "A",
    "name": "'${SAFE_NAME}'",
    "content": "'${DROPLET_IP}'",
    "ttl": 120,
    "proxied": true
  }')

# Check if successful
if echo "$CF_RESPONSE" | grep -q '"success":true'; then
    echo "✅ DNS record created"
else
    echo "❌ DNS creation failed:"
    echo "$CF_RESPONSE"
    exit 1
fi

# Step 2: Create database
echo "💾 Creating database ${DB_NAME}..."

mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    echo "✅ Database created"
else
    echo "❌ Database creation failed"
    exit 1
fi

# Store DB credentials for later use (optional - for debugging)
echo "DB_NAME=${DB_NAME}" >> /root/previews/${SAFE_NAME}.env
echo "DB_USER=${DB_USER}" >> /root/previews/${SAFE_NAME}.env
echo "DB_PASS=${DB_PASS}" >> /root/previews/${SAFE_NAME}.env

# Step 3: Install WordPress
echo "📦 Copying production WordPress to ${WP_DIR}..."

cp -r /var/www/production ${WP_DIR}
chown -R www-data:www-data ${WP_DIR}

if [ -d "${WP_DIR}" ]; then
    echo "✅ WordPress copied"
else
    echo "❌ WordPress copy failed"
    exit 1
fi

# Update wp-config.php with new database credentials
echo "⚙️  Updating database credentials..."
sudo -u www-data wp --path=${WP_DIR} config set DB_NAME ${DB_NAME}
sudo -u www-data wp --path=${WP_DIR} config set DB_USER ${DB_USER}
sudo -u www-data wp --path=${WP_DIR} config set DB_PASSWORD ${DB_PASS}

echo "✅ Database credentials updated"

# Export from production
sudo -u www-data wp --path=/var/www/production db export /tmp/preview-db.sql

if sudo -u www-data wp --path=/var/www/production db export /tmp/preview-db.sql; then
    echo "✅ Database exported"
else
    echo "❌ Database export failed"
    exit 1
fi

# Import to preview
sudo -u www-data wp --path=${WP_DIR} db import /tmp/preview-db.sql

# Update URLs in database
sudo -u www-data wp --path=${WP_DIR} search-replace "${DOMAIN}" "${PREVIEW_URL}" --skip-columns=guid

# Clean up
rm /tmp/preview-db.sql

# Step 4: Generate nginx config from template
echo "⚙️ Configuring nginx..."

# Generate nginx config from template
sed -e "s|{{PREVIEW_URL}}|${PREVIEW_URL}|g" \
    -e "s|{{WP_DIR}}|${WP_DIR}|g" \
    /root/templates/preview-nginx.conf.tpl > /etc/nginx/sites-available/${SAFE_NAME}

# Symlink to enable
ln -sf /etc/nginx/sites-available/${SAFE_NAME} /etc/nginx/sites-enabled/${SAFE_NAME}

# Test nginx config
if nginx -t 2>/dev/null; then
    systemctl reload nginx
    echo "✅ Nginx configured"
else
    echo "❌ Nginx config failed"
    nginx -t  # Show error
    exit 1
fi

# Step 5: Get SSL certificate
echo "🔒 Getting SSL certificate..."

# Get list of current domains from existing cert
CURRENT_DOMAINS=$(certbot certificates 2>/dev/null | grep "Domains:" | head -1 | cut -d: -f2 | tr ',' '\n' | xargs)

# Add our new domain to the list
ALL_DOMAINS="${CURRENT_DOMAINS} ${PREVIEW_URL}"

# Build certbot command with all domains
CERTBOT_CMD="certbot certonly --nginx --expand --non-interactive --agree-tos --email ${TF_SSL_EMAIL}"

for domain in ${ALL_DOMAINS}; do
    CERTBOT_CMD="${CERTBOT_CMD} -d ${domain}"
done

if eval $CERTBOT_CMD; then
    echo "✅ SSL certificate obtained"
    systemctl reload nginx  # Reload nginx to use new cert
else
    echo "❌ SSL certificate failed"
    exit 1
fi

# Step 6: Purge Cache for the preview URL
echo "🧹 Purging Cloudflare cache..."
curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/purge_cache" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{\"files\":[\"https://${PREVIEW_URL}\"]}" > /dev/null
echo "✅ Cache purged"


echo "Preview deployment complete!"
echo "URL: https://${PREVIEW_URL}"
