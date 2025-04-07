@if ($is_ordered)
    <ol class="{{ $list_classes }}">
        @foreach ($items as $item)
            <li class="{{ $item_classes }}">{!! $item !!}</li>
        @endforeach
    </ol>
@else
    <ul class="{{ $list_classes }}">
        @foreach ($items as $item)
            <li class="{{ $item_classes }}">{!! $item !!}</li>
        @endforeach
    </ul>
@endif
