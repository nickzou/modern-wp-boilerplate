<?php

function default_block_category($categories)
{
    $categories[] = [
        "slug" => "base-theme",
        "title" => "Base Theme",
    ];

    return $categories;
}

add_filter("block_categories_all", "default_block_category");
