<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin User
 */
final class EmployeeResource extends JsonResource
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
            'deleted_at' => $user->deletedAt,
            'deleted_by' => $user->deletedBy,
        ];
    }
}
