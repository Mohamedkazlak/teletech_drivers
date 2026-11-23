<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\User;
use App\Domain\Enums\AvailabilityStatus;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin User
 */
final class UserResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var User $user */
        $user = $this->resource;

        return [
            'id' => $user->id,
            'name_en' => $user->nameEn,
            'name_ar' => $user->nameAr,
            'email' => $user->email,
            'role' => $user->role->value,
            'is_active' => $user->isActive,
            'phone' => $user->phone,
            'branch' => $user->branch?->value,
            'must_change_password' => $user->mustChangePassword,
            'is_available' => $user->availabilityStatus === AvailabilityStatus::Available,
        ];
    }
}
