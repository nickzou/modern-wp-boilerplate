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
if [ ! -f "tailwind.css" ]; then
    echo "Error: tailwind.css not found in the current directory"
    exit 1
fi

# Replace 'base-theme' with THEME_SLUG env variable in tailwind.csss
sed -i "" "s/base-theme/${THEME_SLUG}/g" tailwind.css

echo "Renaming base-theme to $THEME_SLUG in tailwind.css"
echo -e "${GREEN}Rename complete${NC}"
