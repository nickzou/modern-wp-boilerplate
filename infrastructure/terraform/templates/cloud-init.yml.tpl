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
