# HTTP server to redirect to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name staging.${domain_name};
    
    # Allow Let's Encrypt validation to work
    location /.well-known/acme-challenge/ {
        root /letsencrypt;
        default_type "text/plain";
        allow all;
    }
    
    # Redirect all other HTTP requests to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS server for staging
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    
    server_name staging.${domain_name};
    
    # SSL certificates
    ssl_certificate /etc/letsencrypt/live/staging.${domain_name}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/staging.${domain_name}/privkey.pem;
    
    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    
    # HSTS (uncomment if you understand the implications)
    # add_header Strict-Transport-Security "max-age=63072000" always;
    
    # Proxy to staging WordPress container
    location / {
        proxy_pass http://staging_wordpress:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
