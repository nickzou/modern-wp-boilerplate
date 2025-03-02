#!/bin/bash

# Load environment variables from root directory
if [ -f "$(dirname "$0")/../.env" ]; then
  source "$(dirname "$0")/../.env"
fi

# Default values
namespace="${THEME_NAME:-"my-namespace"}"
block_name="my-block"
title="My Block"
category="widgets"
description="A custom block for displaying content."
icon="smiley"
version="0.1.0"
api_version=3

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --namespace) namespace="$2"; shift ;;
        --block-name) block_name="$2"; shift ;;
        --title) title="$2"; shift ;;
        --category) category="$2"; shift ;;
        --description) description="$2"; shift ;;
        --icon) icon="$2"; shift ;;
        --version) version="$2"; shift ;;
        --api-version) api_version="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Format the full block name
full_name="${namespace}/${block_name}"

# Create the block.json content
cat > block.json << EOF
{
	"\$schema": "https://schemas.wp.org/trunk/block.json",
	"apiVersion": ${api_version},
	"name": "${full_name}",
	"version": "${version}",
	"title": "${title}",
	"category": "${category}",
	"icon": "${icon}",
	"description": "${description}",
	"example": {},
	"textdomain": "${block_name}",
	"editorScript": "file:./build/index.js",
	"attributes": {
		"content": {
			"type": "string",
			"source": "html",
			"selector": "p",
			"default": ""
		}
	}
}
EOF

echo "✅ block.json created successfully!"
echo "Block identifier: ${full_name}"
