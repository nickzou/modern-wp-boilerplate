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
  description = "Path to your SSH private key file"
  type        = string
}

variable "domain_name" {
  description = "Domain name for WordPress site"
  type        = string
  default     = "pandacalculus.com"
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
  default     = "s-1vcpu-2gb"  # 1 vCPU, 2GB RAM
}

variable "your_ip_address" {
  description = "Your IP address for SSH access restrictions"
  type        = string
  default     = "0.0.0.0/0"  # Default allows all, but you should restrict this
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
