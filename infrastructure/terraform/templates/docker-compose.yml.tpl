version: '3'

services:
  db:
    image: mysql:8.0
    container_name: wordpress_db
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
    container_name: wordpress_app
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

  staging_db:
    image: mysql:8.0
    container_name: staging_db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${mysql_root_password}
      MYSQL_DATABASE: ${mysql_database}_staging
      MYSQL_USER: ${mysql_user}
      MYSQL_PASSWORD: ${mysql_password}
    volumes:
      - staging_mysql_data:/var/lib/mysql
    networks:
      - wordpress_network

  # Staging WordPress
  staging_wordpress:
    image: wordpress:latest
    container_name: staging_app
    restart: always
    depends_on:
      - staging_db
    environment:
      WORDPRESS_DB_HOST: staging_db
      WORDPRESS_DB_NAME: ${mysql_database}_staging
      WORDPRESS_DB_USER: ${mysql_user}
      WORDPRESS_DB_PASSWORD: ${mysql_password}
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_HOME', 'http://staging.${domain_name}');
        define('WP_SITEURL', 'http://staging.${domain_name}');
    volumes:
      - staging_wordpress_data:/var/www/html
    networks:
      - wordpress_network

  nginx:
    image: nginx:latest
    container_name: wordpress_nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - wordpress_data:/var/www/html/production
      - wordpress_data:/var/www/html/staging
    depends_on:
      - wordpress
      - staging_wordpress
    networks:
      - wordpress_network

networks:
  wordpress_network:

volumes:
  mysql_data:
  wordpress_data:
  staging_mysql_data:
  staging_wordpress_data:
