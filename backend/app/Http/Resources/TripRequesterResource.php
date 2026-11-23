<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\TripPassenger;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * The requesting employee only. Fellow passengers are not contacts.
 *
 * Allowed fields: id (trip_requests.employee_id), name_en, name_ar, phone, branch.
 *
 * @mixin TripPassenger
 */
final class TripRequesterResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var TripPassenger $requester */
        $requester = $this->resource;

        return [
            'id' => $requester->employeeId,
            'name_en' => $requester->nameEn,
            'name_ar' => $requester->nameAr,
            'phone' => $requester->phone,
            'branch' => $requester->branch,
        ];
    }
}
