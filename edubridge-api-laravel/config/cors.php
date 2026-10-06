<?php

$allowLocalOrigins = in_array(env('APP_ENV', 'production'), ['local', 'testing'], true);

return [
    'paths' => ['api/*'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    'allowed_origins' => [
        'https://edubridge.win',
        'https://www.edubridge.win',
    ],
    'allowed_origins_patterns' => $allowLocalOrigins ? [
        '#^http://localhost:[0-9]+$#',
        '#^http://127[.]0[.]1:[0-9]+$#',
    ] : [],
    'allowed_headers' => [
        'Accept',
        'Authorization',
        'Content-Type',
        'Origin',
        'X-Requested-With',
        'X-CSRF-TOKEN',
        'X-EduBridge-Client',
    ],
    'exposed_headers' => [],
    'max_age' => 600,
    'supports_credentials' => false,
];
