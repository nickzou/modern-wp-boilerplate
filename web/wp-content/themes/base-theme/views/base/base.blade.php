<!DOCTYPE html>
<html {!! $language_attributes !!}>
<head>
    <meta charset="{{ $charset }}">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    {!! $wp_head !!}
</head>

<body class="{{ $body_class }}">
        {!! $wp_body_open !!}

    <header>
        <h1><a href="{{ $home_url }}">{{ $site_name }}</a></h1>
        <p>{{ $description }}</p>
    </header>

    <footer>
        <p>&copy; {{ $copyright_year }} {{ $site_name }}</p>
    </footer>

    {!! $wp_footer !!}
</body>
</html>
