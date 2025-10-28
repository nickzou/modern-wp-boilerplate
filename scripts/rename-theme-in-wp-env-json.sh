#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Path to your .env file
ENV_FILE=".env"

# Extract the THEME_SLUG variable from .env file
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
  echo "Warning: .env file not found at $ENV_FILE"
  THEME_SLUG="base-theme"  # Default fallback value
fi

# Check if package.json exists
if [ ! -f ".wp-env.json" ]; then
    echo "Error: .wp-env.json not found in the current directory"
    exit 1
fi

# Replace 'base-theme' with THEME_SLUG env variable in .wp-env.json
sed -i "" "s/base-theme/${THEME_SLUG}/g" .wp-env.json

echo "Renaming base-theme to $THEME_SLUG in .wp-env.json"
echo -e "${GREEN}Rename complete${NC}"
