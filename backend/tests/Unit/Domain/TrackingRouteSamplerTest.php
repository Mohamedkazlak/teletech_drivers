<?php

declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\Entities\TrackingPoint;
use App\Domain\Services\TrackingRouteSampler;
use DateTimeImmutable;
use PHPUnit\Framework\TestCase;

final class TrackingRouteSamplerTest extends TestCase
{
    public function test_caps_a_route_at_500_and_keeps_both_ends(): void
    {
        $points = [];
        for ($i = 0; $i < 800; $i++) {
            $points[] = new TrackingPoint(
                lat: 30 + ($i / 1000),
                lng: 31 + ($i / 1000),
                recordedAt: (new DateTimeImmutable('2026-11-10T08:00:00Z'))->modify('+'.$i.' seconds'),
            );
        }

        $sampled = (new TrackingRouteSampler)->cap($points);

        $this->assertCount(TrackingRouteSampler::MAX_POINTS, $sampled);
        $this->assertSame($points[0]->lat, $sampled[0]->lat);
        $this->assertSame($points[799]->recordedAt->format(DATE_ATOM), $sampled[array_key_last($sampled)]->recordedAt->format(DATE_ATOM));
    }

    public function test_short_routes_are_unchanged(): void
    {
        $point = new TrackingPoint(30.0, 31.0, new DateTimeImmutable('2026-11-10T08:00:00Z'));

        $this->assertSame([], (new TrackingRouteSampler)->cap([]));
        $this->assertSame([$point], (new TrackingRouteSampler)->cap([$point]));
    }
}
