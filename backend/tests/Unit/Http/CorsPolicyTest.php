<?php

declare(strict_types=1);

namespace Tests\Unit\Http;

use App\Http\Cors\CorsPolicy;
use PHPUnit\Framework\TestCase;

final class CorsPolicyTest extends TestCase
{
    public function test_dev_patterns_allow_localhost_loopback_and_private_lan_on_any_port(): void
    {
        $resolved = CorsPolicy::resolve('local', null, null);

        $this->assertSame(
            ['http://localhost:*', 'http://127.0.0.1:*'],
            $resolved['allowed_origins'],
        );
        $this->assertTrue($this->patternMatches($resolved['allowed_origins_patterns'], 'http://localhost:5173'));
        $this->assertTrue($this->patternMatches($resolved['allowed_origins_patterns'], 'https://localhost'));
        $this->assertTrue($this->patternMatches($resolved['allowed_origins_patterns'], 'http://127.0.0.1:8000'));
        $this->assertTrue($this->patternMatches($resolved['allowed_origins_patterns'], 'https://127.0.0.1'));
        $this->assertTrue($this->patternMatches($resolved['allowed_origins_patterns'], 'http://192.168.1.20:5173'));
        $this->assertTrue($this->patternMatches($resolved['allowed_origins_patterns'], 'https://192.168.0.10'));
        $this->assertTrue($this->patternMatches($resolved['allowed_origins_patterns'], 'http://10.0.2.2:8000'));
        $this->assertTrue($this->patternMatches($resolved['allowed_origins_patterns'], 'http://10.1.2.3'));
        $this->assertTrue($this->patternMatches($resolved['allowed_origins_patterns'], 'http://172.16.0.1'));
        $this->assertTrue($this->patternMatches($resolved['allowed_origins_patterns'], 'http://172.31.255.254:65535'));
        $this->assertFalse($this->patternMatches($resolved['allowed_origins_patterns'], 'http://172.15.255.255:5173'));
        $this->assertFalse($this->patternMatches($resolved['allowed_origins_patterns'], 'http://172.32.0.1'));
        $this->assertFalse($this->patternMatches($resolved['allowed_origins_patterns'], 'http://11.0.0.1:5173'));
        $this->assertFalse($this->patternMatches($resolved['allowed_origins_patterns'], 'http://192.168.256.1'));
        $this->assertFalse($this->patternMatches($resolved['allowed_origins_patterns'], 'http://192.168.1.1.evil.com'));
        $this->assertFalse($this->patternMatches($resolved['allowed_origins_patterns'], 'https://8.8.8.8:5173'));
        $this->assertFalse($this->patternMatches($resolved['allowed_origins_patterns'], 'https://evil.example'));
        $this->assertFalse($this->patternMatches($resolved['allowed_origins_patterns'], 'http://192.168.1.20:5173/api'));
    }

    public function test_explicit_values_replace_the_dev_defaults(): void
    {
        $resolved = CorsPolicy::resolve(
            'local',
            ' https://admin.example.com , http://localhost:5173 ',
            '#^https?://phone\.example(?::\d+)?$#',
        );

        $this->assertSame(
            ['https://admin.example.com', 'http://localhost:5173'],
            $resolved['allowed_origins'],
        );
        $this->assertSame(
            ['#^https?://phone\.example(?::\d+)?$#'],
            $resolved['allowed_origins_patterns'],
        );
    }

    public function test_configured_origins_keep_the_dev_patterns_when_patterns_are_empty(): void
    {
        $resolved = CorsPolicy::resolve('testing', 'http://localhost:5173', '');

        $this->assertSame(['http://localhost:5173'], $resolved['allowed_origins']);
        $this->assertNotEmpty($resolved['allowed_origins_patterns']);
        $this->assertTrue($this->patternMatches($resolved['allowed_origins_patterns'], 'http://192.168.1.8:5173'));
    }

    public function test_production_has_no_dev_defaults_until_origins_are_explicit(): void
    {
        $closed = CorsPolicy::resolve('production', null, null);
        $this->assertSame([], $closed['allowed_origins']);
        $this->assertSame([], $closed['allowed_origins_patterns']);

        $blank = CorsPolicy::resolve('production', '  ', '');
        $this->assertSame([], $blank['allowed_origins']);
        $this->assertSame([], $blank['allowed_origins_patterns']);

        $explicit = CorsPolicy::resolve('production', 'https://admin.example.com', null);
        $this->assertSame(['https://admin.example.com'], $explicit['allowed_origins']);
        $this->assertSame([], $explicit['allowed_origins_patterns']);
    }

    /**
     * @param  list<string>  $patterns
     */
    private function patternMatches(array $patterns, string $origin): bool
    {
        foreach ($patterns as $pattern) {
            if (preg_match($pattern, $origin) === 1) {
                return true;
            }
        }

        return false;
    }
}
