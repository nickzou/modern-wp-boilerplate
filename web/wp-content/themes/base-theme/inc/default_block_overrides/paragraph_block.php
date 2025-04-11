<?php
// Filter all core heading blocks to use Tailwind classes
function paragraph_block($block_content, $block)
{
    if ($block["blockName"] === "core/paragraph") {
        // Extract the content
        preg_match("/<p[^>]*>(.*?)<\/p>/s", $block_content, $matches);
        $content = $matches[1] ?? "";

        // Define paragraph Tailwind classes
        $classes =
            "text-base leading-[1.65] mb-4 text-black [&_a]:ease-in-out [&_a]:duration-200 [&_a]:text-gray-400 [&_a]:hover:text-gray-600";

        // Get alignment specifically for this paragraph
        $alignment = isset($block["attrs"]["align"]) ? $block["attrs"]["align"] : null;

        // Apply alignment classes
        if ($alignment === "center") {
            $classes .= " text-center";
        } elseif ($alignment === "right") {
            $classes .= " text-right";
        }

        return get_view("components.default-blocks.paragraph", [
            "classes" => $classes,
            "content" => $content,
        ]);
    }

    return $block_content;
}

add_filter("render_block", "paragraph_block", 10, 2);
