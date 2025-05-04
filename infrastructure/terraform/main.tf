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

# Create a DigitalOcean Droplet for WordPress
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

  # Install Docker and Docker Compose
  provisioner "remote-exec" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update",
      "apt-get upgrade -y",
      
      # Install required packages
      "apt-get install -y apt-transport-https ca-certificates curl software-properties-common",
      
      # Add Docker's official GPG key
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
      
      # Set up the Docker repository
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null",
      
      # Install Docker Engine
      "apt-get update",
      "apt-get install -y docker-ce docker-ce-cli containerd.io",
      
      # Install Docker Compose
      "curl -L \"https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-linux-x86_64\" -o /usr/local/bin/docker-compose",
      "chmod +x /usr/local/bin/docker-compose"
    ]
  }
  
  # Create WordPress directory structure
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /opt/wordpress/{nginx,mysql,wordpress}",
      "mkdir -p /opt/wordpress/nginx/conf.d"
    ]
  }
  
  # Upload Nginx configuration
  provisioner "file" {
    content     = templatefile("${path.module}/templates/nginx.conf.tpl", {
      domain_name = var.domain_name
    })
    destination = "/opt/wordpress/nginx/conf.d/default.conf"
  }
  
  # Upload docker-compose.yml
  provisioner "file" {
    content     = templatefile("${path.module}/templates/docker-compose.yml.tpl", {
      domain_name      = var.domain_name,
      mysql_root_password = var.mysql_root_password,
      mysql_database   = var.mysql_database,
      mysql_user       = var.mysql_user,
      mysql_password   = var.mysql_password
    })
    destination = "/opt/wordpress/docker-compose.yml"
  }
  
  # Upload environment management scripts
  provisioner "file" {
    content     = templatefile("${path.module}/templates/create-env.sh.tpl", {
      domain_name      = var.domain_name,
      mysql_root_password = var.mysql_root_password,
      mysql_database   = var.mysql_database,
      mysql_user       = var.mysql_user,
      mysql_password   = var.mysql_password,
      ENV_NAME         = "$${ENV_NAME}"
    })
    destination = "/opt/wordpress/create-env.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /opt/wordpress/create-env.sh",
      "cd /opt/wordpress && docker-compose up -d"
    ]
  }
}

# Create a new domain
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

# Assign resources to the project
resource "digitalocean_project_resources" "wordpress" {
  project = digitalocean_project.wordpress.id
  resources = [
    digitalocean_droplet.wordpress.urn,
    digitalocean_domain.default.urn
  ]
}
