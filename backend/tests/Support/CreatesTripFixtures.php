<?php

declare(strict_types=1);

namespace Tests\Support;

use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Place;
use App\Models\Trip;
use App\Models\TripRequest;
use App\Models\User;
use DateTimeImmutable;

trait CreatesTripFixtures
{
    protected function createActivePlace(string $name = 'HQ'): Place
    {
        return Place::factory()->create([
            'name_en' => $name,
            'name_ar' => $name,
            'latitude' => 30.0444,
            'longitude' => 31.2357,
            'is_active' => true,
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    protected function tripRequestPayload(?Place $pickup = null, ?Place $destination = null): array
    {
        $pickup ??= $this->createActivePlace('Pickup');
        $destination ??= $this->createActivePlace('Destination');

        return [
            'pickup' => ['place_id' => $pickup->id],
            'destination' => ['place_id' => $destination->id],
            'requested_at' => (new DateTimeImmutable('+2 days'))->format(DATE_ATOM),
            'notes' => 'please',
        ];
    }

    protected function createPendingRequest(User $employee): TripRequest
    {
        $pickup = $this->createActivePlace('P');
        $destination = $this->createActivePlace('D');

        return TripRequest::factory()->pending()->create([
            'employee_id' => $employee->id,
            'requester_role' => UserRole::Employee,
            'pickup_place_id' => $pickup->id,
            'pickup_name' => $pickup->name_en,
            'pickup_lat' => $pickup->latitude,
            'pickup_lng' => $pickup->longitude,
            'destination_place_id' => $destination->id,
            'destination_name' => $destination->name_en,
            'destination_lat' => $destination->latitude,
            'destination_lng' => $destination->longitude,
            'status' => TripRequestStatus::Pending,
        ]);
    }

    protected function createApprovedUnlinkedRequest(User $employee): TripRequest
    {
        $request = $this->createPendingRequest($employee);
        $request->status = TripRequestStatus::Approved;
        $request->handled_by = $employee->id;
        $request->handled_at = now();
        $request->save();

        return $request->fresh();
    }

    protected function createUnassignedTrip(User $createdBy): Trip
    {
        return Trip::factory()->unassigned()->create([
            'created_by' => $createdBy->id,
            'status' => TripStatus::Unassigned,
            'going_route' => 'SECRET_GOING',
            'return_route' => 'SECRET_RETURN',
            'start_lat' => 30.1,
            'start_lng' => 31.1,
        ]);
    }
}
