<?php

declare(strict_types=1);

namespace Tests\Feature\Cors;

use Tests\TestCase;

final class CorsPreflightTest extends TestCase
{
    private const ORIGINS = 'http://localhost:*,http://127.0.0.1:*';

    protected function setUp(): void
    {
        $this->setAllowedOrigins(self::ORIGINS);

        parent::setUp();
    }

    protected function tearDown(): void
    {
        putenv('CORS_ALLOWED_ORIGINS');
        unset($_ENV['CORS_ALLOWED_ORIGINS'], $_SERVER['CORS_ALLOWED_ORIGINS']);

        parent::tearDown();
    }

    public function test_preflight_allows_a_configured_origin(): void
    {
        $origin = 'http://localhost:54321';

        $response = $this->call('OPTIONS', '/api/auth/login', [], [], [], [
            'HTTP_ORIGIN' => $origin,
            'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST',
            'HTTP_ACCESS_CONTROL_REQUEST_HEADERS' => 'authorization,content-type,accept,x-requested-with',
        ]);

        $response->assertNoContent();
        $response->assertHeader('Access-Control-Allow-Origin', $origin);

        $allowedHeaders = strtolower((string) $response->headers->get('Access-Control-Allow-Headers'));
        $this->assertStringContainsString('authorization', $allowedHeaders);
        $this->assertStringContainsString('content-type', $allowedHeaders);
        $this->assertStringContainsString('accept', $allowedHeaders);
        $this->assertStringContainsString('x-requested-with', $allowedHeaders);
        $this->assertNotSame(
            'true',
            strtolower((string) $response->headers->get('Access-Control-Allow-Credentials')),
        );
    }

    private function setAllowedOrigins(string $value): void
    {
        putenv('CORS_ALLOWED_ORIGINS='.$value);
        $_ENV['CORS_ALLOWED_ORIGINS'] = $value;
        $_SERVER['CORS_ALLOWED_ORIGINS'] = $value;
    }
}
