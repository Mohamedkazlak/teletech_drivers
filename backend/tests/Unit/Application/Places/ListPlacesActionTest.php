<?php

declare(strict_types=1);

namespace Tests\Unit\Application\Places;

use App\Application\Places\Actions\ListPlacesAction;
use App\Application\Places\DTOs\ListPlacesData;
use App\Domain\Entities\Place;
use PHPUnit\Framework\TestCase;
use Tests\Support\FakePlaceRepository;

final class ListPlacesActionTest extends TestCase
{
    public function test_it_filters_by_search(): void
    {
        $places = new FakePlaceRepository;
        $places->seed(new Place('1', 'Cairo HQ', 'القاهرة', null, null, null, true, true));
        $places->seed(new Place('2', 'Alexandria', 'الإسكندرية', null, null, null, false, true));

        $action = new ListPlacesAction($places);
        $result = $action->execute(new ListPlacesData(
            isActive: null,
            search: 'Cairo',
            isHeadquarters: null,
        ));

        $this->assertSame(1, $result->total);
        $this->assertSame('Cairo HQ', $result->items[0]->nameEn);
    }
}
