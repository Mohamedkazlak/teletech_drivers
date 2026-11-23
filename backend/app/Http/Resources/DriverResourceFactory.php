<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\Driver;
use App\Domain\Entities\DriverStats;
use App\Domain\Enums\UserRole;
use App\Models\User;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Gate;

/**
 * Selects DriverResource vs DriverSummaryResource via UserPolicy.
 */
final class DriverResourceFactory
{
    public function make(
        Driver $driver,
        User $actor,
        ?DriverStats $totals = null,
        ?int $tripsThisWeek = null,
    ): JsonResource {
        $target = $this->policyTarget($driver);

        if (Gate::forUser($actor)->allows('viewPrivateDriverFields', $target)) {
            return new DriverResource($driver, $totals, $tripsThisWeek);
        }

        return new DriverSummaryResource($driver, $totals, $tripsThisWeek);
    }

    /**
     * @param  list<Driver>  $drivers
     * @param  array<string, int>  $tripsThisWeek
     * @return list<JsonResource>
     */
    public function makeMany(
        array $drivers,
        User $actor,
        array $tripsThisWeek = [],
    ): array {
        return array_map(
            fn (Driver $driver): JsonResource => $this->make(
                $driver,
                $actor,
                tripsThisWeek: $tripsThisWeek[$driver->user->id] ?? null,
            ),
            $drivers,
        );
    }

    private function policyTarget(Driver $driver): User
    {
        $target = new User;
        $target->forceFill([
            'id' => $driver->user->id,
            'role' => UserRole::Driver,
        ]);

        return $target;
    }
}
