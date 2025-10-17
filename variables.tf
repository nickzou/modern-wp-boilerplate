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
