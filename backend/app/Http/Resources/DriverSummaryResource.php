<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\Driver;
use App\Domain\Entities\DriverStats;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Driver without private profile fields (for company_admin).
 *
 * @mixin Driver
 */
final class DriverSummaryResource extends JsonResource
{
    public function __construct(
        mixed $resource,
        private readonly ?DriverStats $totals = null,
        private readonly ?int $tripsThisWeek = null,
    ) {
        parent::__construct($resource);
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var Driver $driver */
        $driver = $this->resource;
        $user = $driver->user;

        return [
            'id' => $user->id,
            'name_en' => $user->nameEn,
            'name_ar' => $user->nameAr,
            'email' => $user->email,
            'role' => $user->role->value,
            'is_active' => $user->isActive,
            'phone' => $user->phone,
            'is_available' => $user->availabilityStatus->value === 'available',
            'distance_from_hq_m' => $driver->checkInDistanceM,
            'favorite_place_ids' => $driver->favoritePlaceIds,
            'deleted_at' => $user->deletedAt,
            'deleted_by' => $user->deletedBy,
            ...DriverTotalsFields::payload($this->totals),
            ...($this->tripsThisWeek === null ? [] : ['trips_this_week' => $this->tripsThisWeek]),
        ];
    }
}
