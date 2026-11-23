<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Places;

use App\Application\Places\Actions\UpdatePlaceAction;
use App\Application\Places\DTOs\UpdatePlaceData;
use App\Domain\Entities\Place;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakePlaceRepository;

final class UpdatePlaceActionTest extends TestCase
{
    public function test_it_updates_a_place_and_allows_deactivating_hq(): void
    {
        $places = new FakePlaceRepository;
        $places->seed(new Place(
            id: 'place-1',
            nameEn: 'HQ',
            nameAr: 'مقر',
            latitude: 30.0,
            longitude: 31.0,
            address: 'Cairo',
            isHeadquarters: true,
            isActive: true,
        ));

        $action = new UpdatePlaceAction($places);

        $updated = $action->execute(new UpdatePlaceData(
            id: 'place-1',
            nameEn: 'HQ Off',
            nameAr: 'مقر',
            latitude: 30.0,
            longitude: 31.0,
            address: 'Cairo',
            isHeadquarters: true,
            isActive: false,
        ));

        $this->assertFalse($updated->isActive);
        $this->assertSame('HQ Off', $updated->nameEn);
    }
}
