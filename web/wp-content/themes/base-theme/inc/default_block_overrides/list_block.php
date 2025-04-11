<?php
// Filter all core heading blocks to use Tailwind classes
function list_block($block_content, $block)
{
    if ($block["blockName"] === "core/list") {
        $is_ordered = isset($block["attrs"]["ordered"]) && $block["attrs"]["ordered"] === true;

        // Extract the content - get all list items
        $list_items = [];
        if ($is_ordered) {
            preg_match("/<ol[^>]*>(.*?)<\/ol>/s", $block_content, $matches);
        } else {
            preg_match("/<ul[^>]*>(.*?)<\/ul>/s", $block_content, $matches);
        }

        $list_content = $matches[1] ?? "";

        preg_match_all("/<li[^>]*>(.*?)<\/li>/s", $list_content, $item_matches);
        $items = $item_matches[1] ?? [];

        return get_view("components.default-blocks.list", [
            "is_ordered" => $is_ordered,
            "items" => $items,
        ]);
    }

    return $block_content;
}

add_filter("render_block", "list_block", 10, 2);
