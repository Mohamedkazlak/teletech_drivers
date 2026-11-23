<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\TripRequest;
use App\Http\Support\JsonNumber;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin TripRequest
 */
final class TripRequestResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var TripRequest $tripRequest */
        $tripRequest = $this->resource;

        return [
            'id' => $tripRequest->id,
            'employee_id' => $tripRequest->employeeId,
            'employee_name_en' => $tripRequest->employeeNameEn,
            'employee_name_ar' => $tripRequest->employeeNameAr,
            'employee_phone' => $tripRequest->employeePhone,
            'employee_branch' => $tripRequest->employeeBranch,
            'requester_role' => $tripRequest->requesterRole->value,
            'pickup' => [
                'place_id' => $tripRequest->pickup->placeId,
                'name' => $tripRequest->pickup->name,
                'lat' => JsonNumber::orNull($tripRequest->pickup->lat),
                'lng' => JsonNumber::orNull($tripRequest->pickup->lng),
                'address' => $tripRequest->pickup->address,
            ],
            'destination' => [
                'place_id' => $tripRequest->destination->placeId,
                'name' => $tripRequest->destination->name,
                'lat' => JsonNumber::orNull($tripRequest->destination->lat),
                'lng' => JsonNumber::orNull($tripRequest->destination->lng),
                'address' => $tripRequest->destination->address,
            ],
            'requested_at' => $tripRequest->requestedAt->format(DATE_ATOM),
            'notes' => $tripRequest->notes,
            'status' => $tripRequest->status->value,
            'trip_id' => $tripRequest->tripId,
            'trip_status' => $tripRequest->tripStatus?->value,
            'rejection_reason' => $tripRequest->rejectionReason,
            'handled_by' => $tripRequest->handledBy,
            'handled_at' => $tripRequest->handledAt?->format(DATE_ATOM),
            'auto_approved' => $tripRequest->autoApproved,
            'suggested_group_id' => $tripRequest->suggestedGroupId,
            'created_at' => $tripRequest->createdAt->format(DATE_ATOM),
            'tracking' => $tripRequest->tracking !== null
                ? RequestTrackingResource::make($tripRequest->tracking)
                : null,
            'trip' => $this->tripBlock($tripRequest),
        ];
    }

    /**
     * @return array<string, mixed>|null
     */
    private function tripBlock(TripRequest $tripRequest): ?array
    {
        $trip = $tripRequest->linkedTrip;
        if ($tripRequest->tripId === null || $trip === null) {
            return null;
        }

        return [
            'id' => $trip->id,
            'status' => $trip->status->value,
            'driver_name_en' => $trip->driverNameEn,
            'driver_name_ar' => $trip->driverNameAr,
            'confirmation_status' => $trip->confirmationStatus?->value,
            'driver_showed_up' => $trip->driverShowedUp,
        ];
    }
}
