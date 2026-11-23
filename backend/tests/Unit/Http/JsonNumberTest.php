<?php

declare(strict_types=1);

namespace Tests\Unit\Http;

use App\Http\Support\JsonNumber;
use PHPUnit\Framework\TestCase;

final class JsonNumberTest extends TestCase
{
    public function test_reads_string_number_and_null(): void
    {
        $this->assertEqualsWithDelta(30.0444, JsonNumber::orNull('30.0444'), 0.0000001);
        $this->assertIsFloat(JsonNumber::orNull('30.0444'));
        $this->assertSame(31.0, JsonNumber::orNull(31));
        $this->assertSame(31.2, JsonNumber::orNull(31.2));
        $this->assertNull(JsonNumber::orNull(null));
        $this->assertNull(JsonNumber::orNull(''));
        $this->assertNull(JsonNumber::orNull('north'));
    }
}
