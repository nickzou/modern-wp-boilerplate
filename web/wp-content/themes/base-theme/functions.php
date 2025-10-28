<?php

function load_theme_files()
{
    $directory = get_template_directory() . "/inc/";

    // Check if the directory exists
    if (!is_dir($directory)) {
        trigger_error("Directory 'inc/' not found", E_USER_WARNING);
        return 0;
    }

    $count = 0;
    $files = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($directory, RecursiveDirectoryIterator::SKIP_DOTS),
    );

    foreach ($files as $file) {
        $filename = $file->getFilename();
        $filepath = $file->getPathname();

        // Only process PHP files
        if (pathinfo($filename, PATHINFO_EXTENSION) === "php" && is_file($filepath)) {
            require_once $filepath;
            $count++;
        }
    }

    return $count;
}

load_theme_files();
