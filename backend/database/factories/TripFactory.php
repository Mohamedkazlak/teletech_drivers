<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Domain\Enums\TripStatus;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Trip>
 */
final class TripFactory extends Factory
{
    protected $model = Trip::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'driver_id' => null,
            'scheduled_at' => now()->addDay(),
            'status' => TripStatus::Unassigned,
            'created_by' => User::factory()->driversAdmin(),
            'pickup_summary' => 'Pickup',
            'destination_summary' => 'Destination',
            'going_started_at' => null,
            'going_ended_at' => null,
            'return_started_at' => null,
            'finished_at' => null,
            'start_lat' => null,
            'start_lng' => null,
            'going_distance_m' => null,
            'return_distance_m' => null,
            'total_distance_m' => null,
            'going_route' => null,
            'return_route' => null,
        ];
    }

    public function unassigned(): static
    {
        return $this->state(fn (): array => [
            'status' => TripStatus::Unassigned,
            'driver_id' => null,
        ]);
    }

    public function assigned(): static
    {
        return $this->state(fn (): array => [
            'status' => TripStatus::Assigned,
        ]);
    }
}
