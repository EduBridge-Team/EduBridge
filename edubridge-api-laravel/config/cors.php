<?php

return [
    'paths' => ['api/*'],
    'allowed_methods' => ['*'],
    'allowed_origins' => [
        'https://edubridge.win',
        'https://www.edubridge.win',
        'https://edubridge.apps.taqat.academy',
        'https://edubridge.alwaysdata.net',
    ],
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => false,
];
