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
    wp_register_script("app", "{$theme_uri}/js/app.js", [], filemtime("{$theme_directory}/js/app.js"));
    wp_register_script(
        "alpine",
        "https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js",
        ["alpine-intersect"],
        "3.x.x",
        [
            "strategy" => "defer",
            "in_footer" => false,
        ]
    );

    wp_register_script(
        "alpine-intersect",
        "https://cdn.jsdelivr.net/npm/@alpinejs/intersect@3.x.x/dist/cdn.min.js",
        [],
        "3.x.x",
        [
            "strategy" => "defer",
            "in_footer" => false,
        ]
    );
}

/**
 * Hook to enqueue all JS files in theme
 */
add_action("init", "register_theme_js_files");
