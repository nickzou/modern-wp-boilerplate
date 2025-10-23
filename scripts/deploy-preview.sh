#!/bin/bash
set -e  # Exit on error

# Usage: ./deploy-preview.sh feature-branch-name
BRANCH_NAME=$1

if [ -z "$BRANCH_NAME" ]; then
    echo "Usage: $0 <branch-name>"
    exit 1
fi

echo "Deploying preview for branch: $BRANCH_NAME"

# TODO: Sanitize branch name (remove special chars)
# TODO: Create CloudFlare DNS record
# TODO: Create database
# TODO: Install WordPress
# TODO: Generate nginx config
# TODO: Get SSL cert
# TODO: Reload nginx

# Sanitize branch name (replace / and _ with -)
SAFE_NAME=$(echo "$BRANCH_NAME" | sed 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]')

echo "🚀 Deploying preview for: $BRANCH_NAME"
echo "📝 Safe name: $SAFE_NAME"

echo "Preview deployment complete!"
echo "URL: https://${BRANCH_NAME}.pandacalculus.com"
```
