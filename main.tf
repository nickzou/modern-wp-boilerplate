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
    wordpress_nginx_conf = base64encode(file("${path.module}/wordpress-nginx.conf")),
    mysql_root_password = var.mysql_root_password,
    wordpress_db_password = var.wordpress_db_password
  })
}

output "droplet_ip" {
  value       = digitalocean_droplet.basic.ipv4_address
  description = "The public IP address of the droplet"
}

output "droplet_id" {
  value       = digitalocean_droplet.basic.id
  description = "The ID of the droplet"
}
