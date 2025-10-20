<?php

function columns_block($block_content, $block)
{
    if ($block["blockName"] === "core/columns") {
        // Use DOMDocument for more reliable HTML parsing
        $dom = new DOMDocument();
        libxml_use_internal_errors(true); // Suppress warnings
        $dom->loadHTML('<?xml encoding="utf-8" ?>' . $block_content, LIBXML_HTML_NOIMPLIED | LIBXML_HTML_NODEFDTD);

        // Find the wp-block-columns div
        $xpath = new DOMXPath($dom);
        $columnsDiv = $xpath->query('//div[contains(@class, "wp-block-columns")]')->item(0);

        if ($columnsDiv) {
            // Get the inner HTML content
            $content = "";
            foreach ($columnsDiv->childNodes as $child) {
                $content .= $dom->saveHTML($child);
            }
        } else {
            // Fallback to original content if parsing fails
            $content = $block_content;
        }

        // Define columns container Tailwind classes
        $classes = "flex flex-wrap gap-6 mb-6";

        // Get alignment specifically for this columns block
        $alignment = isset($block["attrs"]["align"]) ? $block["attrs"]["align"] : null;

        // Get vertical alignment
        $verticalAlignment = isset($block["attrs"]["verticalAlignment"]) ? $block["attrs"]["verticalAlignment"] : null;

        // Apply alignment classes
        if ($alignment === "center") {
            $classes .= " justify-center";
        } elseif ($alignment === "right") {
            $classes .= " justify-end";
        }

        // Apply vertical alignment classes
        if ($verticalAlignment === "center") {
            $classes .= " items-center";
        } elseif ($verticalAlignment === "bottom") {
            $classes .= " items-end";
        } else {
            $classes .= " items-start"; // default
        }

        // Check if it's a full-width block
        if ($alignment === "full" || $alignment === "wide") {
            $classes .= " w-full";
        }

        return get_view("components.default-blocks.columns", [
            "classes" => $classes,
            "content" => $content,
        ]);
    }

    return $block_content;
}

add_filter("render_block", "columns_block", 10, 2);
