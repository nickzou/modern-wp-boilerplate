<?php

$theme_dir = get_template_directory();

if (file_exists("$theme_dir/vendor/autoload.php")) {
    require_once "$theme_dir/vendor/autoload.php";
}

use eftec\bladeone\BladeOne;

function get_blade_instance()
{
    $theme_dir = get_template_directory();
    $views = "$theme_dir/views";

    $cache = "$theme_dir/cache";

    if (!file_exists($cache)) {
        mkdir($cache, 0755, true);
    }

    // BladeOne mode: 0=fast, 1=forced, 2=strict, 5=debug
    // Use 5 (debug) for development, 0 for production
    $mode = WP_DEBUG ? 5 : 0;

    return new BladeOne($views, $cache, $mode);
}

function view($template, $data = [])
{
    $globals = [
        'language_attributes' => get_language_attributes(),
        'charset' => get_bloginfo('charset'),
        'site_name' => get_bloginfo('name'),
        'site_description' => get_bloginfo('description'),
        'site_url' => get_bloginfo('url'),
        'template_directory_uri' => get_template_directory_uri(),
        'stylesheet_directory_uri' => get_stylesheet_directory_uri(),
        'home_url' => home_url('/'),
        'wp_head' => function() { ob_start(); wp_head(); return ob_get_clean(); },
        'wp_body_open' => function() { ob_start(); wp_head(); return ob_get_clean(); },
        'wp_footer' => function() { ob_start(); wp_footer(); return ob_get_clean(); },
        'body_class' => join(' ', get_body_class()),
        'copyright_year' => date('Y'),
    ];

    $merged_data = array_merge($globals, $data);
    try {
        $blade = get_blade_instance();
        echo $blade->run($template, $merged_data);
    } catch (Exception $e) {
        if (WP_DEBUG) {
            echo "Template error: " . $e->getMessage();
        }
    }
}

