<?php
// Filter core table blocks to use Tailwind classes
function table_block($block_content, $block)
{
    if ($block["blockName"] === "core/table") {
        // Extract the table head content
        preg_match("/<thead[^>]*>(.*?)<\/thead>/s", $block_content, $thead_matches);
        $thead_content = $thead_matches[1] ?? "";

        // Extract header rows
        preg_match_all("/<tr[^>]*>(.*?)<\/tr>/s", $thead_content, $thead_row_matches);
        $header_rows = $thead_row_matches[1] ?? [];

        // Extract header cells from each row
        $header_cells = [];
        foreach ($header_rows as $row) {
            preg_match_all("/<th[^>]*>(.*?)<\/th>/s", $row, $th_matches);
            $header_cells[] = $th_matches[1] ?? [];
        }

        // Extract the table body content
        preg_match("/<tbody[^>]*>(.*?)<\/tbody>/s", $block_content, $tbody_matches);
        $tbody_content = $tbody_matches[1] ?? "";

        // Extract body rows
        preg_match_all("/<tr[^>]*>(.*?)<\/tr>/s", $tbody_content, $tbody_row_matches);
        $body_rows = $tbody_row_matches[1] ?? [];

        // Extract body cells from each row
        $body_cells = [];
        foreach ($body_rows as $row) {
            preg_match_all("/<td[^>]*>(.*?)<\/td>/s", $row, $td_matches);
            $body_cells[] = $td_matches[1] ?? [];
        }

        // Get table attributes
        $has_fixed_layout = isset($block["attrs"]["hasFixedLayout"]) && $block["attrs"]["hasFixedLayout"];

        // Define classes
        $table_classes = "";
        if ($has_fixed_layout) {
            $table_classes .= " table-fixed";
        }

        return get_view("components.default-blocks.table", [
            "table_classes" => $table_classes,
            "header_cells" => $header_cells,
            "body_cells" => $body_cells,
        ]);
    }

    return $block_content;
}

add_filter("render_block", "table_block", 10, 2);
