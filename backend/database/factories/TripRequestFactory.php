<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\UserRole;
use App\Models\TripRequest;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<TripRequest>
 */
final class TripRequestFactory extends Factory
{
    protected $model = TripRequest::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'employee_id' => User::factory()->employee(),
            'requester_role' => UserRole::Employee,
            'pickup_place_id' => null,
            'pickup_name' => 'Pickup',
            'pickup_lat' => 30.0444,
            'pickup_lng' => 31.2357,
            'pickup_address' => null,
            'destination_place_id' => null,
            'destination_name' => 'Destination',
            'destination_lat' => 30.0500,
            'destination_lng' => 31.2400,
            'destination_address' => null,
            'requested_at' => now()->addDay(),
            'notes' => '',
            'status' => TripRequestStatus::Pending,
            'trip_id' => null,
            'rejection_reason' => null,
            'handled_by' => null,
            'handled_at' => null,
            'auto_approved' => false,
            'suggested_group_id' => null,
        ];
    }

    public function pending(): static
    {
        return $this->state(fn (): array => [
            'status' => TripRequestStatus::Pending,
            'auto_approved' => false,
        ]);
    }

    public function approved(): static
    {
        return $this->state(fn (): array => [
            'status' => TripRequestStatus::Approved,
            'auto_approved' => false,
            'handled_at' => now(),
            'approved_at' => now(),
        ]);
    }
}
