@php
    $list_classes = "mb-6 space-y-1.5 pl-6 dark:text-white";
    $item_classes = "text-base leading-relaxed";
@endphp

@if ($is_ordered)
    <ol class="{{ $list_classes }} list-decimal">
        @foreach ($items as $item)
            <li class="{{ $item_classes }} font-sans">{!! $item !!}</li>
        @endforeach
    </ol>
@else
    <ul class="{{ $list_classes }} list-disc">
        @foreach ($items as $item)
            <li class="{{ $item_classes }} font-sans">{!! $item !!}</li>
        @endforeach
    </ul>
@endif
