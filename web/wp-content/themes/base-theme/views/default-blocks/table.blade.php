<div class="overflow-x-auto">
    <table class="{{ $table_classes }}">
        @if (! empty($header_cells))
            <thead class="{{ $thead_classes }}">
                @foreach ($header_cells as $row)
                    <tr>
                        @foreach ($row as $cell)
                            <th class="{{ $th_classes }}">{!! $cell !!}</th>
                        @endforeach
                    </tr>
                @endforeach
            </thead>
        @endif

        <tbody class="{{ $tbody_classes }}">
            @foreach ($body_cells as $row)
                <tr>
                    @foreach ($row as $cell)
                        <td class="{{ $td_classes }}">{!! $cell !!}</td>
                    @endforeach
                </tr>
            @endforeach
        </tbody>
    </table>
</div>
