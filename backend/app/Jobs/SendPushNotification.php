<?php

declare(strict_types=1);

namespace App\Jobs;

use App\Application\Push\FcmService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;
use Throwable;

final class SendPushNotification implements ShouldQueue
{
    use Queueable;

    public int $tries = 1;

    public function __construct(public readonly string $notificationId)
    {
        $this->afterCommit = true;
    }

    public function handle(FcmService $fcm): void
    {
        try {
            $fcm->deliver($this->notificationId);
        } catch (Throwable $exception) {
            Log::error('Push notification failed.', [
                'notification_id' => $this->notificationId,
                'error' => $exception->getMessage(),
            ]);
        }
    }
}
