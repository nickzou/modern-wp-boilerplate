<!DOCTYPE html>
<html {!! $language_attributes !!}>
    <head>
        <meta charset="{{ $charset }}" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
        @wphead
    </head>

    <body class="{{ $body_class }}">
        @wpbodyopen

        @include("globals.header")
        @yield("content")
        @include("globals.footer")
        @wpfooter
    </body>
</html>
