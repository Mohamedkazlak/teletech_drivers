<?php

declare(strict_types=1);

namespace Tests\Feature\Cors;

use Illuminate\Support\Env;
use Illuminate\Support\Facades\Facade;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

final class CorsOriginPatternsTest extends TestCase
{
    protected function setUp(): void
    {
        $this->putEnv('APP_ENV', 'testing');
        $this->putEnv('CORS_ALLOWED_ORIGINS', '');
        $this->putEnv('CORS_ALLOWED_ORIGINS_PATTERNS', '');

        parent::setUp();
    }

    protected function tearDown(): void
    {
        $this->putEnv('APP_ENV', 'testing');
        $this->clearEnv('CORS_ALLOWED_ORIGINS');
        $this->clearEnv('CORS_ALLOWED_ORIGINS_PATTERNS');

        parent::tearDown();
    }

    public function test_dev_default_reflects_private_origins_and_rejects_public_ones(): void
    {
        $this->assertNotEmpty(config('cors.allowed_origins_patterns'));

        foreach ([
            'http://192.168.1.20:5173',
            'https://10.0.2.2:8000',
            'http://172.16.0.1',
            'http://172.31.255.254:5173',
            'https://127.0.0.1:9999',
            'https://localhost:5173',
        ] as $origin) {
            $this->preflight($origin)->assertHeader('Access-Control-Allow-Origin', $origin);
        }

        foreach ([
            'http://172.15.1.1:5173',
            'http://172.32.0.1',
            'https://8.8.8.8:5173',
            'https://app.example.com',
        ] as $origin) {
            $this->assertFalse(
                $this->preflight($origin)->headers->has('Access-Control-Allow-Origin'),
                $origin,
            );
        }
    }

    public function test_explicit_pattern_replaces_the_dev_default(): void
    {
        $this->putEnv('CORS_ALLOWED_ORIGINS_PATTERNS', '#^https?://phone\.example(?::\d+)?$#i');
        $this->refreshApplication();
        Facade::clearResolvedInstances();

        $this->preflight('https://phone.example:5173')
            ->assertHeader('Access-Control-Allow-Origin', 'https://phone.example:5173');
        $this->assertFalse(
            $this->preflight('http://192.168.1.5:5173')->headers->has('Access-Control-Allow-Origin'),
        );
    }

    public function test_production_rejects_lan_until_explicit_origins_are_set(): void
    {
        $this->putEnv('APP_ENV', 'production');
        $this->putEnv('CORS_ALLOWED_ORIGINS', '');
        $this->putEnv('CORS_ALLOWED_ORIGINS_PATTERNS', '');
        $this->refreshApplication();
        Facade::clearResolvedInstances();

        $this->assertSame([], config('cors.allowed_origins'));
        $this->assertSame([], config('cors.allowed_origins_patterns'));
        $this->assertFalse(
            $this->preflight('http://192.168.1.20:5173')->headers->has('Access-Control-Allow-Origin'),
        );
        $this->assertFalse(
            $this->preflight('http://localhost:5173')->headers->has('Access-Control-Allow-Origin'),
        );

        $this->putEnv('CORS_ALLOWED_ORIGINS', 'https://admin.example.com,https://www.example.com');
        $this->refreshApplication();
        Facade::clearResolvedInstances();

        $this->assertSame([], config('cors.allowed_origins_patterns'));
        $this->preflight('https://admin.example.com')
            ->assertHeader('Access-Control-Allow-Origin', 'https://admin.example.com');
        $this->assertFalse(
            $this->preflight('http://10.1.2.3:5173')->headers->has('Access-Control-Allow-Origin'),
        );
    }

    private function preflight(string $origin): TestResponse
    {
        return $this->call('OPTIONS', '/api/auth/login', [], [], [], [
            'HTTP_ORIGIN' => $origin,
            'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST',
            'HTTP_ACCESS_CONTROL_REQUEST_HEADERS' => 'authorization,content-type,accept',
        ]);
    }

    private function putEnv(string $key, string $value): void
    {
        // The dotenv repository is process-wide and immutable. Variables it has
        // already loaded from .env are written again on the next boot, which
        // would undo this override. Drop the repository first so the new value
        // counts as an existing variable and .env leaves it alone.
        Env::enablePutenv();
        putenv($key.'='.$value);
        $_ENV[$key] = $value;
        $_SERVER[$key] = $value;
    }

    private function clearEnv(string $key): void
    {
        Env::enablePutenv();
        putenv($key);
        unset($_ENV[$key], $_SERVER[$key]);
    }
}
