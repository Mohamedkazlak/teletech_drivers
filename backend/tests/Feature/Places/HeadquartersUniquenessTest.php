<?php

declare(strict_types=1);

namespace Tests\Feature\Places;

use App\Domain\Exceptions\ActiveHeadquartersExistsException;
use App\Domain\Repositories\PlaceRepositoryInterface;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class HeadquartersUniquenessTest extends TestCase
{
    use RefreshDatabase;

    public function test_only_one_active_headquarters_is_allowed(): void
    {
        /** @var PlaceRepositoryInterface $places */
        $places = $this->app->make(PlaceRepositoryInterface::class);

        $places->create(
            nameEn: 'HQ One',
            nameAr: 'مقر ١',
            latitude: 30.0,
            longitude: 31.0,
            address: 'Cairo',
            isHeadquarters: true,
            isActive: true,
        );

        $this->expectException(ActiveHeadquartersExistsException::class);

        $places->create(
            nameEn: 'HQ Two',
            nameAr: 'مقر ٢',
            latitude: 30.1,
            longitude: 31.1,
            address: 'Giza',
            isHeadquarters: true,
            isActive: true,
        );
    }
}
