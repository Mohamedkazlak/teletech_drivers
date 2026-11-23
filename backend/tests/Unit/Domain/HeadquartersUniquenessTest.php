<?php

declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\Exceptions\ActiveHeadquartersExistsException;
use App\Domain\Services\HeadquartersUniqueness;
use PHPUnit\Framework\TestCase;

final class HeadquartersUniquenessTest extends TestCase
{
    public function test_it_allows_first_active_headquarters(): void
    {
        $service = new HeadquartersUniqueness;
        $service->assertCanBecomeHeadquarters(false);
        $this->assertTrue(true);
    }

    public function test_it_rejects_second_active_headquarters(): void
    {
        $service = new HeadquartersUniqueness;

        $this->expectException(ActiveHeadquartersExistsException::class);
        $service->assertCanBecomeHeadquarters(true);
    }
}
