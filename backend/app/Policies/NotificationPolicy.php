<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\Notification;
use App\Models\User;

final class NotificationPolicy
{
    public function viewAny(User $actor): bool
    {
        return $this->isEligible($actor);
    }

    public function markRead(User $actor, Notification $notification): bool
    {
        return $this->isEligible($actor) && $actor->id === $notification->user_id;
    }

    private function isEligible(User $actor): bool
    {
        return $actor->is_active && $actor->deleted_at === null;
    }
}
