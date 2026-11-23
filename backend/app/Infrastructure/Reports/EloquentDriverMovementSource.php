<?php

declare(strict_types=1);

namespace App\Infrastructure\Reports;

use App\Domain\Entities\AvailabilityPresence;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Reports\MovementTripStop;
use App\Models\AttendanceLog;
use App\Models\Place;
use App\Models\Trip;
use DateTimeImmutable;

/** Loads completed trips and attendance check-in/out for one driver and a UTC window. */
final class EloquentDriverMovementSource
{
    /**
     * @return list<MovementTripStop>
     */
    public function trips(string $driverId, DateTimeImmutable $start, DateTimeImmutable $end): array
    {
        $models = Trip::query()
            ->where('driver_id', $driverId)
            ->where('status', TripStatus::Completed->value)
            ->where(function ($query): void {
                $query->where('driver_showed_up', true)->orWhereNull('driver_showed_up');
            })
            ->where(function ($query) use ($start, $end): void {
                $query->where(function ($inner) use ($start, $end): void {
                    $inner->where('going_started_at', '>=', $start)
                        ->where('going_started_at', '<', $end);
                })->orWhere(function ($inner) use ($start, $end): void {
                    $inner->where('finished_at', '>=', $start)
                        ->where('finished_at', '<', $end);
                });
            })
            ->with([
                'tripRequests' => function ($query): void {
                    $query->with([
                        'pickupPlace' => static fn ($place) => $place->withTrashed(),
                        'destinationPlace' => static fn ($place) => $place->withTrashed(),
                    ]);
                },
            ])
            ->orderBy('going_started_at')
            ->orderBy('finished_at')
            ->get();

        $stops = [];
        foreach ($models as $trip) {
            $from = [];
            $to = [];
            foreach ($trip->tripRequests as $request) {
                $from[] = $this->placeName($request->pickupPlace, $request->pickup_name);
                $to[] = $this->placeName($request->destinationPlace, $request->destination_name);
            }
            $started = $trip->going_started_at;
            $finished = $trip->finished_at;
            $stops[] = new MovementTripStop(
                startedAt: $started === null ? null : DateTimeImmutable::createFromInterface($started),
                finishedAt: $finished === null ? null : DateTimeImmutable::createFromInterface($finished),
                fromNames: $from,
                toNames: $to,
            );
        }

        return $stops;
    }

    /**
     * @return list<AvailabilityPresence>
     */
    public function presence(string $driverId, DateTimeImmutable $start, DateTimeImmutable $end): array
    {
        $events = [];
        $rows = AttendanceLog::query()
            ->where('driver_id', $driverId)
            ->where(function ($query) use ($start, $end): void {
                $query->where(function ($inner) use ($start, $end): void {
                    $inner->where('checked_in_at', '>=', $start)
                        ->where('checked_in_at', '<', $end);
                })->orWhere(function ($inner) use ($start, $end): void {
                    $inner->where('checked_out_at', '>=', $start)
                        ->where('checked_out_at', '<', $end);
                });
            })
            ->get(['driver_id', 'checked_in_at', 'checked_out_at']);

        foreach ($rows as $row) {
            if ($row->checked_in_at !== null) {
                $events[] = new AvailabilityPresence(
                    driverId: (string) $row->driver_id,
                    status: AvailabilityStatus::Available,
                    requestedAt: DateTimeImmutable::createFromInterface($row->checked_in_at),
                );
            }
            if ($row->checked_out_at !== null) {
                $events[] = new AvailabilityPresence(
                    driverId: (string) $row->driver_id,
                    status: AvailabilityStatus::FinishedToday,
                    requestedAt: DateTimeImmutable::createFromInterface($row->checked_out_at),
                );
            }
        }

        return $events;
    }

    private function placeName(?Place $place, ?string $fallback): string
    {
        $arabic = trim((string) ($place->name_ar ?? ''));
        if ($arabic !== '') {
            return $arabic;
        }

        return trim((string) $fallback);
    }
}
