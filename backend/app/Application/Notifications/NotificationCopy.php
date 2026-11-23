<?php

declare(strict_types=1);

namespace App\Application\Notifications;

use App\Domain\Entities\Notification;

/**
 * Renders a stored notification in one locale. Push delivery calls this
 * with the device locale because the queue worker has no request language.
 */
final class NotificationCopy
{
    public function title(Notification $notification, string $locale): string
    {
        return (string) trans(
            $notification->titleKey,
            $this->replacements($notification->params, $locale),
            $this->locale($locale),
        );
    }

    public function body(Notification $notification, string $locale): string
    {
        return (string) trans(
            $notification->bodyKey,
            $this->replacements($notification->params, $locale),
            $this->locale($locale),
        );
    }

    /**
     * @param  array<string, mixed>  $params
     * @return array<string, string>
     */
    private function replacements(array $params, string $locale): array
    {
        $arabic = $this->locale($locale) === 'ar';

        return [
            'requester' => $this->localizedName($params, 'requester_name', $arabic),
            'driver' => $this->localizedName($params, 'driver_name', $arabic),
            'pickup' => (string) ($params['pickup'] ?? ''),
            'destination' => (string) ($params['destination'] ?? ''),
        ];
    }

    /**
     * @param  array<string, mixed>  $params
     */
    private function localizedName(array $params, string $prefix, bool $arabic): string
    {
        $arabicName = $params[$prefix.'_ar'] ?? null;
        $englishName = $params[$prefix.'_en'] ?? null;

        if ($arabic && is_string($arabicName) && $arabicName !== '') {
            return $arabicName;
        }

        return is_string($englishName) ? $englishName : '';
    }

    private function locale(string $locale): string
    {
        $language = strtolower(trim(explode('-', $locale)[0] ?? 'en'));

        return $language === 'ar' ? 'ar' : 'en';
    }
}
