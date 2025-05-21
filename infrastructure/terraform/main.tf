# Configure the Terraform provider
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# Create a Digital Ocean Project
resource "digitalocean_project" "wordpress" {
  name        = var.project_name
  description = "Resources for the WordPress site at ${var.domain_name}"
  purpose     = "Web Application"
  environment = var.environment
}

# STEP 1: Create the DigitalOcean Droplet
resource "digitalocean_droplet" "wordpress" {
  image    = "ubuntu-24-04-x64"
  name     = "wordpress-${var.environment}"
  region   = var.region
  size     = var.droplet_size
  ssh_keys = [var.ssh_key_id]
  tags     = ["wordpress", var.environment]
  
  # Use a separate connection block for SSH access
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = self.ipv4_address
    timeout     = "2m"
  }

  # Install required packages
  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt update",
      "apt upgrade -y",

      "useradd -m -s /bin/bash automator",
      "mkdir -p /home/automator/.ssh",
      "echo '${var.automator_ssh_public_key}' > /home/automator/.ssh/authorized_keys",
      "chmod 700 /home/automator/.ssh",
      "chmod 600 /home/automator/.ssh/authorized_keys",
      "chown -R automator:automator /home/automator/.ssh",
      "echo 'automator ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/automator",

      "useradd -m -s /bin/bash sysadmin",
      "mkdir -p /home/sysadmin/.ssh",
      "echo '${var.sysadmin_ssh_public_key}' > /home/sysadmin/.ssh/authorized_keys",
      "chmod 700 /home/sysadmin/.ssh",
      "chmod 600 /home/sysadmin/.ssh/authorized_keys",
      "chown -R sysadmin:sysadmin /home/sysadmin/.ssh",
      "echo 'sysadmin ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/sysadmin",
      
      # Install prerequisites
      "apt install -y apt-transport-https ca-certificates curl software-properties-common certbot",
      
      # Add Docker's official GPG key and repository
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null",
      
      # Update package index again and install Docker
      "apt update",
      "apt install -y docker-ce docker-ce-cli containerd.io",
      
      # Install Docker Compose
      "curl -L \"https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-linux-x86_64\" -o /usr/local/bin/docker-compose",
      "chmod +x /usr/local/bin/docker-compose"
    ]
  }
  
  # Create directory structure (one by one to ensure they exist)
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /opt/wordpress",
      "mkdir -p /opt/wordpress/nginx",
      "mkdir -p /opt/wordpress/nginx/conf.d",
      "mkdir -p /opt/wordpress/mysql",
      "mkdir -p /opt/wordpress/wordpress/production",
      "mkdir -p /opt/wordpress/wordpress/staging",
      "mkdir -p /opt/wordpress/ssl",
      "ls -la /opt/wordpress/nginx/conf.d"  # Verify the directory exists
    ]
  }
}

# STEP 2: Create DNS records
resource "digitalocean_domain" "default" {
  name = var.domain_name
}

# Add main A record
resource "digitalocean_record" "main" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.wordpress.ipv4_address
  ttl    = 1800
}

# Add www subdomain
resource "digitalocean_record" "www" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "www"
  value  = "@"
  ttl    = 1800
}

# Add staging subdomain
resource "digitalocean_record" "staging" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "staging"
  value  = digitalocean_droplet.wordpress.ipv4_address
  ttl    = 1800
}

# Add wildcard for feature branches
resource "digitalocean_record" "wildcard" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "*"
  value  = digitalocean_droplet.wordpress.ipv4_address
  ttl    = 1800
}

# STEP 3: Create initial HTTP/HTTPS configuration to get started
resource "null_resource" "initial_http_setup" {
  depends_on = [
    digitalocean_droplet.wordpress,
    digitalocean_record.main,
    digitalocean_record.www,
    digitalocean_record.staging
  ]
  
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = digitalocean_droplet.wordpress.ipv4_address
  }
  
  # Upload Nginx configuration for main site with SSL support
  provisioner "file" {
    content     = <<-EOT
    server {
        listen 80;
        listen [::]:80;
        
        server_name ${var.domain_name} www.${var.domain_name};
        
        # Redirect HTTP to HTTPS
        location / {
            return 301 https://$host$request_uri;
        }
    }

    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        
        server_name ${var.domain_name} www.${var.domain_name};
        
        # SSL configuration
        ssl_certificate /etc/letsencrypt/live/${var.domain_name}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${var.domain_name}/privkey.pem;
        
        # Recommended SSL settings
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_session_cache shared:SSL:10m;
        
        location / {
            proxy_pass http://wordpress_app;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
    EOT
    destination = "/opt/wordpress/nginx/conf.d/default.conf"
  }
  
  # Upload Nginx configuration for staging site with SSL support
  provisioner "file" {
    content     = <<-EOT
    server {
        listen 80;
        listen [::]:80;
        
        server_name staging.${var.domain_name};
        
        # Redirect HTTP to HTTPS
        location / {
            return 301 https://$host$request_uri;
        }
    }

    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        
        server_name staging.${var.domain_name};
        
        # SSL configuration
        ssl_certificate /etc/letsencrypt/live/${var.domain_name}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${var.domain_name}/privkey.pem;
        
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
    EOT
    destination = "/opt/wordpress/nginx/conf.d/staging.conf"
  }
  
  # Upload docker-compose.yml with HTTPS configuration
  provisioner "file" {
    content     = <<-EOT
    version: '3'

    services:
      # Production Database
      db:
        image: mysql:8.0
        container_name: wordpress_db
        restart: always
        environment:
          MYSQL_ROOT_PASSWORD: ${var.mysql_root_password}
          MYSQL_DATABASE: ${var.mysql_database}
          MYSQL_USER: ${var.mysql_user}
          MYSQL_PASSWORD: ${var.mysql_password}
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
          WORDPRESS_DB_NAME: ${var.mysql_database}
          WORDPRESS_DB_USER: ${var.mysql_user}
          WORDPRESS_DB_PASSWORD: ${var.mysql_password}
          WORDPRESS_CONFIG_EXTRA: |
            define('WP_HOME', 'https://${var.domain_name}');
            define('WP_SITEURL', 'https://${var.domain_name}');
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
          MYSQL_ROOT_PASSWORD: ${var.mysql_root_password}
          MYSQL_DATABASE: ${var.mysql_database}_staging
          MYSQL_USER: ${var.mysql_user}
          MYSQL_PASSWORD: ${var.mysql_password}
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
          WORDPRESS_DB_NAME: ${var.mysql_database}_staging
          WORDPRESS_DB_USER: ${var.mysql_user}
          WORDPRESS_DB_PASSWORD: ${var.mysql_password}
          WORDPRESS_CONFIG_EXTRA: |
            define('WP_HOME', 'https://staging.${var.domain_name}');
            define('WP_SITEURL', 'https://staging.${var.domain_name}');
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
    EOT
    destination = "/opt/wordpress/docker-compose.yml"
  }
  
  # Upload environment management script for feature branches (HTTPS version)
  provisioner "file" {
    content     = <<-EOT
    #!/bin/bash

# Check if an argument was provided
if [ $# -eq 0 ]; then
    echo "Error: No feature branch name provided."
    echo "Usage: $0 <feature-branch-name>"
    exit 1
fi

# Get the feature branch name from the first argument
FEATURE_BRANCH="$1"

# Replace slashes and dashes with underscores for all names
FEATURE_NAME=$(echo "$FEATURE_BRANCH" | sed 's|/|__|g' | sed 's|-|_|g')

# Set filename with the requested format: docker-compose.featurebranchname.yml
output_file="docker-compose.$${FEATURE_NAME}.yml"

# Create the Docker Compose file
cat > "$output_file" << EOF
version: '3'

services:
  # Feature Database
  $${FEATURE_NAME}_db:
    image: mysql:8.0
    container_name: $${FEATURE_NAME}_db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${var.mysql_root_password}
      MYSQL_DATABASE: ${var.mysql_database}_$${FEATURE_NAME}
      MYSQL_USER: ${var.mysql_user}
      MYSQL_PASSWORD: ${var.mysql_password}
    volumes:
      - $${FEATURE_NAME}_mysql_data:/var/lib/mysql
    networks:
      - wordpress_network

  # Feature WordPress
  $${FEATURE_NAME}_wordpress:
    image: wordpress:latest
    container_name: $${FEATURE_NAME}_app
    restart: always
    depends_on:
      - $${FEATURE_NAME}_db
    environment:
      WORDPRESS_DB_HOST: $${FEATURE_NAME}_db
      WORDPRESS_DB_NAME: ${var.mysql_database}_$${FEATURE_NAME}
      WORDPRESS_DB_USER: ${var.mysql_user}
      WORDPRESS_DB_PASSWORD: ${var.mysql_password}
      WORDPRESS_CONFIG_EXTRA: |
        define('WP_HOME', 'https://$${FEATURE_NAME}.${var.domain_name}');
        define('WP_SITEURL', 'https://$${FEATURE_NAME}.${var.domain_name}');
    volumes:
      - /opt/wordpress/wordpress/$${FEATURE_NAME}/wp-content/themes:/var/www/html/wp-content/themes
      - /opt/wordpress/wordpress/$${FEATURE_NAME}/wp-content/plugins:/var/www/html/wp-content/plugins
      - $${FEATURE_NAME}_wordpress_data:/var/www/html
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
      - $${FEATURE_NAME}_wordpress_data:/var/www/html/$${FEATURE_NAME}
      - /etc/letsencrypt:/etc/letsencrypt:ro
    depends_on:
      - $${FEATURE_NAME}_wordpress
    networks:
      - wordpress_network

networks:
  wordpress_network:

volumes:
  $${FEATURE_NAME}_mysql_data:
  $${FEATURE_NAME}_wordpress_data:
EOF

echo "Docker Compose file generated as $output_file for feature branch: $FEATURE_BRANCH (sanitized as: $FEATURE_NAME)"
    EOT
    destination = "/opt/wordpress/create-feature-env.sh"
  }
  
  # Create an SSL acquisition script
  provisioner "file" {
    content     = <<-EOT
    #!/bin/bash
    # Script to obtain SSL certificates using certbot

    # Stop nginx to free up port 80
    cd /opt/wordpress && docker-compose stop nginx

    # Get SSL certificates
    certbot certonly --standalone -d ${var.domain_name} -d www.${var.domain_name} -d staging.${var.domain_name} --email ${var.ssl_email} --agree-tos --non-interactive

    # Restart services
    cd /opt/wordpress && docker-compose up -d

    # Set up automatic renewal
    echo "0 0 * * * root certbot renew --quiet --post-hook 'docker exec wordpress_nginx nginx -s reload'" > /etc/cron.d/certbot-renew
    chmod 644 /etc/cron.d/certbot-renew
    EOT
    destination = "/opt/wordpress/get-ssl.sh"
  }
  
  # Start containers and get SSL certificates
  provisioner "remote-exec" {
    inline = [
      "chmod +x /opt/wordpress/create-feature-env.sh",
      "chmod +x /opt/wordpress/get-ssl.sh",
      "cd /opt/wordpress && docker-compose up -d",
      "sleep 60", # Wait for services to start
      "bash /opt/wordpress/get-ssl.sh" # Run the SSL script
    ]
  }
}

# STEP 4: Run post-deploy script for any additional setup
resource "null_resource" "post_deploy_trigger" {
  depends_on = [
    digitalocean_droplet.wordpress,
    digitalocean_domain.default,
    digitalocean_record.main,
    digitalocean_record.www,
    digitalocean_record.staging,
    digitalocean_record.wildcard,
    null_resource.initial_http_setup,
    digitalocean_project_resources.wordpress
  ]

  # This triggers the resource to be recreated when any of these values change
  triggers = {
    server_ip = digitalocean_droplet.wordpress.ipv4_address
    domain_name = var.domain_name
    always_run = "${timestamp()}"  # Makes sure this runs on every apply
  }

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = digitalocean_droplet.wordpress.ipv4_address
  }

  # Ensure everything is properly configured after setup
  provisioner "remote-exec" {
    inline = [
      "docker exec wordpress_nginx nginx -t",
      "docker exec wordpress_nginx nginx -s reload",
      "echo 'WordPress setup complete with SSL enabled at https://${var.domain_name} and https://staging.${var.domain_name}'"
    ]
  }
}

# Assign resources to the project
resource "digitalocean_project_resources" "wordpress" {
  project = digitalocean_project.wordpress.id
  resources = [
    digitalocean_droplet.wordpress.urn,
    digitalocean_domain.default.urn
  ]
}
