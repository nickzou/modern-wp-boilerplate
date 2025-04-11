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

        // Define classes for different list types
        $list_classes = "pl-6 space-y-1.5 mb-6";
        $item_classes = "text-base leading-relaxed";

        // Additional styling based on list type
        if ($is_ordered) {
            $list_classes .= " list-decimal";
        } else {
            $list_classes .= " list-disc";
        }

        return get_view("components.default-blocks.list", [
            "is_ordered" => $is_ordered,
            "list_classes" => $list_classes,
            "item_classes" => $item_classes,
            "items" => $items,
        ]);
    }

    return $block_content;
}

add_filter("render_block", "list_block", 10, 2);
