#!/bin/bash
set -e

ENV_FILE=".env"

source $ENV_FILE

if [ -z "$THEME_SLUG" ]; then
    echo "❌ Failed to get THEME_SLUG from .env file"
    exit 1
fi

echo "📍 THEME_SLUG: $THEME_SLUG"


# Update GitHub secret using gh CLI
echo "🔐 Updating GitHub secret..."
gh secret set THEME_SLUG \
  --body "$THEME_SLUG" \
  --repo "$REPO_OWNER/$REPO_NAME"

if [ $? -eq 0 ]; then
    echo "✅ GitHub secret THEME_SLUG updated successfully!"
else
    echo "❌ Failed to update GitHub secret"
    exit 1
fi
