<?php
/**
 * Register all custom blocks from a specified directory
 *
 * @return void
 */
function register_custom_blocks()
{
    $blocks_dir = get_template_directory() . "/blocks";

    if (!file_exists($blocks_dir)) {
        return;
    }

    $block_folders = array_filter(glob($blocks_dir . "/*"), "is_dir");

    foreach ($block_folders as $block) {
        $block_json = $block . "/block.json";

        if (file_exists($block_json)) {
            register_block_type($block_json);
        }
    }
}
add_action("init", "register_custom_blocks");
