<?php

declare(strict_types=1);

namespace App\Application\TripRequests\DTOs;

final readonly class ApproveGroupTripRequestsData
{
    /**
     * @param  list<string>  $requestIds
     */
    public function __construct(
        public array $requestIds,
        public string $handledBy,
    ) {}
}
