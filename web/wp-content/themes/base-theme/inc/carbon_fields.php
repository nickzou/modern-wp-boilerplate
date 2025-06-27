<?php
$theme_dir = get_template_directory();

if (file_exists("$theme_dir/vendor/autoload.php")) {
    require_once "$theme_dir/vendor/autoload.php";
}

function carbon_field_load()
{
    \Carbon_Fields\Carbon_Fields::boot();
}

add_action("after_setup_theme", "carbon_field_load");
