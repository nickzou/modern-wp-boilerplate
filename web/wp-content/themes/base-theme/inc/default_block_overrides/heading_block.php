<?php
// Filter all core heading blocks to use Tailwind classes
function heading_block($block_content, $block)
{
    if ($block["blockName"] === "core/heading") {
        $level = isset($block["attrs"]["level"]) ? $block["attrs"]["level"] : 2;

        // Extract the content
        preg_match("/<h\d[^>]*>(.*?)<\/h\d>/s", $block_content, $matches);
        $content = $matches[1] ?? "";

        // Tailwind classes based on heading level
        $class_map = [
            1 => "text-[32px] font-bold leading-[1.65] mb-4 text-black",
            2 => "text-[28px] font-bold leading-[1.65] mb-2 text-black",
            3 => "text-2xl font-bold leading-[1.65] mb-2 text-black",
            4 => "text-2xl font-normal leading-[1.65] mb-2 text-black",
            5 => "text-lg font-semibold leading-[1.65] mb-2 text-black",
            6 => "text-lg font-semibold leading-[1.65] mb-2 text-[#505050]",
            // etc filter_heading_blocks_with_tailwind
        ];

        $classes = $class_map[$level] ?? $class_map[2];

        return get_view("components.default-blocks.heading", [
            "level" => $level,
            "classes" => $classes,
            "content" => $content,
        ]);
    }

    return $block_content;
}

add_filter("render_block", "heading_block", 10, 2);
