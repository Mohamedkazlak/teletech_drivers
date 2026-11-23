<?php

declare(strict_types=1);

namespace App\Domain\Services;

use App\Domain\Entities\GroupableTripRequest;
use App\Domain\Entities\GroupSuggestion;
use App\Domain\Entities\GroupSuggestionMember;
use DateTimeImmutable;
use DateTimeZone;

/**
 * Domain service: clusters requests that share a destination on the same
 * calendar day (business timezone) via union-find.
 */
final class GroupingSuggestionService
{
    public const DEFAULT_RADIUS_METERS = 500.0;

    public function __construct(
        private readonly HaversineDistance $distance = new HaversineDistance,
        private readonly float $radiusMeters = self::DEFAULT_RADIUS_METERS,
        private readonly string $businessTimezone = 'Africa/Cairo',
    ) {}

    /**
     * @param  list<GroupableTripRequest>  $requests
     * @return list<GroupSuggestion>
     */
    public function suggest(array $requests): array
    {
        $count = count($requests);
        if ($count < 2) {
            return [];
        }

        $parent = range(0, $count - 1);

        $find = function (int $i) use (&$parent, &$find): int {
            while ($parent[$i] !== $i) {
                $parent[$i] = $parent[$parent[$i]];
                $i = $parent[$i];
            }

            return $i;
        };

        $union = function (int $a, int $b) use (&$parent, $find): void {
            $ra = $find($a);
            $rb = $find($b);
            if ($ra !== $rb) {
                $parent[$rb] = $ra;
            }
        };

        for ($i = 0; $i < $count; $i++) {
            for ($j = $i + 1; $j < $count; $j++) {
                if ($this->areSimilar($requests[$i], $requests[$j])) {
                    $union($i, $j);
                }
            }
        }

        /** @var array<int, list<GroupableTripRequest>> $clusters */
        $clusters = [];
        for ($i = 0; $i < $count; $i++) {
            $root = $find($i);
            $clusters[$root][] = $requests[$i];
        }

        $suggestions = [];
        foreach ($clusters as $members) {
            if (count($members) < 2) {
                continue;
            }

            usort(
                $members,
                static fn (GroupableTripRequest $a, GroupableTripRequest $b): int => $a->requestedAt <=> $b->requestedAt,
            );

            $ids = array_map(static fn (GroupableTripRequest $r): string => $r->id, $members);
            sort($ids);

            $suggestions[] = new GroupSuggestion(
                clusterId: $this->stableClusterId($ids),
                requestIds: array_values($ids),
                destinationLabel: $members[0]->destinationName,
                routeLabel: $this->routeLabel($members),
                date: $this->calendarDate($members[0]->requestedAt),
                earliestRequestedAt: $members[0]->requestedAt,
                latestRequestedAt: $members[array_key_last($members)]->requestedAt,
                members: array_map(
                    static fn (GroupableTripRequest $request): GroupSuggestionMember => new GroupSuggestionMember(
                        requestId: $request->id,
                        requesterNameEn: $request->requesterNameEn,
                        requesterNameAr: $request->requesterNameAr,
                        branch: $request->branch,
                        fromPlace: $request->pickupName,
                        toPlace: $request->destinationName,
                        requestedAt: $request->requestedAt,
                    ),
                    $members,
                ),
            );
        }

        usort(
            $suggestions,
            static fn (GroupSuggestion $a, GroupSuggestion $b): int => $a->earliestRequestedAt <=> $b->earliestRequestedAt,
        );

        return $suggestions;
    }

    private function areSimilar(GroupableTripRequest $a, GroupableTripRequest $b): bool
    {
        if ($this->calendarDate($a->requestedAt) !== $this->calendarDate($b->requestedAt)) {
            return false;
        }

        return $this->samePlace(
            $a->destinationPlaceId,
            $a->destinationLat,
            $a->destinationLng,
            $b->destinationPlaceId,
            $b->destinationLat,
            $b->destinationLng,
        );
    }

    private function samePlace(
        ?string $placeIdA,
        ?float $latA,
        ?float $lngA,
        ?string $placeIdB,
        ?float $latB,
        ?float $lngB,
    ): bool {
        if ($placeIdA !== null && $placeIdA !== '' && $placeIdA === $placeIdB) {
            return true;
        }

        $customA = $placeIdA === null || $placeIdA === '';
        $customB = $placeIdB === null || $placeIdB === '';
        if (! $customA || ! $customB) {
            return false;
        }

        if ($latA === null || $lngA === null || $latB === null || $lngB === null) {
            return false;
        }

        return $this->distance->meters($latA, $lngA, $latB, $lngB) <= $this->radiusMeters;
    }

    /**
     * @param  list<GroupableTripRequest>  $members
     */
    private function routeLabel(array $members): string
    {
        $destination = $members[0]->destinationName;
        $pickups = [];
        foreach ($members as $member) {
            $pickups[$member->pickupName] = true;
        }

        if (count($pickups) === 1) {
            return array_key_first($pickups).' → '.$destination;
        }

        return $destination;
    }

    /**
     * @param  list<string>  $sortedIds
     */
    private function stableClusterId(array $sortedIds): string
    {
        $joined = implode('|', $sortedIds);
        if (strlen($joined) <= 120) {
            return 'sg_'.$joined;
        }

        $hash = 2166136261;
        $length = strlen($joined);
        for ($i = 0; $i < $length; $i++) {
            $hash ^= ord($joined[$i]);
            $hash = ($hash * 16777619) & 0xFFFFFFFF;
        }

        return 'sg_'.dechex($hash);
    }

    private function calendarDate(DateTimeImmutable $at): string
    {
        $local = $at->setTimezone(new DateTimeZone($this->businessTimezone));

        return $local->format('Y-m-d');
    }
}
