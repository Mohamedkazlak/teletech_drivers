<?php

declare(strict_types=1);

use App\Domain\Enums\UserRole;
use App\Models\User;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('role.admin', function (User $user): bool {
    return $user->role === UserRole::Admin;
});

Broadcast::channel('role.company-admin', function (User $user): bool {
    return $user->role === UserRole::CompanyAdmin;
});

Broadcast::channel('role.drivers-admin', function (User $user): bool {
    return $user->role === UserRole::DriversAdmin;
});

Broadcast::channel('user.{userId}', function (User $user, string $userId): bool {
    return $user->id === $userId;
});
