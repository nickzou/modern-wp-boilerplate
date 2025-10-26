#!/bin/bash
set -e

ENV_FILE=".env"

source $ENV_FILE

# Get the droplet IP from Terraform
echo "🔍 Getting droplet IP from Terraform..."
DROPLET_IP=$(cd infrastructure && terraform output -raw droplet_ip)

if [ -z "$DROPLET_IP" ]; then
    echo "❌ Failed to get droplet IP from Terraform"
    exit 1
fi

echo "📍 Droplet IP: $DROPLET_IP"


# Update GitHub secret using gh CLI
echo "🔐 Updating GitHub secret..."
gh secret set DROPLET_IP \
  --body "$DROPLET_IP" \
  --repo "$REPO_OWNER/$REPO_NAME"

if [ $? -eq 0 ]; then
    echo "✅ GitHub secret DROPLET_IP updated successfully!"
else
    echo "❌ Failed to update GitHub secret"
    exit 1
fi
