<?php

function column_block($block_content, $block)
{
    if ($block["blockName"] === "core/column") {
        $dom = new DOMDocument();
        $dom->loadHTML('<?xml encoding="utf-8" ?>' . $block_content, LIBXML_HTML_NOIMPLIED | LIBXML_HTML_NODEFDTD);

        // Find the wp-block-column div
        $xpath = new DOMXPath($dom);
        $columnDiv = $xpath->query('//div[contains(@class, "wp-block-column")]')->item(0);

        if ($columnDiv) {
            // Get the inner HTML content
            $content = "";
            foreach ($columnDiv->childNodes as $child) {
                $content .= $dom->saveHTML($child);
            }
        } else {
            // Fallback to original content if parsing fails
            $content = $block_content;
        }

        // Define column Tailwind classes
        $classes = "flex-1 min-w-0"; // flex-1 for equal width, min-w-0 prevents overflow

        // Get custom width if set
        $width = isset($block["attrs"]["width"]) ? $block["attrs"]["width"] : null;

        if ($width) {
            // Convert percentage or specific width to Tailwind classes
            $classes = "min-w-0"; // Remove flex-1 for custom width

            // Add custom width style (you might want to handle this differently based on your needs)
            $customStyle = "flex: 0 0 {$width};";
        }

        return get_view("components.default-blocks.column", [
            "classes" => $classes,
            "content" => $content,
            "customStyle" => $customStyle ?? null,
        ]);
    }

    return $block_content;
}

add_filter("render_block", "column_block", 10, 2);
