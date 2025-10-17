variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "ssh_key_id" {
  description = "ID of your SSH key in DigitalOcean"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to your SSH private key"
  type        = string
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
}

variable "wordpress_db_password" {
  description = "WordPress database password"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Site Domain"
  type        = string
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

