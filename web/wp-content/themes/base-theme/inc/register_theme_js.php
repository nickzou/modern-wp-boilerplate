<?php

/**
 * Register all JavaScript files in the theme's js directory
 *
 * @return void
 */
function register_theme_js_files()
{
    $theme_directory = get_template_directory();
    $theme_uri = get_template_directory_uri();
    wp_register_script('app', "{$theme_uri}/js/app.js", [], filemtime("{$theme_directory}/js/app.js"));
}

/**
 * Hook to enqueue all JS files in theme
 */
add_action('init', 'register_theme_js_files');
