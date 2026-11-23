<?php

declare(strict_types=1);

namespace App\Application\Push;

use App\Application\Notifications\NotificationCopy;
use App\Application\Push\Contracts\FcmClient;
use App\Domain\Entities\DeviceToken;
use App\Domain\Entities\Notification;
use App\Domain\Repositories\DeviceTokenRepositoryInterface;
use App\Domain\Repositories\NotificationRepositoryInterface;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Sends one stored notification to each of the recipient's device tokens.
 * A rejected token is removed. Any other failure is logged and skipped.
 */
final class FcmService
{
    public function __construct(
        private readonly FcmClient $fcm,
        private readonly NotificationRepositoryInterface $notifications,
        private readonly DeviceTokenRepositoryInterface $tokens,
        private readonly NotificationCopy $copy,
    ) {}

    public function deliver(string $notificationId): void
    {
        if (! $this->fcm->isConfigured()) {
            Log::warning('FIREBASE_CREDENTIALS is missing; push delivery is skipped.');

            return;
        }

        $notification = $this->notifications->find($notificationId);
        if ($notification === null) {
            return;
        }

        $devices = $this->tokens->listForUser($notification->userId);
        if ($devices === []) {
            return;
        }

        $badge = $this->notifications->unreadCount($notification->userId);

        foreach ($devices as $device) {
            $this->deliverToDevice($notification, $device, $badge);
        }
    }

    private function deliverToDevice(Notification $notification, DeviceToken $device, int $badge): void
    {
        $locale = $device->locale === 'ar' ? 'ar' : 'en';

        // device_tokens.token stores the Firebase Installation ID.
        $message = [
            'fid' => $device->token,
            'notification' => [
                'title' => $this->copy->title($notification, $locale),
                'body' => $this->copy->body($notification, $locale),
            ],
            'data' => [
                'notification_id' => $notification->id,
                'type' => $notification->type->value,
                'trip_id' => $notification->tripId ?? '',
                'trip_request_id' => $notification->tripRequestId ?? '',
            ],
            'android' => [
                'priority' => 'HIGH',
                'notification' => [
                    'channel_id' => 'trips',
                ],
            ],
            'apns' => [
                'headers' => [
                    'apns-priority' => '10',
                ],
                'payload' => [
                    'aps' => [
                        'sound' => 'default',
                        'badge' => $badge,
                    ],
                ],
            ],
        ];

        try {
            $this->fcm->send($message);
        } catch (FcmMessageException $exception) {
            if (in_array($exception->errorCode, ['UNREGISTERED', 'INVALID_ARGUMENT'], true)) {
                $this->tokens->deleteByToken($device->token);
            }

            Log::warning('Push delivery failed for a device token.', [
                'notification_id' => $notification->id,
                'error_code' => $exception->errorCode,
            ]);
        } catch (Throwable $exception) {
            Log::error('Push delivery failed for a device token.', [
                'notification_id' => $notification->id,
                'error' => $exception->getMessage(),
            ]);
        }
    }
}
