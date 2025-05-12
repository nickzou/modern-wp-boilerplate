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
  name        = "WordPress Infrastructure"
  description = "Resources for the WordPress site at ${var.domain_name}"
  purpose     = "Web Application"
  environment = var.environment
}

# STEP 1: Create the DigitalOcean Droplet
resource "digitalocean_droplet" "wordpress" {
  image    = "ubuntu-22-04-x64"
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
      "apt-get update",
      "apt-get upgrade -y",
      
      # Install prerequisites
      "apt-get install -y apt-transport-https ca-certificates curl software-properties-common certbot",
      
      # Add Docker's official GPG key and repository
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null",
      
      # Update package index again and install Docker
      "apt-get update",
      "apt-get install -y docker-ce docker-ce-cli containerd.io",
      
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
      "mkdir -p /opt/wordpress/wordpress",
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
}

# Add www subdomain
resource "digitalocean_record" "www" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "www"
  value  = "@"
}

# Add staging subdomain
resource "digitalocean_record" "staging" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "staging"
  value  = digitalocean_droplet.wordpress.ipv4_address
}

# Add wildcard for feature branches
resource "digitalocean_record" "wildcard" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "*"
  value  = digitalocean_droplet.wordpress.ipv4_address
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
          - wordpress_data:/var/www/html
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
          - staging_wordpress_data:/var/www/html
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
    # Script to create feature branch environments for WordPress (with HTTPS)

    # Check if argument is provided
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <environment-name>"
        exit 1
    fi

    # Use bash variables
    ENV_NAME=$1
    ENV_PATH="/opt/wordpress-$ENV_NAME"
    DOMAIN="$ENV_NAME.${var.domain_name}"

    # Create directory structure
    mkdir -p $ENV_PATH/{nginx/conf.d,mysql,wordpress}

    # Create docker-compose.yml
    cat > $ENV_PATH/docker-compose.yml << EOF
    version: '3'

    services:
      db:
        image: mysql:8.0
        container_name: $${ENV_NAME}_db
        restart: always
        environment:
          MYSQL_ROOT_PASSWORD: ${var.mysql_root_password}
          MYSQL_DATABASE: ${var.mysql_database}_$${ENV_NAME}
          MYSQL_USER: ${var.mysql_user}
          MYSQL_PASSWORD: ${var.mysql_password}
        volumes:
          - mysql_data:/var/lib/mysql
        networks:
          - wordpress_network

      wordpress:
        image: wordpress:latest
        container_name: $${ENV_NAME}_app
        restart: always
        depends_on:
          - db
        environment:
          WORDPRESS_DB_HOST: db
          WORDPRESS_DB_NAME: ${var.mysql_database}_$${ENV_NAME}
          WORDPRESS_DB_USER: ${var.mysql_user}
          WORDPRESS_DB_PASSWORD: ${var.mysql_password}
          WORDPRESS_CONFIG_EXTRA: |
            define('WP_HOME', 'https://$${DOMAIN}');
            define('WP_SITEURL', 'https://$${DOMAIN}');
        volumes:
          - wordpress_data:/var/www/html
        networks:
          - wordpress_network

      nginx:
        image: nginx:latest
        container_name: $${ENV_NAME}_nginx
        restart: always
        expose:
          - 80
        volumes:
          - ./nginx/conf.d:/etc/nginx/conf.d
          - wordpress_data:/var/www/html
          - /etc/letsencrypt:/etc/letsencrypt:ro
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

    # Create Nginx configuration for the feature branch
    cat > $ENV_PATH/nginx/conf.d/default.conf << EOF
    server {
        listen 80;
        server_name $${DOMAIN};
        
        # Redirect HTTP to HTTPS
        location / {
            return 301 https://\$host\$request_uri;
        }
    }

    server {
        listen 443 ssl;
        server_name $${DOMAIN};
        
        # SSL configuration
        ssl_certificate /etc/letsencrypt/live/${var.domain_name}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${var.domain_name}/privkey.pem;
        
        # Recommended SSL settings
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_session_cache shared:SSL:10m;
        
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
    cat > /opt/wordpress/nginx/conf.d/$${DOMAIN}.conf << EOF
    server {
        listen 80;
        listen [::]:80;
        server_name $${DOMAIN};
        
        # Redirect HTTP to HTTPS
        location / {
            return 301 https://\$host\$request_uri;
        }
    }

    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        server_name $${DOMAIN};
        
        # SSL configuration
        ssl_certificate /etc/letsencrypt/live/${var.domain_name}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${var.domain_name}/privkey.pem;
        
        # Recommended SSL settings
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_session_cache shared:SSL:10m;
        
        location / {
            proxy_pass http://$${ENV_NAME}_app;
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

    echo "Feature branch environment created at https://$DOMAIN"
    echo "To remove this environment, run:"
    echo "  cd $ENV_PATH && docker-compose down -v"
    echo "  rm -rf $ENV_PATH"
    echo "  rm /opt/wordpress/nginx/conf.d/$DOMAIN.conf"
    echo "  docker exec -it wordpress_nginx nginx -s reload"
    EOT
    destination = "/opt/wordpress/create-env.sh"
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
      "chmod +x /opt/wordpress/create-env.sh",
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
