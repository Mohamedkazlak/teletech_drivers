<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Places;

use App\Application\Places\Actions\GetPlaceAction;
use App\Domain\Entities\Place;
use App\Domain\Exceptions\PlaceNotFoundException;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakePlaceRepository;

final class GetPlaceActionTest extends TestCase
{
    public function test_it_returns_place(): void
    {
        $places = new FakePlaceRepository;
        $places->seed(new Place('1', 'HQ', 'مقر', null, null, null, true, true));

        $place = (new GetPlaceAction($places))->execute('1');

        $this->assertSame('HQ', $place->nameEn);
    }

    public function test_it_throws_when_missing(): void
    {
        $this->expectException(PlaceNotFoundException::class);
        (new GetPlaceAction(new FakePlaceRepository))->execute('missing');
    }
}
