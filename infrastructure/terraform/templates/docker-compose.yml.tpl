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

  nginx:
    image: nginx:latest
    container_name: wordpress_nginx
    restart: always
    ports:
      - "80:80"
      - "443:443"
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
