#!/bin/bash

# Path to your .env file
ENV_FILE=".env"

# Extract the THEME_NAME variable from .env file
if [ -f "$ENV_FILE" ]; then
  THEME_NAME=$(grep -E "^THEME_NAME=" "$ENV_FILE" | cut -d= -f2)
  # Remove any surrounding quotes if present
  THEME_NAME=$(echo $THEME_NAME | sed 's/^"//;s/"$//;s/^'\''//;s/'\''$//')
  
  if [ -n "$THEME_NAME" ]; then
    echo "Using theme: $THEME_NAME"
  else
    echo "Warning: THEME_NAME not found in $ENV_FILE"
    THEME_NAME="base-theme"  # Default fallback value
  fi
else
  echo "Warning: .env file not found at $ENV_FILE"
  THEME_NAME="base-theme"  # Default fallback value
fi

THEME_DIR="web/wp-content/themes/$THEME_NAME"
COMPOSER_JSON="$THEME_DIR/composer.json"
COMPOSER_LOCK="$THEME_DIR/composer.lock"

# Check if composer is installed
if ! command -v composer &> /dev/null; then
  echo "Error: Composer is not installed or not in PATH"
  exit 1
fi

# Check if composer.json exists
if [ ! -f "composer.json" ]; then
  echo "Error: composer.json not found in current directory"
  exit 1
fi
