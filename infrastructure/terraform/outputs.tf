# Output the server IP address
output "server_ip" {
  description = "The public IP address of the WordPress server"
  value       = digitalocean_droplet.wordpress.ipv4_address
}

# Output the WordPress URL
output "wordpress_url" {
  description = "The URL of the WordPress site"
  value       = "http://${var.domain_name}"
}

# Output WordPress admin URL
output "wordpress_admin" {
  description = "The WordPress admin URL"
  value       = "http://${var.domain_name}/wp-admin/"
}

# Output SSH connection command
output "ssh_command" {
  description = "Command to SSH into the server"
  value       = "ssh -i ${var.ssh_private_key_path} root@${digitalocean_droplet.wordpress.ipv4_address}"
}

# Output MySQL connection info
output "mysql_connection" {
  description = "Local MySQL connection details"
  value       = "Database: wordpress, User: wordpress, Password: wordpress"
  sensitive   = true
}

# Output server status check command
output "status_check" {
  description = "Command to check Nginx and PHP-FPM status"
  value       = "ssh -i ${var.ssh_private_key_path} root@${digitalocean_droplet.wordpress.ipv4_address} 'systemctl status nginx php8.1-fpm'"
}
