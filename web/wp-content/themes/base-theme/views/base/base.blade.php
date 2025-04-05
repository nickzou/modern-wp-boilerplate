<!DOCTYPE html>
<html {!! $language_attributes !!}>
<head>
    <meta charset="{{ $charset }}">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    @wphead
</head>

<body class="{{ $body_class }}">
    @wpbodyopen

    @include('globals.header')
        yotyot
    @include('globals.footer')
    @wpfooter
</body>
</html>
