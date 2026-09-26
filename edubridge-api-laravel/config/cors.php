<?php

return [
    'paths' => ['api/*'],
    'allowed_methods' => ['*'],
    'allowed_origins' => [
        'https://edubridge.win',
        'https://www.edubridge.win',
    ],
    'allowed_origins_patterns' => [
        '#^http://localhost:[0-9]+$#',
        '#^http://127[.]0[.]0[.]1:[0-9]+$#',
    ],
    'allowed_headers' => ['*'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => false,
];
