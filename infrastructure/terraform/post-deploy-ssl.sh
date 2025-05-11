#!/bin/bash
# post-deploy-ssl.sh
# This script is designed to be run after Terraform has finished deploying
# the WordPress infrastructure and DNS records have had time to propagate.

# Exit on any error
set -e

# Check if all required arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <server_ip> <domain_name> <ssh_key_path> <ssl_email>"
    exit 1
fi

# Get arguments
SERVER_IP=$1
DOMAIN_NAME=$2
SSH_KEY_PATH=$3
SSL_EMAIL=$4

# Colors for pretty output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting SSL certificate setup for $DOMAIN_NAME...${NC}"

# Function to check DNS propagation
check_dns() {
    local domain=$1
    local expected_ip=$2
    local resolved_ip
    
    echo "Checking DNS propagation for $domain..."
    # Get the last line from dig output which should be the actual IP address
    # even if CNAME resolution returns multiple lines
    resolved_ip=$(dig +short $domain | tail -n1)
    
    if [ "$resolved_ip" = "$expected_ip" ]; then
        echo -e "${GREEN}DNS has propagated successfully for $domain!${NC}"
        return 0
    else
        echo "DNS has not propagated yet. Expected IP: $expected_ip, Got: $resolved_ip"
        return 1
    fi
}

# Wait for DNS propagation
echo "Waiting for DNS propagation (checking every 30 seconds)..."
for i in {1..20}; do  # Try for 10 minutes (20 * 30 seconds)
    if check_dns "$DOMAIN_NAME" "$SERVER_IP" && check_dns "www.$DOMAIN_NAME" "$SERVER_IP" && check_dns "staging.$DOMAIN_NAME" "$SERVER_IP"; then
        echo -e "${GREEN}All DNS records have propagated!${NC}"
        break
    fi
    
    if [ $i -eq 20 ]; then
        echo -e "${YELLOW}Warning: DNS records haven't fully propagated after 10 minutes.${NC}"
        echo "You may need to run this script again later."
        echo "Do you want to continue anyway? (y/n)"
        read -r continue_anyway
        if [[ "$continue_anyway" != "y" ]]; then
            echo "Exiting. Run this script again when DNS has propagated."
            exit 1
        fi
    else
        echo "Waiting 30 seconds before checking again... (attempt $i/20)"
        sleep 30
    fi
done

# Setup SSL certificate
echo -e "${YELLOW}Setting up SSL certificates...${NC}"

# SSH commands to set up SSL
ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no root@"$SERVER_IP" << EOF
    # First make sure your firewall allows traffic on port 80
    echo "Checking firewall status..."
    if command -v ufw &> /dev/null; then
        echo "UFW firewall detected, ensuring ports 80 and 443 are open..."
        ufw allow 80/tcp
        ufw allow 443/tcp
    fi
    
    # Create directory for Let's Encrypt webroot validation
    echo "Setting up webroot for Let's Encrypt validation..."
    mkdir -p /opt/wordpress/letsencrypt/.well-known/acme-challenge
    chmod -R 755 /opt/wordpress/letsencrypt
    
    # Create a simple Nginx config for Let's Encrypt validation
    echo "Creating temporary Nginx config for Let's Encrypt validation..."
    cat > /opt/wordpress/letsencrypt.conf << EOCFG
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME staging.$DOMAIN_NAME;
    
    location /.well-known/acme-challenge/ {
        root /letsencrypt;
        default_type "text/plain";
        allow all;
    }
    
    location / {
        return 200 "Let's Encrypt validation server";
    }
}
EOCFG
    
    # Stop any running containers
    echo "Stopping all containers to free port 80..."
    docker stop \$(docker ps -q) 2>/dev/null || true
    
    # Run a simple Nginx container just for SSL verification
    echo "Starting Nginx container for Let's Encrypt validation..."
    docker run -d --name ssl_validation \
      -p 80:80 \
      -v /opt/wordpress/letsencrypt:/letsencrypt \
      -v /opt/wordpress/letsencrypt.conf:/etc/nginx/conf.d/default.conf \
      nginx:latest
    
    # Check if Nginx is running and port 80 is open
    echo "Checking if Nginx is running and accessible..."
    sleep 5
    curl -s -o /dev/null -w "%{http_code}\n" http://localhost:80 || echo "Warning: Nginx may not be accessible"
    
    # Get SSL certificate for main domain using webroot
    echo "Getting SSL certificate for $DOMAIN_NAME and www.$DOMAIN_NAME..."
    certbot certonly --webroot -w /opt/wordpress/letsencrypt -d $DOMAIN_NAME -d www.$DOMAIN_NAME --non-interactive --agree-tos --email $SSL_EMAIL
    
    # Get SSL certificate for staging subdomain
    echo "Getting SSL certificate for staging.$DOMAIN_NAME..."
    certbot certonly --webroot -w /opt/wordpress/letsencrypt -d staging.$DOMAIN_NAME --non-interactive --agree-tos --email $SSL_EMAIL
    
    # Create renewal cron job
    echo "Setting up certificate renewal cron job..."
    echo "0 3 * * * certbot renew --quiet --webroot -w /opt/wordpress/letsencrypt --post-hook 'docker exec wordpress_nginx nginx -s reload'" | crontab -
    
    # Stop the temporary Nginx container
    echo "Stopping temporary Nginx container..."
    docker stop ssl_validation
    docker rm ssl_validation
    
    # Clean up
    echo "Cleaning up temporary files..."
    rm /opt/wordpress/letsencrypt.conf
    
    # Restart original containers
    echo "Restarting original containers..."
    cd /opt/wordpress && docker-compose up -d
    
    # Modify the volumes for the nginx container to include letsencrypt directory
    echo "Ensuring letsencrypt directory is accessible to nginx..."
    docker exec -it wordpress_nginx mkdir -p /letsencrypt
    docker cp /opt/wordpress/letsencrypt/. wordpress_nginx:/letsencrypt/
    
    # Reload Nginx configuration
    echo "Reloading Nginx configuration..."
    docker exec wordpress_nginx nginx -s reload
EOF

echo -e "${GREEN}SSL certificate setup completed successfully!${NC}"
echo "Your WordPress sites are now accessible via HTTPS:"
echo "- Main site: https://$DOMAIN_NAME"
echo "- Staging site: https://staging.$DOMAIN_NAME"
echo ""
echo "Note: If you want to add SSL for feature branches in the future,"
echo "run the following command on the server after creating a feature branch:"
echo "certbot certonly --webroot -w /opt/wordpress/letsencrypt -d branch-name.$DOMAIN_NAME"

exit 0
