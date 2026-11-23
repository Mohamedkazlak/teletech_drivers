<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\Place;
use App\Http\Support\JsonNumber;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Place
 */
final class PlaceResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var Place $place */
        $place = $this->resource;

        return [
            'id' => $place->id,
            'name_en' => $place->nameEn,
            'name_ar' => $place->nameAr,
            'latitude' => JsonNumber::orNull($place->latitude),
            'longitude' => JsonNumber::orNull($place->longitude),
            'address' => $place->address,
            'is_headquarters' => $place->isHeadquarters,
            'is_active' => $place->isActive,
            'created_at' => $place->createdAt?->format(DATE_ATOM),
        ];
    }
}
