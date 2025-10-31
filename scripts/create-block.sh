#!/bin/bash

# Load environment variables from root directory
source ".env"

# Default values
namespace="${THEME_SLUG:-"my-namespace"}"
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
        --block_name) block_name="$2"; shift ;;
        --title) title="$2"; shift ;;
        --category) category="$2"; shift ;;
        --description) description="$2"; shift ;;
        --icon) icon="$2"; shift ;;
        --version) version="$2"; shift ;;
        --api_version) api_version="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Format the full block name
full_name="${namespace}/${block_name}"

# Define the blocks directory
# blocks_dir="web/wp-content/themes/${THEME_NAME}/inc/blocks/${block_name}"
blocks_dir="src/blocks/${block_name}"

mkdir -p "$blocks_dir"

# Create the block.json content
cat > "${blocks_dir}/block.json" << EOF
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
	"editorScript": "file:./editor.js",
    "render": "file:./render.php",
    "editorStyle": [ "file:./../../css/admin-tailwind.css" ],
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

# Create the editor.js file
cat > "src/blocks/${block_name}/editor.tsx" << EOF
/**
 * WordPress dependencies
 */
import { registerBlockType, BlockConfiguration, BlockAttributes } from "@wordpress/blocks";
import { useBlockProps, RichText } from "@wordpress/block-editor";
import { __ } from "@wordpress/i18n";
import Metadata from "./../../types/blocks/Metadata"; 

/**
 * Internal dependencies
 */
import metadata from "./block.json";

const {name, ...settings } = metadata as unknown as Metadata;

/**
 * Edit component props
 */
interface EditProps {
	attributes: BlockAttributes;
	setAttributes: (attrs: Partial<BlockAttributes>) => void;
}

/**
 * Save component props
 */
interface SaveProps {
	attributes: BlockAttributes;
}

/**
 * Edit component - Renders the block in the editor
 * 
 * @param {EditProps} props Block properties
 * @returns {JSX.Element} The component to render
 */
const Edit = ({ attributes, setAttributes }: EditProps): JSX.Element => {
	const { content } = attributes;
	const blockProps = useBlockProps();

	return (
		<div { ...blockProps }>
			<RichText
				tagName="p"
				value={ content }
				onChange={ (newContent: string) => setAttributes({ content: newContent }) }
				placeholder={ __( 'Enter content...', metadata.textdomain ) }
			/>
		</div>
	);
};

/**
 * Save component - Defines the saved output
 * 
 * @param {SaveProps} props Block properties
 * @returns {JSX.Element} The component to save
 */
const Save = ({ attributes }: SaveProps): JSX.Element => {
	const { content } = attributes;
	const blockProps = useBlockProps.save();

	return (
		<div { ...blockProps }>
			<RichText.Content
				tagName="p"
				value={ content }
			/>
		</div>
	);
};

/**
 * Register the block
 */
registerBlockType( metadata.name, {
	...settings,
	edit: Edit,
	save: Save,
} as BlockConfiguration<BlockAttributes>);

EOF



cat > "${blocks_dir}/render.php" <<EOF
<?php
/**
 * Render template for a custom block
 *
 * @package MyTheme
 */

// Exit if accessed directly
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}
?>

<div>
    <?= "${full_name}" ?>
</div>

EOF

echo "✅ block.json created successfully!"
echo "Block identifier: ${full_name}"
echo "Files created:"
echo "- ${blocks_dir}/block.json"
echo "- ${blocks_dir}/editor.tsx"
echo "- ${blocks_dir}/render.php"

echo "Running build processes..."
npm run admin:tailwind:prod
npm run wp:blocks:build
echo "✅ Block creation and build complete!"
