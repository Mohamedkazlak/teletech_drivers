<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\TripPassenger;
use App\Http\Support\JsonNumber;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TripPassenger
 */
final class TripPassengerResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var TripPassenger $passenger */
        $passenger = $this->resource;

        return [
            'employee_id' => $passenger->employeeId,
            'name_en' => $passenger->nameEn,
            'name_ar' => $passenger->nameAr,
            'phone' => $passenger->phone,
            'branch' => $passenger->branch,
            'request_id' => $passenger->requestId,
            'pickup' => [
                'place_id' => $passenger->pickup->placeId,
                'name' => $passenger->pickup->name,
                'lat' => JsonNumber::orNull($passenger->pickup->lat),
                'lng' => JsonNumber::orNull($passenger->pickup->lng),
                'address' => $passenger->pickup->address,
            ],
            'destination' => [
                'place_id' => $passenger->destination->placeId,
                'name' => $passenger->destination->name,
                'lat' => JsonNumber::orNull($passenger->destination->lat),
                'lng' => JsonNumber::orNull($passenger->destination->lng),
                'address' => $passenger->destination->address,
            ],
        ];
    }
}
