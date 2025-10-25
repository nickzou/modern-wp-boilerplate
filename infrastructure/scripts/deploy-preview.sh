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

# TODO: Sanitize branch name (remove special chars)
# TODO: Create CloudFlare DNS record
# TODO: Create database
# TODO: Install WordPress
# TODO: Generate nginx config
# TODO: Get SSL cert
# TODO: Reload nginx

# Sanitize branch name (replace / and _ with -)
SAFE_NAME=$(echo "$BRANCH_NAME" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]')

echo "🚀 Deploying preview for: $BRANCH_NAME"
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
echo "📦 Installing WordPress to ${WP_DIR}..."

# Download WordPress
cd /tmp
curl -O https://wordpress.org/latest.tar.gz
tar xzf latest.tar.gz

# Move to web directory
mkdir -p ${WP_DIR}
cp -a wordpress/. ${WP_DIR}/
chown -R www-data:www-data ${WP_DIR}

# Clean up
rm -rf wordpress latest.tar.gz

if [ -d "${WP_DIR}" ]; then
    echo "✅ WordPress installed"
else
    echo "❌ WordPress installation failed"
    exit 1
fi

# Create wp-config.php
echo "⚙️  Configuring WordPress..."
sudo -u www-data wp --path=${WP_DIR} config create \
  --dbname=${DB_NAME} \
  --dbuser=${DB_USER} \
  --dbpass=${DB_PASS} \
  --dbhost=localhost \
  --skip-check

if [ $? -eq 0 ]; then
    echo "✅ wp-config.php created"
else
    echo "❌ wp-config.php creation failed"
    exit 1
fi

# Export from production
sudo -u www-data wp --path=/var/www/production db export /tmp/preview-db.sql

# Import to preview
sudo -u www-data wp --path=${WP_DIR} db import /tmp/preview-db.sql

# Update URLs in database
sudo -u www-data wp --path=${WP_DIR} search-replace "pandacalculus.com" "${PREVIEW_URL}" --skip-columns=guid

# Clean up
rm /tmp/preview-db.sql

# Copy uploads folder (media library)
echo "🖼️ Copying media files..."

if [ -d "/var/www/production/wp-content/uploads" ]; then
    cp -r /var/www/production/wp-content/uploads ${WP_DIR}/wp-content/
    chown -R www-data:www-data ${WP_DIR}/wp-content/uploads
    echo "✅ Media files copied"
else
    echo "⚠️  No uploads folder found in production"
fi

# Step 4: Generate nginx config from template
echo "⚙️  Configuring nginx..."

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


echo "Preview deployment complete!"
echo "URL: https://${BRANCH_NAME}.${DOMAIN}"
