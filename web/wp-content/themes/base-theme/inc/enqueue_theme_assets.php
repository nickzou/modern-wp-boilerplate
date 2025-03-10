<?php

/**
 * Enqueue rules for assets (js and css)
 *
 * @return void
 */


function enqueue_theme_assets()
{
    wp_enqueue_script('app');
};

add_action('wp_enqueue_scripts', 'enqueue_theme_assets');
