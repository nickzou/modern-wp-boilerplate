#!/bin/bash

# Path to your .env file
ENV_FILE=".env"

# Path to the output .env.tpl file
ENV_TPL_FILE="infrastructure/templates/.env.tpl"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: $ENV_FILE file not found."
    exit 1
fi

# Source the .env file
source "$ENV_FILE"

# Clear or create terraform.tfvars file
> "$ENV_TPL_FILE"

# Generate server.env.tpl with actual values
cat > "$ENV_TPL_FILE" << EOF
# Server Configuration - Generated from .env
DOMAIN=$TF_DOMAIN_NAME
MYSQL_ROOT_PASSWORD=$TF_MYSQL_ROOT_PASSWORD
SSL_EMAIL=$TF_SSL_EMAIL
CF_API_TOKEN=$TF_CF_TOKEN
CF_ZONE_ID=$TF_CF_ZONE_ID
PROJECT_NAME=$TF_PROJECT_NAME
EOF

echo "Created $ENV_TPL_FILE from $ENV_FILE"
