terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_droplet" "basic" {
  image  = "ubuntu-24-04-x64"
  name   = "terraform-wordpress"
  region = "nyc3"
  size   = "s-1vcpu-1gb-35gb-intel"
  ssh_keys = [var.ssh_key_id]

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = self.ipv4_address
    timeout     = "2m"
  }

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    cache_conf                = base64encode(file("${path.module}/cache.conf")),
    production_nginx_conf     = base64encode(file("${path.module}/production-nginx.conf")),
    staging_nginx_conf        = base64encode(file("${path.module}/staging-nginx.conf")),
    dev_nginx_conf            = base64encode(file("${path.module}/dev-nginx.conf")),
    mysql_root_password       = var.mysql_root_password,
    wordpress_prod_password   = var.wordpress_prod_password,
    wordpress_staging_password = var.wordpress_staging_password,
    wordpress_dev_password    = var.wordpress_dev_password
  })
}

resource "digitalocean_domain" "wordpress" {
  name = var.domain_name
}

resource "digitalocean_record" "root" {
  domain = digitalocean_domain.wordpress.id
  type   = "A"
  name   = "@"
  value  = digitalocean_droplet.basic.ipv4_address
}

resource "digitalocean_record" "www" {
  domain = digitalocean_domain.wordpress.id
  type   = "A"
  name   = "www"
  value  = digitalocean_droplet.basic.ipv4_address
}

resource "digitalocean_record" "staging" {
  domain = digitalocean_domain.wordpress.id
  type   = "A"
  name   = "staging"
  value  = digitalocean_droplet.basic.ipv4_address
}

resource "digitalocean_record" "dev" {
  domain = digitalocean_domain.wordpress.id
  type   = "A"
  name   = "dev"
  value  = digitalocean_droplet.basic.ipv4_address
}

output "droplet_ip" {
  value       = digitalocean_droplet.basic.ipv4_address
  description = "The public IP address of the droplet"
}

output "droplet_id" {
  value       = digitalocean_droplet.basic.id
  description = "The ID of the droplet"
}
