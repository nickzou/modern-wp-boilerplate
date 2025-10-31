terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    htpasswd = {
      source  = "loafoe/htpasswd"
      version = "~> 1.5"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "cloudflare" {
  api_token = var.cf_token
}

resource "htpasswd_password" "monitoring" {
  password = var.monitoring_password
}

resource "digitalocean_droplet" "basic" {
  image  = "ubuntu-24-04-x64"
  name   = var.project_name
  region = var.region
  size   = var.droplet_size
  ssh_keys = [var.ssh_key_id]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = self.ipv4_address
    timeout     = "2m"
  }

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    cache_conf                 = base64encode(file("${path.module}/cache.conf")),
    production_nginx_conf      = base64encode(file("${path.module}/production-nginx.conf")),
    staging_nginx_conf         = base64encode(file("${path.module}/staging-nginx.conf")),
    dev_nginx_conf             = base64encode(file("${path.module}/dev-nginx.conf")),
    monitoring_nginx_conf      = base64encode(templatefile("${path.module}/monitoring-nginx.conf.tpl", {
      domain_name = var.domain_name
    })),
    monitoring_htpasswd        = "admin:${htpasswd_password.monitoring.apr1}",
    fail2ban_config            = base64encode(file("${path.module}/fail2ban-jail.local")),
    deploy_preview_script      = base64encode(file("${path.module}/scripts/deploy-preview.sh")),
    cleanup_preview_script     = base64encode(file("${path.module}/scripts/cleanup-preview.sh")),
    create_backup_script       = base64encode(file("${path.module}/scripts/create-backup.sh")),
    env                        = base64encode(file("${path.module}/templates/.env.tpl")),
    preview_nginx_template     = base64encode(file("${path.module}/templates/preview-nginx.conf.tpl")),
    domain_name                = var.domain_name,
    mysql_root_password        = var.mysql_root_password,
    wordpress_prod_password    = var.wordpress_prod_password,
    wordpress_staging_password = var.wordpress_staging_password,
    wordpress_dev_password     = var.wordpress_dev_password,
    ssl_email                  = var.ssl_email,
    wp_default_username        = var.wp_default_username,
    wp_default_user_email      = var.wp_default_user_email,
    wp_default_user_password   = var.wp_default_user_password
    cf_token                   = var.cf_token
  })
}

# Root domain
resource "cloudflare_record" "root" {
  zone_id = var.cf_zone_id
  name    = "@"
  content = digitalocean_droplet.basic.ipv4_address
  type    = "A"
  proxied = true
}

# www subdomain
resource "cloudflare_record" "www" {
  zone_id = var.cf_zone_id
  name    = "www"
  content = digitalocean_droplet.basic.ipv4_address
  type    = "A"
  proxied = true
}

# Staging subdomain
resource "cloudflare_record" "staging" {
  zone_id = var.cf_zone_id
  name    = "staging"
  content = digitalocean_droplet.basic.ipv4_address
  type    = "A"
  proxied = true
}

# Dev subdomain
resource "cloudflare_record" "dev" {
  zone_id = var.cf_zone_id
  name    = "dev"
  content = digitalocean_droplet.basic.ipv4_address
  type    = "A"
  proxied = true
}

# Monitoring subdomain
resource "cloudflare_record" "monitoring" {
  zone_id = var.cf_zone_id
  name    = "monitoring"
  content = digitalocean_droplet.basic.ipv4_address
  type    = "A"
  proxied = true
}

output "droplet_ip" {
  value       = digitalocean_droplet.basic.ipv4_address
  description = "The public IP address of the droplet"
}

output "droplet_id" {
  value       = digitalocean_droplet.basic.id
  description = "The ID of the droplet"
}
