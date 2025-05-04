#!/bin/bash
# Script to create feature branch environments for WordPress

# Check if argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <environment-name>"
    exit 1
fi

ENV_NAME=$1
ENV_PATH="/opt/wordpress-$ENV_NAME"
DOMAIN="$ENV_NAME.${domain_name}"

# Create directory structure
mkdir -p $ENV_PATH/{nginx/conf.d,mysql,wordpress}

# Create docker-compose.yml
cat > $ENV_PATH/docker-compose.yml << EOF
version: '3'

services:
  db:
    image: mysql:8.0
    container_name: ${ENV_NAME}_db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${mysql_root_password}
      MYSQL_DATABASE: ${mysql_database}
      MYSQL_USER: ${mysql_user}
      MYSQL_PASSWORD: ${mysql_password}
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - wordpress_network

  wordpress:
    image: wordpress:latest
    container_name: ${ENV_NAME}_app
    restart: always
    depends_on:
      - db
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_NAME: ${mysql_database}
      WORDPRESS_DB_USER: ${mysql_user}
      WORDPRESS_DB_PASSWORD: ${mysql_password}
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - wordpress_network

  nginx:
    image: nginx:latest
    container_name: ${ENV_NAME}_nginx
    restart: always
    ports:
      - "80"
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

# Create Nginx configuration
cat > $ENV_PATH/nginx/conf.d/default.conf << EOF
server {
    listen 80;

    server_name $DOMAIN;
    
    location / {
        proxy_pass http://wordpress:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Update main Nginx configuration to include feature branch
cat > /opt/wordpress/nginx/conf.d/$DOMAIN.conf << EOF
server {
    listen 80;

    server_name $DOMAIN;
    
    location / {
        proxy_pass http://${ENV_NAME}_nginx;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Start the feature branch environment
cd $ENV_PATH && docker-compose up -d

# Reload main Nginx to pick up the new configuration
docker exec -it wordpress_nginx nginx -s reload

echo "Feature branch environment created at $DOMAIN"
echo "To remove this environment, run:"
echo "  cd $ENV_PATH && docker-compose down -v"
echo "  rm -rf $ENV_PATH"
echo "  rm /opt/wordpress/nginx/conf.d/$DOMAIN.conf"
echo "  docker exec -it wordpress_nginx nginx -s reload"
