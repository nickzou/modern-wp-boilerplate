server {
    listen 80;
    server_name {{PREVIEW_URL}};
    root {{WP_DIR}};
    
    index index.php index.html;

    # Cache settings
    set $skip_cache 0;
    
    if ($request_method = POST) {
        set $skip_cache 1;
    }
    
    if ($query_string != "") {
        set $skip_cache 1;
    }
    
    if ($request_uri ~* "/wp-admin/|/wp-login.php|/wp-json/") {
        set $skip_cache 1;
    }
    
    if ($http_cookie ~* "wordpress_logged_in|wp-postpass|woocommerce") {
        set $skip_cache 1;
    }

    # Let's Encrypt challenge 
    location ^~ /.well-known/acme-challenge/ {
        allow all;
        default_type "text/plain";
        try_files $uri =404;
    }
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;

        fastcgi_cache_bypass $skip_cache;
        fastcgi_no_cache $skip_cache;
        fastcgi_cache WORDPRESS;
        fastcgi_cache_valid 200 60m;
        add_header X-FastCGI-Cache $upstream_cache_status;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot|webp|avif|pdf|mp4|webm|json|xml)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    location ~ /\.ht {
        deny all;
    }
}
