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

    $blade = new BladeOne($views, $cache, $mode);

    $blade->directive("wphead", function () {
        return "<?php wp_head(); ?>";
    });

    $blade->directive("wpfooter", function () {
        return "<?php wp_footer(); ?>";
    });

    $blade->directive("wpbodyopen", function () {
        return '<?php if (function_exists("wp_body_open")) { wp_body_open(); } ?>';
    });

    $blade->directive("content", function () {
        return "<?php the_content(); ?>";
    });

    $blade->directive("pagination", function () {
        return "<?php 
                    echo \"<div class='flex items-center justify-center text-it-dark-gray lg:justify-end dark:text-white'>\";
                        echo get_the_posts_pagination([
                            'type' => 'plain',
                            'prev_text' => 'Prev',
                            'next_text' => 'Next',
                        ]); 
                    echo \"</div>\";
                ?>";
    });

    $blade->directive("asset", function ($name) {
        return "<?php echo get_template_directory_uri() . '/' . $name; ?>";
    });

    $blade->directive("svg", function ($name) {
        return "<?php echo file_get_contents(get_template_directory() . '/' . $name); ?>";
    });

    return $blade;
}

function view($template, $data = [])
{
    $globals = [
        "language_attributes" => get_language_attributes(),
        "charset" => get_bloginfo("charset"),
        "site_name" => get_bloginfo("name"),
        "site_description" => get_bloginfo("description"),
        "site_url" => get_bloginfo("url"),
        "template_directory_uri" => get_template_directory_uri(),
        "stylesheet_directory_uri" => get_stylesheet_directory_uri(),
        "home_url" => home_url("/"),
        "wp_body_open" => function () {
            ob_start();
            wp_head();
            return ob_get_clean();
        },
        "menus" => (object) [
            "primary_navigation" => wp_get_nav_menu_items("primary-navigation"),
        ],
        "body_class" => join(" ", get_body_class()),
        "copyright_year" => date("Y"),
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

function get_view($template, $data = [])
{
    $globals = [
        "language_attributes" => get_language_attributes(),
        "charset" => get_bloginfo("charset"),
        "site_name" => get_bloginfo("name"),
        "site_description" => get_bloginfo("description"),
        "site_url" => get_bloginfo("url"),
        "template_directory_uri" => get_template_directory_uri(),
        "stylesheet_directory_uri" => get_stylesheet_directory_uri(),
        "home_url" => home_url("/"),
        "wp_body_open" => function () {
            ob_start();
            wp_head();
            return ob_get_clean();
        },
        "body_class" => join(" ", get_body_class()),
        "copyright_year" => date("Y"),
    ];

    $merged_data = array_merge($globals, $data);
    try {
        $blade = get_blade_instance();
        return $blade->run($template, $merged_data);
    } catch (Exception $e) {
        if (WP_DEBUG) {
            echo "Template error: " . $e->getMessage();
        }
    }
}
