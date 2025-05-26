# Server information
output "server_ip" {
  description = "The public IP address of the WordPress server"
  value       = digitalocean_droplet.wordpress.ipv4_address
}

# URLs for different environments
output "wordpress_url" {
  description = "The URL of the WordPress site"
  value       = "https://${var.domain_name}"
}

output "wordpress_admin" {
  description = "The WordPress admin URL"
  value       = "https://${var.domain_name}/wp-admin/"
}

output "staging_url" {
  description = "The URL of the staging environment"
  value       = "https://staging.${var.domain_name}"
}

# SSH and environment management commands
output "ssh_command" {
  description = "Command to SSH into the server"
  value       = "ssh -i ${var.ssh_private_key_path} root@${digitalocean_droplet.wordpress.ipv4_address}"
}

# Additional outputs needed for post-deploy SSL script
output "domain_name" {
  description = "The primary domain name for the WordPress site"
  value       = var.domain_name
}

output "ssl_email" {
  description = "Email to use for SSL certificate registration"
  value       = var.ssl_email
}
