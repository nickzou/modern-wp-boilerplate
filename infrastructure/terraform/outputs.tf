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

output "create_environment_command" {
  description = "Command to create a new feature branch environment"
  value       = "ssh -i ${var.ssh_private_key_path} root@${digitalocean_droplet.wordpress.ipv4_address} '/opt/wordpress/create-env.sh feature-branch-name'"
}

# Additional outputs needed for post-deploy SSL script
output "domain_name" {
  description = "The primary domain name for the WordPress site"
  value       = var.domain_name
}

output "ssh_private_key_path" {
  description = "Path to the SSH private key file"
  value       = var.ssh_private_key_path
  sensitive   = true
}

output "ssl_email" {
  description = "Email to use for SSL certificate registration"
  value       = var.ssl_email
}

# Post-deploy SSL script command
# output "ssl_setup_command" {
#   description = "Command to manually run the SSL setup script"
#   value       = "./post-deploy-ssl.sh ${digitalocean_droplet.wordpress.ipv4_address} ${var.domain_name} ${var.ssh_private_key_path} ${var.ssl_email}"
# }
