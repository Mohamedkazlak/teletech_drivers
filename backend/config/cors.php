<?php

declare(strict_types=1);

use App\Http\Cors\CorsPolicy;

/*
 * Local and testing environments allow localhost, loopback, and private LAN
 * origins when CORS_ALLOWED_ORIGINS / CORS_ALLOWED_ORIGINS_PATTERNS are empty.
 * Production does not apply that default. Set CORS_ALLOWED_ORIGINS to the real
 * website origin before deploying. A non-empty CORS_ALLOWED_ORIGINS_PATTERNS
 * replaces the local patterns; it is not appended to them.
 */
$rawOrigins = env('CORS_ALLOWED_ORIGINS');
$rawPatterns = env('CORS_ALLOWED_ORIGINS_PATTERNS');

$resolved = CorsPolicy::resolve(
    (string) env('APP_ENV', 'production'),
    is_string($rawOrigins) ? $rawOrigins : null,
    is_string($rawPatterns) ? $rawPatterns : null,
);

return [
    'paths' => ['api/*'],

    'allowed_methods' => ['*'],

    'allowed_origins' => $resolved['allowed_origins'],

    'allowed_origins_patterns' => $resolved['allowed_origins_patterns'],

    'allowed_headers' => [
        'Authorization',
        'Content-Type',
        'Accept',
        'X-Requested-With',
    ],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,
];
