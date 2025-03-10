<?php

/**
 * Enqueue rules for admin assets (js and css)
 *
 * @return void
 */


function enqueue_admin_assets()
{
    wp_enqueue_style('admin-tailwind');
};

add_action('admin_enqueue_scripts', 'enqueue_admin_assets');
