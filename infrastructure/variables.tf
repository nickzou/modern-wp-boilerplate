variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "cf_token" {
  description = "CloudFlare API Token"
  type        = string
  sensitive   = true
}

variable "cf_zone_id" {
  description = "CloudFlare Zone ID"
  type        = string
}

variable "ssh_key_id" {
  description = "ID of your SSH key in DigitalOcean"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to your SSH private key"
  type        = string
}

variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "region" {
  description = "VPS Region"
  type        = string
}

variable "droplet_size" {
  description = "VPS Type"
  type        = string
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
}

variable "wordpress_prod_password" {
  description = "WordPress production database password"
  type        = string
  sensitive   = true
}

variable "wordpress_staging_password" {
  description = "WordPress staging database password"
  type        = string
  sensitive   = true
}

variable "wordpress_dev_password" {
  description = "WordPress dev database password"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Site Domain"
  type        = string
}

variable "ssl_email" {
  description = "SSL Email"
  type        = string
}

variable "wp_default_username" {
  description = "WordPress Admin Username"
  type        = string
}

variable "wp_default_user_email" {
  description = "WordPress Admin Email"
  type        = string
}

variable "wp_default_user_password" {
  description = "WordPress Admin Password"
  type        = string
}
