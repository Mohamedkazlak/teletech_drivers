<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\RequestTracking;
use App\Domain\Entities\RequestTrackingEvent;

final class RequestTrackingResource
{
    /**
     * @return array<string, mixed>
     */
    public static function make(RequestTracking $tracking): array
    {
        return [
            'stage' => $tracking->stage->value,
            'timeline' => array_map(
                static fn (RequestTrackingEvent $event): array => [
                    'stage' => $event->stage->value,
                    'reached_at' => $event->reachedAt?->format(DATE_ATOM),
                    'actor_role' => $event->actorRole?->value,
                ],
                $tracking->timeline,
            ),
            'rejection_reason' => $tracking->rejectionReason,
            'driver' => $tracking->driver === null ? null : [
                'name_en' => $tracking->driver->nameEn,
                'name_ar' => $tracking->driver->nameAr,
                'phone' => $tracking->driver->phone,
            ],
            'scheduled_at' => $tracking->scheduledAt?->format(DATE_ATOM),
            'vehicle' => $tracking->carLicense === null ? null : [
                'car_license' => $tracking->carLicense,
            ],
        ];
    }
}
