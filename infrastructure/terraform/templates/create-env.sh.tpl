#!/bin/bash
# Script to create feature branch environments for WordPress with SSL

# Check if argument is provided
if [ "$$#" -ne 1 ]; then
    echo "Usage: $$0 <environment-name>"
    exit 1
fi

# Use bash variables to avoid Terraform interpolation issues
ENV_NAME=$$1
ENV_PATH="/opt/wordpress-$$ENV_NAME"
DOMAIN="$$ENV_NAME.${domain_name}"

# Create directory structure
mkdir -p $$ENV_PATH/{nginx/conf.d,mysql,wordpress}

# Get SSL certificate for the feature branch subdomain
echo "Getting SSL certificate for $$DOMAIN..."
docker stop $$(docker ps -q) 2>/dev/null || true
certbot certonly --standalone --non-interactive --agree-tos --email ${ssl_email} -d $$DOMAIN
docker-compose -f /opt/wordpress/docker-compose.yml up -d

# Create docker-compose.yml
cat > $$ENV_PATH/docker-compose.yml << EOF
version: '3'

services:
  db:
    image: mysql:8.0
    container_name: $$ENV_NAME\_db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${mysql_root_password}
      MYSQL_DATABASE: ${mysql_database}_$$ENV_NAME
      MYSQL_USER: ${mysql_user}
      MYSQL_PASSWORD: ${mysql_password}
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - wordpress_network

  wordpress:
    image: wordpress:latest
    container_name: $$ENV_NAME\_app
    restart: always
    depends_on:
      - db
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: ${mysql_database}_$$ENV_NAME
      WORDPRESS_DB_USER: ${mysql_user}
      WORDPRESS_DB_PASSWORD: ${mysql_password}
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_HOME', 'https://$$DOMAIN');
        define('WP_SITEURL', 'https://$$DOMAIN');
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - wordpress_network

  nginx:
    image: nginx:latest
    container_name: $$ENV_NAME\_nginx
    restart: always
    expose:
      - 80
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - wordpress_data:/var/www/html
    depends_on:
      - wordpress
    networks:
      - wordpress_network

networks:
  wordpress_network:

volumes:
  mysql_data:
  wordpress_data:
EOF

# Create Nginx configuration for the feature branch container
cat > $$ENV_PATH/nginx/conf.d/default.conf << EOF
server {
    listen 80;
    server_name $$DOMAIN;
    
    location / {
        proxy_pass http://wordpress:80;
        proxy_set_header Host \$$host;
        proxy_set_header X-Real-IP \$$remote_addr;
        proxy_set_header X-Forwarded-For \$$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$$scheme;
    }
}
EOF

# Update main Nginx configuration to include feature branch
cat > /opt/wordpress/nginx/conf.d/$$DOMAIN.conf << EOF
# HTTP server to redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name $$DOMAIN;
    
    # Redirect all HTTP requests to HTTPS
    return 301 https://\$$host\$$request_uri;
}

# HTTPS server for feature branch
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    
    server_name $$DOMAIN;
    
    # SSL certificates
    ssl_certificate /etc/letsencrypt/live/$$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$$DOMAIN/privkey.pem;
    
    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    
    # Proxy to feature branch WordPress container
    location / {
        proxy_pass http://$$ENV_NAME\_app;
        proxy_set_header Host \$$host;
        proxy_set_header X-Real-IP \$$remote_addr;
        proxy_set_header X-Forwarded-For \$$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$$scheme;
    }
}
EOF

# Start the feature branch environment
cd $$ENV_PATH && docker-compose up -d

# Reload main Nginx to pick up the new configuration
docker exec -it wordpress_nginx nginx -s reload

echo "Feature branch environment with SSL created at https://$$DOMAIN"
echo "To remove this environment, run:"
echo "  cd $$ENV_PATH && docker-compose down -v"
echo "  rm -rf $$ENV_PATH"
echo "  rm /opt/wordpress/nginx/conf.d/$$DOMAIN.conf"
echo "  docker exec -it wordpress_nginx nginx -s reload"
