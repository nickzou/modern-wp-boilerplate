#!/bin/bash
# Script to copy register.php files from src/blocks to the WordPress theme

# Load environment variables if .env file exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# Set default theme name if not defined in environment
THEME_NAME=${THEME_NAME:-"base-theme"}

# Count for summary
COPIED_COUNT=0

# Find all PHP files in the blocks directory
for FILE_PATH in ./src/blocks/**/*.php; do
  # Skip if file doesn't exist (in case the glob doesn't match anything)
  [ -f "$FILE_PATH" ] || continue
  
  # Get the directory containing the PHP file
  BLOCK_DIR=$(dirname "$FILE_PATH")
  
  # Extract the block name (last part of the directory path)
  BLOCK_NAME=$(basename "$BLOCK_DIR")
  
  # Define destination directory
  DEST_DIR="./web/wp-content/themes/${THEME_NAME}/inc/blocks/${BLOCK_NAME}"
  
  # Create destination directory if it doesn't exist
  mkdir -p "$DEST_DIR"
  
  # Copy the PHP file to the destination
  cp "$FILE_PATH" "${DEST_DIR}/register.php"
  
  echo "Copied and updated: ${BLOCK_NAME} register.php"
  
  ((COPIED_COUNT++))
done

echo "All ${COPIED_COUNT} register.php files copied to the blocks directory"
