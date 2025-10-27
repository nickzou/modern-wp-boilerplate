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
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "cloudflare" {
  api_token = var.cf_token
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

  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tpl", {
    cache_conf                  = base64encode(file("${path.module}/cache.conf")),
    production_nginx_conf       = base64encode(file("${path.module}/production-nginx.conf")),
    staging_nginx_conf          = base64encode(file("${path.module}/staging-nginx.conf")),
    dev_nginx_conf              = base64encode(file("${path.module}/dev-nginx.conf")),
    fail2ban_config             = base64encode(file("${path.module}/fail2ban-jail.local")),
    deploy_preview_script       = base64encode(file("${path.module}/scripts/deploy-preview.sh")),
    cleanup_preview_script      = base64encode(file("${path.module}/scripts/cleanup-preview.sh")),
    env                         = base64encode(file("${path.module}/templates/.env.tpl")),
    preview_nginx_template      = base64encode(file("${path.module}/templates/preview-nginx.conf.tpl")),
    preview_wildcard_nginx_conf = base64encode(file("${path.module}/nginx-configs/preview-wildcard.conf")),
    cf_token                    = var.cf_token,
    domain_name                 = var.domain_name,
    mysql_root_password         = var.mysql_root_password,
    wordpress_prod_password     = var.wordpress_prod_password,
    wordpress_staging_password  = var.wordpress_staging_password,
    wordpress_dev_password      = var.wordpress_dev_password,
    ssl_email                   = var.ssl_email
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

output "droplet_ip" {
  value       = digitalocean_droplet.basic.ipv4_address
  description = "The public IP address of the droplet"
}

output "droplet_id" {
  value       = digitalocean_droplet.basic.id
  description = "The ID of the droplet"
}
