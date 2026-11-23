<?php

declare(strict_types=1);

namespace Tests\Unit\Http;

use App\Domain\Entities\Place;
use App\Http\Resources\PlaceResource;
use Tests\TestCase;

final class PlaceResourceCoordinateTest extends TestCase
{
    public function test_place_resource_coordinates_are_json_numbers(): void
    {
        $present = (new PlaceResource(new Place(
            id: 'place-1',
            nameEn: 'HQ',
            nameAr: 'المقر',
            latitude: 30.0444,
            longitude: 31.2357,
            address: null,
            isHeadquarters: true,
            isActive: true,
        )))->resolve();

        $this->assertIsFloat($present['latitude']);
        $this->assertIsFloat($present['longitude']);
        $decoded = json_decode((string) json_encode($present['latitude']));
        $this->assertIsFloat($decoded);
        $this->assertEqualsWithDelta(30.0444, $decoded, 0.0000001);

        $missing = (new PlaceResource(new Place(
            id: 'place-2',
            nameEn: 'Site',
            nameAr: 'موقع',
            latitude: null,
            longitude: null,
            address: null,
            isHeadquarters: false,
            isActive: true,
        )))->resolve();

        $this->assertNull($missing['latitude']);
        $this->assertNull($missing['longitude']);
    }
}
