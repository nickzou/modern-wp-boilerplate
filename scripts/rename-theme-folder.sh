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

BASE_THEME_DIR="web/wp-content/themes/base-theme"
THEME_DIR="web/wp-content/themes/$THEME_SLUG"

echo "Renaming base-theme to $THEME_SLUG"
mv "$BASE_THEME_DIR" "$THEME_DIR"
echo -e "${GREEN}Rename complete${NC}"
