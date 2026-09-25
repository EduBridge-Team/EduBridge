<!doctype html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ config('app.name', 'EduBridge') }} API</title>
    <style>
        body {
            margin: 0;
            min-height: 100vh;
            display: grid;
            place-items: center;
            font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background: #f5f7fb;
            color: #172033;
        }
        main {
            width: min(560px, calc(100% - 48px));
            padding: 32px;
            border: 1px solid #dfe5ee;
            border-radius: 18px;
            background: #fff;
            box-shadow: 0 12px 32px rgba(23, 32, 51, .08);
        }
        h1 { margin: 0 0 10px; font-size: 1.75rem; }
        p { margin: 0; line-height: 1.6; color: #5b6577; }
        code { color: #2457a6; }
    </style>
</head>
<body>
<main>
    <h1>EduBridge API</h1>
    <p>The backend service is running. API routes are available under <code>/api</code>.</p>
</main>
</body>
</html>
