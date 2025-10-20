<div
    class="{{ $classes }}"
    @if (isset($customStyle))
        style="{{ $customStyle }}"
    @endif
>
    {!! $content !!}
</div>
