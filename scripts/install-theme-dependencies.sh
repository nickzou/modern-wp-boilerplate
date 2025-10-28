#!/bin/bash

# Path to your .env file
ENV_FILE=".env"

# Extract the THEME_SLUG variable from .env file
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
  echo "Warning: .env file not found at $ENV_FILE"
  THEME_SLUG="base-theme"  # Default fallback value
fi

THEME_DIR="web/wp-content/themes/$THEME_SLUG"
COMPOSER_JSON="$THEME_DIR/composer.json"
COMPOSER_LOCK="$THEME_DIR/composer.lock"

# Check if composer is installed
if ! command -v composer &> /dev/null; then
  echo "Error: Composer is not installed or not in PATH"
  exit 1
fi

# Check if composer.json exists
if [ ! -f "$COMPOSER_JSON" ]; then
  echo "Error: composer.json not found at $COMPOSER_JSON"
  exit 1
fi

# Decide whether to run install or update
if [ ! -f "$COMPOSER_LOCK" ]; then
  echo "No composer.lock file found, running composer install"
  COMMAND="install"
elif [ "$COMPOSER_JSON" -nt "$COMPOSER_LOCK" ]; then
  echo "composer.json is newer than composer.lock, running composer update"
  COMMAND="update"
else
  echo "Using existing composer.lock file, running composer install"
  COMMAND="install"
fi

echo "Executing: composer $COMMAND in $THEME_DIR"
composer "$COMMAND" -d "$THEME_DIR"

exit $?

