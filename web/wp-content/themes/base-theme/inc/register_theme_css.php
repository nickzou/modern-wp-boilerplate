<?php

/**
 * Register all stylsheet files in the theme's css directory
 *
 * @return void
 */
function register_theme_css_files()
{
    $theme_directory = get_template_directory();
    $theme_uri = get_template_directory_uri();
    wp_register_style(
        "tailwind",
        "{$theme_uri}/css/tailwind.css",
        [],
        filemtime("{$theme_directory}/css/tailwind.css"),
        "all"
    );
    wp_register_style(
        "admin-tailwind",
        "{$theme_uri}/css/admin-tailwind.css",
        [],
        filemtime("{$theme_directory}/css/admin-tailwind.css"),
        "all"
    );
    wp_register_style(
        "styles",
        "{$theme_uri}/css/styles.css",
        [],
        filemtime("{$theme_directory}/css/styles.css"),
        "all"
    );
}

/**
 * Hook to enqueue all JS files in theme
 */
add_action("init", "register_theme_css_files");
