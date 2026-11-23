<?php

declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\Entities\GroupableTripRequest;
use App\Domain\Services\GroupingSuggestionService;
use App\Domain\Services\HaversineDistance;
use DateTimeImmutable;
use DateTimeZone;
use PHPUnit\Framework\TestCase;

final class GroupingSuggestionServiceTest extends TestCase
{
    private GroupingSuggestionService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new GroupingSuggestionService(
            distance: new HaversineDistance,
            radiusMeters: 500.0,
            businessTimezone: 'Africa/Cairo',
        );
    }

    public function test_same_day_same_place_id_clusters(): void
    {
        $day = new DateTimeImmutable('2026-11-04T10:00:00+00:00');
        $a = $this->req('a', $day, 'place-1', null, null, 'Airport');
        $b = $this->req('b', $day->modify('+2 hours'), 'place-1', null, null, 'Airport');

        $result = $this->service->suggest([$a, $b]);

        $this->assertCount(1, $result);
        $this->assertSame(['a', 'b'], $result[0]->requestIds);
        $this->assertSame('2026-11-04', $result[0]->date);
        $this->assertSame(['a', 'b'], array_map(
            static fn ($member): string => $member->requestId,
            $result[0]->members,
        ));
        $this->assertSame('Pickup', $result[0]->members[0]->fromPlace);
        $this->assertSame('Airport', $result[0]->members[0]->toPlace);
    }

    public function test_different_calendar_days_in_cairo_not_clustered(): void
    {
        $cairo = new DateTimeZone('Africa/Cairo');
        $late = new DateTimeImmutable('2026-11-04 23:30:00', $cairo);
        $earlyNext = new DateTimeImmutable('2026-11-05 00:30:00', $cairo);

        $a = $this->req('a', $late->setTimezone(new DateTimeZone('UTC')), 'place-1', null, null, 'Airport');
        $b = $this->req('b', $earlyNext->setTimezone(new DateTimeZone('UTC')), 'place-1', null, null, 'Airport');

        $this->assertSame([], $this->service->suggest([$a, $b]));
    }

    public function test_pair_straddling_utc_midnight_but_same_cairo_day_clusters(): void
    {
        // 2026-11-04 23:30 Cairo = 2026-11-04 21:30 UTC
        // 2026-11-05 01:30 UTC = 2026-11-05 03:30 Cairo (different Cairo day) — use pair still same Cairo day:
        // 21:30 UTC and 22:30 UTC on Nov 4 are both Nov 4 Cairo.
        // Straddle UTC midnight while same Cairo day:
        // Cairo Nov 4 01:30 = Nov 3 23:30 UTC
        // Cairo Nov 4 03:30 = Nov 4 01:30 UTC
        $beforeUtcMidnight = new DateTimeImmutable('2026-11-03T23:30:00+00:00');
        $afterUtcMidnight = new DateTimeImmutable('2026-11-04T01:30:00+00:00');

        $a = $this->req('a', $beforeUtcMidnight, 'place-1', null, null, 'Airport');
        $b = $this->req('b', $afterUtcMidnight, 'place-1', null, null, 'Airport');

        $result = $this->service->suggest([$a, $b]);
        $this->assertCount(1, $result);
        $this->assertSame('2026-11-04', $result[0]->date);
    }

    public function test_custom_pins_within_499m_cluster(): void
    {
        $day = new DateTimeImmutable('2026-11-04T10:00:00+00:00');
        // ~450 m apart near equator approx: 0.004 degrees latitude ≈ 445 m
        $a = $this->req('a', $day, null, 30.0000, 31.0000, 'Pin A', 'HQ');
        $b = $this->req('b', $day, null, 30.0040, 31.0000, 'Pin B', 'Villa');

        $meters = (new HaversineDistance)->meters(30.0000, 31.0000, 30.0040, 31.0000);
        $this->assertLessThan(500, $meters);

        $this->assertCount(1, $this->service->suggest([$a, $b]));
    }

    public function test_custom_pins_at_501m_do_not_cluster(): void
    {
        $day = new DateTimeImmutable('2026-11-04T10:00:00+00:00');
        // ~556 m: 0.005 degrees latitude
        $a = $this->req('a', $day, null, 30.0000, 31.0000, 'Pin A');
        $b = $this->req('b', $day, null, 30.0050, 31.0000, 'Pin B');

        $meters = (new HaversineDistance)->meters(30.0000, 31.0000, 30.0050, 31.0000);
        $this->assertGreaterThan(500, $meters);

        $this->assertSame([], $this->service->suggest([$a, $b]));
    }

    public function test_transitive_clustering(): void
    {
        $day = new DateTimeImmutable('2026-11-04T10:00:00+00:00');
        $a = $this->req('a', $day, null, 30.0000, 31.0000, 'A');
        $b = $this->req('b', $day, null, 30.0030, 31.0000, 'B');
        $c = $this->req('c', $day, null, 30.0060, 31.0000, 'C');

        $result = $this->service->suggest([$a, $b, $c]);
        $this->assertCount(1, $result);
        $this->assertSame(['a', 'b', 'c'], $result[0]->requestIds);
    }

    public function test_singletons_excluded(): void
    {
        $day = new DateTimeImmutable('2026-11-04T10:00:00+00:00');
        $a = $this->req('a', $day, 'place-1', null, null, 'Airport');
        $b = $this->req('b', $day, 'place-2', null, null, 'Other');

        $this->assertSame([], $this->service->suggest([$a, $b]));
    }

    private function req(
        string $id,
        DateTimeImmutable $at,
        ?string $placeId,
        ?float $lat,
        ?float $lng,
        string $destinationName,
        string $pickupName = 'Pickup',
    ): GroupableTripRequest {
        return new GroupableTripRequest(
            id: $id,
            requestedAt: $at,
            destinationPlaceId: $placeId,
            destinationLat: $lat,
            destinationLng: $lng,
            destinationName: $destinationName,
            pickupName: $pickupName,
        );
    }
}
