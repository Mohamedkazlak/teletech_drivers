<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\RequestTracking;
use App\Domain\Entities\Trip;
use App\Domain\Entities\TripPassenger;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Trip without going_route, return_route, start_lat/lng (company_admin / admin).
 *
 * @mixin Trip
 */
final class TripSummaryResource extends JsonResource
{
    public function __construct(
        mixed $resource,
        protected readonly ?string $viewerId = null,
        protected readonly bool $limitToViewer = false,
    ) {
        parent::__construct($resource);
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var Trip $trip */
        $trip = $this->resource;

        return $this->fields($trip);
    }

    /**
     * @return array<string, mixed>
     */
    protected function fields(Trip $trip): array
    {
        $tracking = $this->viewerId !== null
            ? ($trip->trackingByEmployeeId[$this->viewerId] ?? null)
            : null;

        return self::baseFields(
            $trip,
            $tracking,
            $this->limitToViewer ? $this->viewerId : null,
        );
    }

    /**
     * @return array<string, mixed>
     */
    public static function baseFields(
        Trip $trip,
        ?RequestTracking $tracking = null,
        ?string $onlyEmployeeId = null,
    ): array {
        $passengers = $trip->passengers;
        if ($onlyEmployeeId !== null) {
            $passengers = array_values(array_filter(
                $passengers,
                static fn (TripPassenger $passenger): bool => $passenger->employeeId === $onlyEmployeeId,
            ));
        }

        $note = $trip->confirmationNote;
        if ($onlyEmployeeId !== null
            && $trip->confirmedBy !== null
            && $trip->confirmedBy !== $onlyEmployeeId) {
            $note = null;
        }

        $scoped = new Trip(
            id: $trip->id,
            driverId: $trip->driverId,
            scheduledAt: $trip->scheduledAt,
            status: $trip->status,
            createdBy: $trip->createdBy,
            pickupSummary: $trip->pickupSummary,
            destinationSummary: $trip->destinationSummary,
            goingStartedAt: $trip->goingStartedAt,
            goingEndedAt: $trip->goingEndedAt,
            returnStartedAt: $trip->returnStartedAt,
            finishedAt: $trip->finishedAt,
            startLat: $trip->startLat,
            startLng: $trip->startLng,
            goingDistanceM: $trip->goingDistanceM,
            returnDistanceM: $trip->returnDistanceM,
            totalDistanceM: $trip->totalDistanceM,
            goingRoute: $trip->goingRoute,
            returnRoute: $trip->returnRoute,
            createdAt: $trip->createdAt,
            passengers: $passengers,
            driver: $trip->driver,
            confirmationStatus: $trip->confirmationStatus,
            confirmationRequestedAt: $trip->confirmationRequestedAt,
            confirmedAt: $trip->confirmedAt,
            confirmedBy: $trip->confirmedBy,
            driverShowedUp: $trip->driverShowedUp,
            confirmationNote: $note,
        );

        return [
            'id' => $scoped->id,
            'driver_id' => $scoped->driverId,
            'driver' => $scoped->driver !== null
                ? (new DriverSummaryResource($scoped->driver))->resolve()
                : null,
            'scheduled_at' => $scoped->scheduledAt->format(DATE_ATOM),
            'status' => $scoped->status->value,
            'created_by' => $scoped->createdBy,
            'pickup_summary' => $scoped->pickupSummary,
            'destination_summary' => $scoped->destinationSummary,
            'going_started_at' => $scoped->goingStartedAt?->format(DATE_ATOM),
            'going_ended_at' => $scoped->goingEndedAt?->format(DATE_ATOM),
            'return_started_at' => $scoped->returnStartedAt?->format(DATE_ATOM),
            'finished_at' => $scoped->finishedAt?->format(DATE_ATOM),
            'going_distance_m' => $scoped->goingDistanceM,
            'return_distance_m' => $scoped->returnDistanceM,
            'total_distance_m' => $scoped->totalDistanceM,
            'confirmation_status' => $scoped->confirmationStatus?->value,
            'confirmation_requested_at' => $scoped->confirmationRequestedAt?->format(DATE_ATOM),
            'confirmed_at' => $scoped->confirmedAt?->format(DATE_ATOM),
            'driver_showed_up' => $scoped->driverShowedUp,
            'confirmation_note' => $scoped->confirmationNote,
            'passengers' => array_map(
                static fn ($passenger): array => (new TripPassengerResource($passenger))->resolve(),
                $scoped->passengers,
            ),
            'passengers_branches' => self::passengerBranches($scoped),
            'requester' => self::requester($scoped),
            'requesters' => array_map(
                static fn (TripPassenger $passenger): array => (new TripRequesterResource($passenger))->resolve(),
                $scoped->passengers,
            ),
            'passenger_count' => $trip->passengerCount(),
            'created_at' => $scoped->createdAt->format(DATE_ATOM),
            'tracking' => $tracking !== null ? RequestTrackingResource::make($tracking) : null,
        ];
    }

    /**
     * First linked requester, for the single-request trip card.
     * Grouped trips list every entry in requesters. Null when the trip has none.
     *
     * @return array<string, mixed>|null
     */
    private static function requester(Trip $trip): ?array
    {
        $first = $trip->passengers[0] ?? null;
        if ($first === null) {
            return null;
        }

        return (new TripRequesterResource($first))->resolve();
    }

    /**
     * Unique passenger branches, alphabetical, omitting passengers with no branch.
     *
     * @return list<string>
     */
    private static function passengerBranches(Trip $trip): array
    {
        $branches = [];
        foreach ($trip->passengers as $passenger) {
            if ($passenger->branch === null || $passenger->branch === '') {
                continue;
            }
            $branches[$passenger->branch] = $passenger->branch;
        }

        $values = array_values($branches);
        sort($values);

        return $values;
    }
}
