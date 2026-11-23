<?php

declare(strict_types=1);

namespace App\Domain\Entities;

final readonly class AdminDashboard
{
    public function __construct(
        public int $driversTotal,
        public int $driversCheckedIn,
        public int $driversCheckedOut,
        public int $driversAbsent,
        public int $employeesTotal,
        public int $placesTotal,
        public int $tripsUnassigned,
        public int $tripsAssigned,
        public int $tripsInProgress,
        public int $tripsCompletedToday,
        public int $tripsCompletedThisWeek,
        public int $requestsPending,
        public int $requestsApproved,
        public int $requestsRejected,
        public int $unconfirmedTrips,
    ) {}
}
