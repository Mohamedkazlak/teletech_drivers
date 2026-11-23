<?php

declare(strict_types=1);

namespace App\Http\Cors;

/**
 * Resolves browser origins for config/cors.php.
 * Local and testing allow localhost, loopback, and private LAN ranges when the
 * env vars are empty. Production does not: set CORS_ALLOWED_ORIGINS explicitly.
 * A non-empty CORS_ALLOWED_ORIGINS_PATTERNS replaces the dev patterns.
 */
final class CorsPolicy
{
    private const OCTET = '(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)';

    /**
     * @return array{allowed_origins: list<string>, allowed_origins_patterns: list<string>}
     */
    public static function resolve(string $appEnv, ?string $allowedOrigins, ?string $allowedOriginPatterns): array
    {
        $production = $appEnv === 'production';
        $origins = self::split($allowedOrigins);
        if ($origins === [] && ! $production) {
            $origins = ['http://localhost:*', 'http://127.0.0.1:*'];
        }

        $patterns = self::split($allowedOriginPatterns);
        if ($patterns === [] && ! $production) {
            $patterns = self::developmentPatterns();
        }

        return [
            'allowed_origins' => $origins,
            'allowed_origins_patterns' => $patterns,
        ];
    }

    /**
     * @return list<string>
     */
    private static function developmentPatterns(): array
    {
        $octet = self::OCTET;

        return [
            '#^https?://localhost(?::\d+)?$#i',
            '#^https?://127\.0\.0\.1(?::\d+)?$#i',
            '#^https?://192\.168\.'.$octet.'\.'.$octet.'(?::\d+)?$#i',
            '#^https?://10\.'.$octet.'\.'.$octet.'\.'.$octet.'(?::\d+)?$#i',
            '#^https?://172\.(?:1[6-9]|2\d|3[0-1])\.'.$octet.'\.'.$octet.'(?::\d+)?$#i',
        ];
    }

    /**
     * @return list<string>
     */
    private static function split(?string $value): array
    {
        if ($value === null || trim($value) === '') {
            return [];
        }

        $parts = array_map(
            static fn (string $part): string => trim($part),
            explode(',', $value),
        );

        return array_values(array_filter(
            $parts,
            static fn (string $part): bool => $part !== '',
        ));
    }
}
