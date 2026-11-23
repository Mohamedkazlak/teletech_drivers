<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Places;

use App\Application\Places\Actions\CreatePlaceAction;
use App\Application\Places\DTOs\CreatePlaceData;
use App\Domain\Exceptions\ActiveHeadquartersExistsException;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakePlaceRepository;

final class CreatePlaceActionTest extends TestCase
{
    public function test_it_creates_a_place(): void
    {
        $places = new FakePlaceRepository;
        $action = new CreatePlaceAction($places);

        $place = $action->execute(new CreatePlaceData(
            nameEn: 'HQ',
            nameAr: 'مقر',
            latitude: 30.0,
            longitude: 31.0,
            address: 'Cairo',
            isHeadquarters: true,
            isActive: true,
        ));

        $this->assertSame('HQ', $place->nameEn);
        $this->assertTrue($place->isHeadquarters);
    }

    public function test_it_rejects_second_active_headquarters(): void
    {
        $places = new FakePlaceRepository;
        $action = new CreatePlaceAction($places);

        $action->execute(new CreatePlaceData(
            nameEn: 'HQ1',
            nameAr: '١',
            latitude: null,
            longitude: null,
            address: null,
            isHeadquarters: true,
            isActive: true,
        ));

        $this->expectException(ActiveHeadquartersExistsException::class);

        $action->execute(new CreatePlaceData(
            nameEn: 'HQ2',
            nameAr: '٢',
            latitude: null,
            longitude: null,
            address: null,
            isHeadquarters: true,
            isActive: true,
        ));
    }
}
