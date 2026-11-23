<?php

declare(strict_types=1);

namespace App\Application\TripRequests\Actions;

use App\Domain\Entities\GroupSuggestion;
use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Repositories\TripRequestRepositoryInterface;
use App\Domain\Services\GroupingSuggestionService;
use App\Domain\Services\HaversineDistance;

final class GetGroupingSuggestionsAction
{
    public function __construct(
        private readonly TripRequestRepositoryInterface $tripRequests,
    ) {}

    /**
     * @return list<GroupSuggestion>
     */
    public function execute(UserRole $role): array
    {
        $status = match ($role) {
            UserRole::CompanyAdmin => TripRequestStatus::Pending,
            UserRole::DriversAdmin => TripRequestStatus::Approved,
            default => TripRequestStatus::Pending,
        };

        $tripIdMustBeNull = $role === UserRole::DriversAdmin;
        $candidates = $this->tripRequests->listGroupable($status, $tripIdMustBeNull);

        $timezone = (string) config('teletech.business_timezone', 'Africa/Cairo');
        $service = new GroupingSuggestionService(
            distance: new HaversineDistance,
            radiusMeters: GroupingSuggestionService::DEFAULT_RADIUS_METERS,
            businessTimezone: $timezone,
        );

        return $service->suggest($candidates);
    }
}
