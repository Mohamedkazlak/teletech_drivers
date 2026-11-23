<?php

declare(strict_types=1);

namespace App\Domain\Services\TripRequest;

/**
 * Strategy: role-specific create behavior (pending vs approved vs + trip).
 */
interface CreateTripRequestStrategy
{
    public function build(): CreateTripRequestPlan;
}
