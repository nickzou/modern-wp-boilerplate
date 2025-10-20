<?php

/**
 * Enqueue rules for assets (js and css)
 *
 * @return void
 */

function enqueue_theme_assets()
{
    wp_enqueue_script("app");
    wp_enqueue_script("alpine");
    wp_enqueue_script("alpine-intersect");
    wp_enqueue_style("tailwind");
    wp_enqueue_style("styles");
}

add_action("wp_enqueue_scripts", "enqueue_theme_assets");
