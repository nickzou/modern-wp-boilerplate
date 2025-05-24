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
#  - |
#    cat > /opt/wordpress/nginx/conf.d/default.conf <<-DEFAULT_CONF_EOF
#    ${default_conf} 
#   DEFAULT_CONF_EOF
# - chmod 644 /opt/wordpress/nginx/conf.d/default.conf
# - |
#   cat > /opt/wordpress/nginx/conf.d/staging.conf <<-STAGING_CONF_EOF
#   ${staging_conf} 
#   STAGING_CONF_EOF
# - chmod 644 /opt/wordpress/nginx/conf.d/staging.conf
