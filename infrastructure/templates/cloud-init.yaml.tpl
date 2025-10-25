#cloud-config
packages:
  - nginx
  - git
  - mysql-server
  - php-fpm
  - php-mysql
  - php-curl
  - php-gd
  - php-mbstring
  - php-xml
  - php-xmlrpc
  - php-soap
  - php-intl
  - php-zip
  - zsh
  - zsh-syntax-highlighting
  - certbot
  - python3-certbot-nginx
  - fail2ban
  
write_files:
  - path: /etc/nginx/conf.d/cache.conf
    encoding: b64
    content: ${cache_conf}

  - path: /etc/nginx/sites-available/production
    encoding: b64
    content: ${production_nginx_conf}

  - path: /etc/nginx/sites-available/staging
    encoding: b64
    content: ${staging_nginx_conf}

  - path: /etc/nginx/sites-available/dev
    encoding: b64
    content: ${dev_nginx_conf}

  - path: /root/.env
    encoding: b64
    content: ${env}
    permissions: '0600'

  - path: /root/scripts/deploy-preview.sh
    encoding: b64
    content: ${deploy_preview_script}
    permissions: '0755'

  - path: /root/scripts/cleanup-preview.sh
    encoding: b64
    content: ${cleanup_preview_script}
    permissions: '0755'

  - path: /root/templates/preview-nginx.conf.tpl
    encoding: b64
    content: ${preview_nginx_template}

runcmd:
  - git clone https://github.com/nickzou/server-dotfiles.git /tmp/dotfiles
  - cp /tmp/dotfiles/dotfiles/.zshrc /root/.zshrc
  - cp /tmp/dotfiles/dotfiles/.zsh_aliases /root/.zsh_aliases
  - cp /tmp/dotfiles/dotfiles/.vimrc /root/.vimrc
  - rm -rf /tmp/dotfiles
  - chsh -s $(which zsh) root

  # Install WP-CLI
  - curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  - chmod +x wp-cli.phar
  - mv wp-cli.phar /usr/local/bin/wp

  # Create cache directory
  - mkdir -p /var/cache/nginx
  - chown -R www-data:www-data /var/cache/nginx

  # Create directories for preview deployments
  - mkdir -p /root/scripts
  - mkdir -p /root/templates
  - mkdir -p /root/previews

  # Set root password
  - mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${mysql_root_password}';"
  - mysql -e "FLUSH PRIVILEGES;"
  - sleep 2
  
  # NOW use auth for ALL remaining commands
  - mysql -uroot -p'${mysql_root_password}' -e "DELETE FROM mysql.user WHERE User='';"
  - mysql -uroot -p'${mysql_root_password}' -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
  - mysql -uroot -p'${mysql_root_password}' -e "DROP DATABASE IF EXISTS test;"
  - mysql -uroot -p'${mysql_root_password}' -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
  - mysql -uroot -p'${mysql_root_password}' -e "FLUSH PRIVILEGES;"
  
  # Create Production WordPress database and user
  - mysql -uroot -p'${mysql_root_password}' -e "CREATE DATABASE wordpress_prod DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  - mysql -uroot -p'${mysql_root_password}' -e "CREATE USER 'wp_prod'@'localhost' IDENTIFIED BY '${wordpress_prod_password}';"
  - mysql -uroot -p'${mysql_root_password}' -e "GRANT ALL ON wordpress_prod.* TO 'wp_prod'@'localhost';"

  # Create Staging WordPress database and user
  - mysql -uroot -p'${mysql_root_password}' -e "CREATE DATABASE wordpress_staging DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  - mysql -uroot -p'${mysql_root_password}' -e "CREATE USER 'wp_staging'@'localhost' IDENTIFIED BY '${wordpress_staging_password}';"
  - mysql -uroot -p'${mysql_root_password}' -e "GRANT ALL ON wordpress_staging.* TO 'wp_staging'@'localhost';"

  - mysql -uroot -p'${mysql_root_password}' -e "CREATE DATABASE wordpress_dev DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  - mysql -uroot -p'${mysql_root_password}' -e "CREATE USER 'wp_dev'@'localhost' IDENTIFIED BY '${wordpress_dev_password}';"
  - mysql -uroot -p'${mysql_root_password}' -e "GRANT ALL ON wordpress_dev.* TO 'wp_dev'@'localhost';"

  - mysql -uroot -p'${mysql_root_password}' -e "FLUSH PRIVILEGES;"

  # Install WordPress - Production
  - cd /tmp && curl -O https://wordpress.org/latest.tar.gz
  - tar xzvf /tmp/latest.tar.gz -C /tmp
  - mkdir -p /var/www/production
  - cp -a /tmp/wordpress/. /var/www/production/
  - chown -R www-data:www-data /var/www/production
  - rm -rf /tmp/wordpress /tmp/latest.tar.gz

  # Install WordPress - Staging
  - cd /tmp && curl -O https://wordpress.org/latest.tar.gz
  - tar xzvf /tmp/latest.tar.gz -C /tmp
  - mkdir -p /var/www/staging
  - cp -a /tmp/wordpress/. /var/www/staging/
  - chown -R www-data:www-data /var/www/staging
  - rm -rf /tmp/wordpress /tmp/latest.tar.gz

  # Install WordPress - Dev
  - cd /tmp && curl -O https://wordpress.org/latest.tar.gz
  - tar xzvf /tmp/latest.tar.gz -C /tmp
  - mkdir -p /var/www/dev
  - cp -a /tmp/wordpress/. /var/www/dev/
  - chown -R www-data:www-data /var/www/dev
  - rm -rf /tmp/wordpress /tmp/latest.tar.gz

  # Enable all sites
  - ln -s /etc/nginx/sites-available/production /etc/nginx/sites-enabled/
  - ln -s /etc/nginx/sites-available/staging /etc/nginx/sites-enabled/
  - ln -s /etc/nginx/sites-available/dev /etc/nginx/sites-enabled/
  - rm -f /etc/nginx/sites-enabled/default
  - nginx -t && systemctl reload nginx

  # Set up SSL
  - certbot --nginx -d ${domain_name} -d www.${domain_name} -d staging.${domain_name} -d dev.${domain_name} --non-interactive --agree-tos --email ${ssl_email} --redirect --staging

  - ufw default deny incoming
  - ufw default allow outgoing
  - ufw allow ssh
  - ufw allow 'Nginx Full'
  - ufw --force enable

  - systemctl enable fail2ban
  - systemctl start fail2ban
