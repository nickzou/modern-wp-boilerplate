<div class="overflow-x-auto">
    <table class="{{ $table_classes }} mb-6 min-w-full border-collapse">
        @if (! empty($header_cells))
            <thead class="bg-gray-100 dark:bg-gray-800">
                @foreach ($header_cells as $row)
                    <tr>
                        @foreach ($row as $cell)
                            <th
                                class="border border-gray-300 px-4 py-2 text-left font-sans font-semibold text-gray-700 dark:border-gray-700 dark:text-white"
                            >
                                {!! $cell !!}
                            </th>
                        @endforeach
                    </tr>
                @endforeach
            </thead>
        @endif

        <tbody class="bg-white dark:bg-transparent">
            @foreach ($body_cells as $row)
                <tr>
                    @foreach ($row as $cell)
                        <td class="border border-gray-300 px-4 py-2 font-sans dark:border-gray-700 dark:text-white">
                            {!! $cell !!}
                        </td>
                    @endforeach
                </tr>
            @endforeach
        </tbody>
    </table>
</div>
