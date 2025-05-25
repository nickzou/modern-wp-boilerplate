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

variable "automator_ssh_public_key_path" {
  description = "Path to your automator user SSH public key"
  type        = string
}

variable "sysadmin_ssh_public_key_path" {
  description = "Path to your SSH public key"
  type        = string
}

variable "project_name" {
  description = "Project name for WordPress site"
  type        = string
}

variable "domain_name" {
  description = "Domain name for WordPress site"
  type        = string
}

variable "environment" {
  description = "Environment name (prod, staging, etc.)"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc1"
}

variable "droplet_size" {
  description = "Size of the DigitalOcean droplet"
  type        = string
  default     = "s-1vcpu-2gb"
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
}

variable "mysql_database" {
  description = "MySQL database name"
  type        = string
  default     = "wordpress"
}

variable "mysql_user" {
  description = "MySQL user"
  type        = string
  default     = "wordpress"
}

variable "mysql_password" {
  description = "MySQL password"
  type        = string
  sensitive   = true
}

variable "ssl_email" {
  description = "Email address for Let's Encrypt SSL certificates"
  type        = string
}
