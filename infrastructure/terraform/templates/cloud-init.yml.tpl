#cloud-config
package_update: true
package_upgrade: true
packages:
  - zsh
  - git
  - stow 
  - lsd
  - bat
  - zoxide
  - fzf
  - btop
  - neovim
  - curl
  - build-essential
  - certbot
  - ca-certificates
  - software-properties-common
users:
  - name: automator
    gecos: "automator"
    shell: /usr/bin/zsh
    groups: sudo, users
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ${automator_ssh_public_key}
  - name: sysadmin
    gecos: "system admin user"
    shell: /usr/bin/zsh
    groups: sudo, users
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ${sysadmin_ssh_public_key}
runcmd:
  - su - sysadmin -c "git clone https://github.com/nickzou/server-dotfiles.git ~/dotfiles"
  - mkdir -p /home/sysadmin/sh
  - |
    cat > /home/sysadmin/sh/setup-dotfiles.sh << 'SCRIPT_EOF'
    #!/bin/bash
    set -e
    
    DOTFILES_DIR="/home/sysadmin/dotfiles"
    cd "$DOTFILES_DIR"

    STOW_FOLDERS=(
      "zsh"
      "bat"
      "nvim"
    )
    
    for folder in "$${STOW_FOLDERS[@]}"; do
      if [ -d "$folder" ]; then
        echo "Stowing $folder..."
        stow --target="$HOME" "$folder"
      fi
    done

    echo "Dotfiles setup complete!"
    SCRIPT_EOF
  - chmod +x /home/sysadmin/sh/setup-dotfiles.sh
  - chown -R sysadmin:sysadmin /home/sysadmin
  - sudo -u sysadmin /home/sysadmin/sh/setup-dotfiles.sh
  - mkdir -p /opt/wordpress
  - mkdir -p /opt/wordpress/nginx
  - mkdir -p /opt/wordpress/nginx/conf.d
  - mkdir -p /opt/wordpress/mysql
  - mkdir -p /opt/wordpress/wordpress/production
  - mkdir -p /opt/wordpress/wordpress/staging
  - mkdir -p /opt/wordpress/ssl
  - ls -la /opt/wordpress/nginx/conf.d  # Verify the directory exist
  - install -m 0755 -d /etc/apt/keyrings
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  - chmod a+r /etc/apt/keyrings/docker.asc
  - |
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  - systemctl enable docker
  - systemctl start docker
  - usermod -aG docker automator
  - usermod -aG docker sysadmin
  - curl -L \"https://github.com/docker/compose/releases/download/v2.36.2/docker-compose-linux-x86_64\" -o /usr/local/bin/docker-compose
  - chmod +x /usr/local/bin/docker-compose
  - |
    cat > /opt/wordpress/nginx/conf.d/default.conf <<-DEFAULT_CONFIG_EOF
     server {
         listen 80;
         listen [::]:80;

         server_name ${domain_name} www.${domain_name};

         # Redirect HTTP to HTTPS
         location / {
             return 301 https://\$host\$request_uri;
         }
     }

     server {
         listen 443 ssl;
         listen [::]:443 ssl;

         server_name ${domain_name} www.${domain_name};

         # SSL configuration
         ssl_certificate /etc/letsencrypt/live/${domain_name}/fullchain.pem;
         ssl_certificate_key /etc/letsencrypt/live/${domain_name}/privkey.pem;

         # Recommended SSL settings
         ssl_protocols TLSv1.2 TLSv1.3;
         ssl_prefer_server_ciphers on;
         ssl_ciphers HIGH:!aNULL:!MD5;
         ssl_session_cache shared:SSL:10m;

         location / {
             proxy_pass http://wordpress_app;
             proxy_set_header Host \$host;
             proxy_set_header X-Real-IP \$remote_addr;
             proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
             proxy_set_header X-Forwarded-Proto \$scheme;
         }
     }
    DEFAULT_CONFIG_EOF
  - chmod +x /opt/wordpress/nginx/default.conf
  - |
    cat > /opt/wordpress/nginx/conf.d/staging.conf <<-STAGING_CONFIG_EOF
    server {
        listen 80;
        listen [::]:80;

        server_name staging.${domain_name};

        # Redirect HTTP to HTTPS
        location / {
            return 301 https://$host$request_uri;
        }
    }

    server {
        listen 443 ssl;
        listen [::]:443 ssl;

        server_name staging.${domain_name};

        # SSL configuration
        ssl_certificate /etc/letsencrypt/live/${domain_name}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${domain_name}/privkey.pem;

        # Recommended SSL settings
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_session_cache shared:SSL:10m;

        location / {
            proxy_pass http://staging_app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    STAGING_CONFIG_EOF
  - |
    cat > /opt/wordpress/docker-compose.yml <<-DOCKER_COMPOSE_EOF
    version: '3'

    services:
      # Production Database
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

      # Production WordPress
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
          WORDPRESS_CONFIG_EXTRA: |
            define('WP_HOME', 'https://${domain_name}');
            define('WP_SITEURL', 'https://${domain_name}');
        volumes:
          - /opt/wordpress/wordpress/production/wp-content/themes:/var/www/html/wp-content/themes
          - /opt/wordpress/wordpress/production/wp-content/plugins:/var/www/html/wp-content/plugins
        networks:
          - wordpress_network

      # Staging Database
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
            define('WP_HOME', 'https://staging.${domain_name}');
            define('WP_SITEURL', 'https://staging.${domain_name}');
        volumes:
          - /opt/wordpress/wordpress/staging/wp-content/themes:/var/www/html/wp-content/themes
          - /opt/wordpress/wordpress/staging/wp-content/plugins:/var/www/html/wp-content/themes/plugins
        networks:
          - wordpress_network

      # Nginx Reverse Proxy
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
          - staging_wordpress_data:/var/www/html/staging
          - /etc/letsencrypt:/etc/letsencrypt:ro
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
    DOCKER_COMPOSE_EOF
  - |
    cat > /opt/wordpress/get-ssl.sh <<-GET_SSL_EOF
     #!/bin/bash
     # Script to obtain SSL certificates using certbot

     # Stop nginx to free up port 80
     cd /opt/wordpress && docker-compose stop nginx

     # Get SSL certificates
     certbot certonly --standalone -d ${domain_name} -d www.${domain_name} -d staging.${domain_name} --email ${ssl_email} --agree-tos --non-interactive

     # Restart services
     cd /opt/wordpress && docker-compose up -d

     # Set up automatic renewal
     echo "0 0 * * * root certbot renew --quiet --post-hook 'docker exec wordpress_nginx nginx -s reload'" > /etc/cron.d/certbot-renew
     chmod 644 /etc/cron.d/certbot-renew
     GET_SSL_EOF
  - chmod +x /opt/wordpress/get-ssl.sh
  - cd /opt/wordpress && docker-compose up -d
  - sleep 120
  - bash /opt/wordpress/get-ssl.sh
